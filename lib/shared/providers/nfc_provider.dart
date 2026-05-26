import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/analytics/posthog_service.dart';
import '../../data/nfc/nfc_balance_repository.dart';
import '../../data/nfc/nfc_card_service.dart';
import 'connectivity_provider.dart';

/// The service instance. Override in tests with a fake.
final nfcCardServiceProvider =
    Provider.autoDispose<NfcCardService>((ref) => NfcCardService());

/// Whether NFC hardware is available on this device.
final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  return ref.read(nfcCardServiceProvider).isNfcAvailable();
});

/// NFC scan status.
enum NfcScanStatus { idle, scanning, success, error, unsupported }

/// State for the NFC scanning flow.
class NfcScanState {
  const NfcScanState({
    this.status = NfcScanStatus.idle,
    this.result,
    this.errorKind,
    this.errorMessage,
    this.scanHistory = const [],
  });

  final NfcScanStatus status;
  final NfcCardResult? result;

  /// Machine-readable error reason; UI resolves it via `AppLocalizations`.
  final NfcCardError? errorKind;

  /// Spanish fallback message — used when no `BuildContext` is available
  /// (e.g. logging) or as default for `NfcCardError.unknown`.
  final String? errorMessage;
  final List<NfcCardResult> scanHistory;

  NfcScanState copyWith({
    NfcScanStatus? status,
    NfcCardResult? result,
    NfcCardError? errorKind,
    String? errorMessage,
    List<NfcCardResult>? scanHistory,
  }) {
    return NfcScanState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorKind: errorKind,
      errorMessage: errorMessage,
      scanHistory: scanHistory ?? this.scanHistory,
    );
  }
}

/// Notifier managing the NFC scan lifecycle.
class NfcScanNotifier extends StateNotifier<NfcScanState> {
  NfcScanNotifier(this._service, this._repo) : super(const NfcScanState());

  final NfcCardService _service;
  final NfcBalanceRepository _repo;

  /// Start scanning for an NFC card.
  Future<void> startScan() async {
    state = state.copyWith(status: NfcScanStatus.scanning, errorMessage: null);

    await _service.startScan(
      onResult: (result) {
        PostHogAnalyticsService.nfcReadSuccess('mifare_classic', result.balance);
        _repo.saveScan(result);
        final history = _repo.getHistory();
        state = NfcScanState(
          status: NfcScanStatus.success,
          result: result,
          scanHistory: history,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: NfcScanStatus.error,
          errorKind: error.error,
          errorMessage: error.displayMessage,
        );
      },
    );
  }

  /// Cancel an active scan and return to idle.
  Future<void> cancelScan() async {
    await _service.stopScan();
    state = state.copyWith(status: NfcScanStatus.idle, errorMessage: null);
  }

  /// Reset to idle state (keeps history).
  void reset() {
    state = state.copyWith(status: NfcScanStatus.idle, errorMessage: null);
  }

  /// Refresh scan history from the persistent repository.
  void refreshHistory() {
    final history = _repo.getHistory();
    state = state.copyWith(scanHistory: history);
  }

  @override
  void dispose() {
    _service.stopScan();
    super.dispose();
  }
}

/// Main provider for NFC scan state.
final nfcScanProvider =
    StateNotifierProvider<NfcScanNotifier, NfcScanState>((ref) {
  final notifier = NfcScanNotifier(
    ref.read(nfcCardServiceProvider),
    ref.read(nfcBalanceRepositoryProvider),
  );

  // When coming back online, sync pending scans to Supabase.
  ref.listen<bool>(isOfflineProvider, (prev, current) {
    if (prev == true && current == false) {
      ref.read(nfcBalanceRepositoryProvider).syncPending();
    }
  });

  return notifier;
});
