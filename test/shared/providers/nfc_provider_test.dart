import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';
import 'package:transitly/shared/providers/nfc_provider.dart';

/// Fake service that drives [onResult]/[onError] deterministically.
class _FakeNfcCardService implements NfcCardService {
  _FakeNfcCardService({this.scenario = _Scenario.success});

  final _Scenario scenario;
  int startCalls = 0;
  int stopCalls = 0;

  @override
  Future<bool> isNfcAvailable() async => true;

  @override
  Future<void> startScan({
    required void Function(NfcCardResult result) onResult,
    required void Function(NfcCardException error) onError,
  }) async {
    startCalls++;
    switch (scenario) {
      case _Scenario.success:
        onResult(NfcCardResult(
          cardId: 'DEADBEEF',
          balance: 12.34,
          scannedAt: DateTime(2026, 4, 22, 10, 0),
        ));
      case _Scenario.error:
        onError(const NfcCardException(NfcCardError.tagLost));
    }
  }

  @override
  Future<void> stopScan() async {
    stopCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

enum _Scenario { success, error }

void main() {
  ProviderContainer containerWith(_FakeNfcCardService fake) {
    final container = ProviderContainer(overrides: [
      nfcCardServiceProvider.overrideWithValue(fake),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('initial state is idle with empty history', () {
    final c = containerWith(_FakeNfcCardService());
    final s = c.read(nfcScanProvider);
    expect(s.status, NfcScanStatus.idle);
    expect(s.scanHistory, isEmpty);
    expect(s.result, isNull);
  });

  test('startScan on success transitions to success with result and history',
      () async {
    final fake = _FakeNfcCardService(scenario: _Scenario.success);
    final c = containerWith(fake);

    await c.read(nfcScanProvider.notifier).startScan();

    final s = c.read(nfcScanProvider);
    expect(s.status, NfcScanStatus.success);
    expect(s.result?.cardId, 'DEADBEEF');
    expect(s.result?.balance, 12.34);
    expect(s.scanHistory.length, 1);
    expect(fake.startCalls, 1);
  });

  test('startScan on error transitions to error with message', () async {
    final fake = _FakeNfcCardService(scenario: _Scenario.error);
    final c = containerWith(fake);

    await c.read(nfcScanProvider.notifier).startScan();

    final s = c.read(nfcScanProvider);
    expect(s.status, NfcScanStatus.error);
    expect(s.errorMessage, isNotNull);
    expect(s.scanHistory, isEmpty);
  });

  test('cancelScan calls service.stopScan and returns to idle', () async {
    final fake = _FakeNfcCardService();
    final c = containerWith(fake);

    await c.read(nfcScanProvider.notifier).cancelScan();

    expect(c.read(nfcScanProvider).status, NfcScanStatus.idle);
    expect(fake.stopCalls, 1);
  });

  test('scan history caps at 10 entries', () async {
    final fake = _FakeNfcCardService(scenario: _Scenario.success);
    final c = containerWith(fake);

    for (int i = 0; i < 12; i++) {
      await c.read(nfcScanProvider.notifier).startScan();
    }
    expect(c.read(nfcScanProvider).scanHistory.length, 10);
  });
}
