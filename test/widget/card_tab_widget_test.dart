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
  final box = await Hive.openBox<Map<dynamic, dynamic>>(
      'nfc_scans_test_${DateTime.now().microsecondsSinceEpoch}');
  await box.clear();

  final supabase = MockSupabaseClient();
  final auth = MockGoTrueClient();
  when(() => supabase.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);

  return NfcBalanceRepository(supabase, box);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Hive.init('test/.hive_test_card_tab');
  });

  // En testWidgets el binding usa FakeAsync zone, lo que bloquea el Future
  // real de Hive.openBox. Envolvemos la apertura con tester.runAsync() para
  // que se ejecute fuera del FakeAsync. Después usamos pump() finito en
  // lugar de pumpAndSettle() para no esperar a timers infinitos (connectivity
  // plus mantiene streams periódicos que nunca quedan "settled").
  testWidgets('CardTab shows "NFC NO DISPONIBLE" when hardware is absent',
      (tester) async {
    final repo = await tester.runAsync(() => _testRepo());
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider
            .overrideWithValue(_FakeNfcCardService(available: false)),
        nfcBalanceRepositoryProvider.overrideWithValue(repo!),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('NFC NO DISPONIBLE'), findsOneWidget);
  });

  testWidgets('CardTab idle state prompts the user to scan', (tester) async {
    final repo = await tester.runAsync(() => _testRepo());
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
        nfcBalanceRepositoryProvider.overrideWithValue(repo!),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('ACERCA TU TARJETA'), findsOneWidget);
    expect(find.text('ESCANEAR TARJETA'), findsOneWidget);
  });

  testWidgets('Tapping "ESCANEAR TARJETA" renders the balance on success',
      (tester) async {
    final repo = await tester.runAsync(() => _testRepo());
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
        nfcBalanceRepositoryProvider.overrideWithValue(repo!),
      ],
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('ESCANEAR TARJETA'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('7.50'), findsWidgets);
    expect(find.text('ABCD1234'), findsOneWidget);
    expect(find.text('ESCANEAR DE NUEVO'), findsOneWidget);
  });
}
