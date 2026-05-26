import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transitly/data/nfc/nfc_balance_repository.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';
import 'package:transitly/shared/providers/nfc_provider.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

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
          scannedAt: DateTime(2026, 4, 22, 10, 0).add(Duration(seconds: startCalls)),
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
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<Map<dynamic, dynamic>> box;
  late NfcBalanceRepository repo;

  setUpAll(() {
    Hive.init('test/.hive_test_nfc_provider');
  });

  setUp(() async {
    box =
        await Hive.openBox<Map<dynamic, dynamic>>('nfc_scans_test_provider');
    await box.clear();

    final supabase = MockSupabaseClient();
    final auth = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(null);

    repo = NfcBalanceRepository(supabase, box);
  });

  tearDown(() async {
    await box.close();
  });

  ProviderContainer containerWith(_FakeNfcCardService fake) {
    final container = ProviderContainer(overrides: [
      nfcCardServiceProvider.overrideWithValue(fake),
      nfcBalanceRepositoryProvider.overrideWithValue(repo),
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

    // Verify the scan was persisted to the box
    expect(box.length, 1);
    final saved = box.get(box.keys.first);
    expect(saved?['cardId'], 'DEADBEEF');
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
