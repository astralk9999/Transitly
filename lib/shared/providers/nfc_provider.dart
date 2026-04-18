import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/nfc/nfc_card_service.dart';

/// Whether NFC hardware is available on this device.
final nfcAvailableProvider = FutureProvider<bool>((ref) async {
  if (kIsWeb) return false;
  return NfcCardService().isNfcAvailable();
});

/// NFC scan status.
enum NfcScanStatus { idle, scanning, success, error, unsupported }

/// State for the NFC scanning flow.
class NfcScanState {
  const NfcScanState({
    this.status = NfcScanStatus.idle,
    this.result,
    this.errorMessage,
    this.scanHistory = const [],
  });

  final NfcScanStatus status;
  final NfcCardResult? result;
  final String? errorMessage;
  final List<NfcCardResult> scanHistory;

  NfcScanState copyWith({
    NfcScanStatus? status,
    NfcCardResult? result,
    String? errorMessage,
    List<NfcCardResult>? scanHistory,
  }) {
    return NfcScanState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
      scanHistory: scanHistory ?? this.scanHistory,
    );
  }
}

/// Notifier managing the NFC scan lifecycle.
class NfcScanNotifier extends StateNotifier<NfcScanState> {
  NfcScanNotifier() : super(const NfcScanState());

  final _service = NfcCardService();
  static const _maxHistory = 10;

  /// Start scanning for an NFC card.
  Future<void> startScan() async {
    state = state.copyWith(status: NfcScanStatus.scanning, errorMessage: null);

    await _service.startScan(
      onResult: (result) {
        final history = [result, ...state.scanHistory].take(_maxHistory).toList();
        state = NfcScanState(
          status: NfcScanStatus.success,
          result: result,
          scanHistory: history,
        );
      },
      onError: (error) {
        state = state.copyWith(
          status: NfcScanStatus.error,
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

  @override
  void dispose() {
    _service.stopScan();
    super.dispose();
  }
}

/// Main provider for NFC scan state.
final nfcScanProvider =
    StateNotifierProvider<NfcScanNotifier, NfcScanState>((ref) {
  return NfcScanNotifier();
});
