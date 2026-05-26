import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transitly/data/nfc/nfc_balance_repository.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';
import 'package:transitly/features/home/tabs/card_tab.dart';
import 'package:transitly/shared/providers/nfc_provider.dart';

import '../helpers/pump_app.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

/// Fake service that drives the flow deterministically. Avoids depending on
/// any native plugin in a widget test environment.
class _FakeNfcCardService implements NfcCardService {
  _FakeNfcCardService({this.available = true});
  final bool available;

  @override
  Future<bool> isNfcAvailable() async => available;

  @override
  Future<void> startScan({
    required void Function(NfcCardResult result) onResult,
    required void Function(NfcCardException error) onError,
  }) async {
    onResult(NfcCardResult(
      cardId: 'ABCD1234',
      balance: 7.50,
      scannedAt: DateTime(2026, 4, 22, 10, 0),
    ));
  }

  @override
  Future<void> stopScan() async {}

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

Future<NfcBalanceRepository> _testRepo() async {
  Hive.init('test/.hive_test_card_tab');
  final box =
      await Hive.openBox<Map<dynamic, dynamic>>('nfc_scans_test_card_tab');
  await box.clear();

  final supabase = MockSupabaseClient();
  final auth = MockGoTrueClient();
  when(() => supabase.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);

  return NfcBalanceRepository(supabase, box);
}

void main() {
  testWidgets('CardTab shows "NFC NO DISPONIBLE" when hardware is absent',
      (tester) async {
    final repo = await _testRepo();
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider
            .overrideWithValue(_FakeNfcCardService(available: false)),
        nfcBalanceRepositoryProvider.overrideWithValue(repo),
      ],
    );
    // Let the FutureProvider resolve.
    await tester.pumpAndSettle();
    expect(find.text('NFC NO DISPONIBLE'), findsOneWidget);
  });

  testWidgets('CardTab idle state prompts the user to scan', (tester) async {
    final repo = await _testRepo();
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
        nfcBalanceRepositoryProvider.overrideWithValue(repo),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('ACERCA TU TARJETA'), findsOneWidget);
    expect(find.text('ESCANEAR TARJETA'), findsOneWidget);
  });

  testWidgets('Tapping "ESCANEAR TARJETA" renders the balance on success',
      (tester) async {
    final repo = await _testRepo();
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
        nfcBalanceRepositoryProvider.overrideWithValue(repo),
      ],
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ESCANEAR TARJETA'));
    await tester.pumpAndSettle();

    expect(find.textContaining('7.50'), findsWidgets);
    expect(find.text('ABCD1234'), findsOneWidget);
    expect(find.text('ESCANEAR DE NUEVO'), findsOneWidget);
  });
}
