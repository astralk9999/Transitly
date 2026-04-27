import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/data/nfc/nfc_card_service.dart';
import 'package:transitly/features/home/tabs/card_tab.dart';
import 'package:transitly/shared/providers/nfc_provider.dart';

import '../helpers/pump_app.dart';

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

void main() {
  testWidgets('CardTab shows "NFC NO DISPONIBLE" when hardware is absent',
      (tester) async {
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider
            .overrideWithValue(_FakeNfcCardService(available: false)),
      ],
    );
    // Let the FutureProvider resolve.
    await tester.pumpAndSettle();
    expect(find.text('NFC NO DISPONIBLE'), findsOneWidget);
  });

  testWidgets('CardTab idle state prompts the user to scan',
      (tester) async {
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
      ],
    );
    await tester.pumpAndSettle();
    expect(find.text('ACERCA TU TARJETA'), findsOneWidget);
    expect(find.text('ESCANEAR TARJETA'), findsOneWidget);
  });

  testWidgets('Tapping "ESCANEAR TARJETA" renders the balance on success',
      (tester) async {
    await pumpApp(
      tester,
      child: const CardTab(),
      overrides: [
        nfcCardServiceProvider.overrideWithValue(_FakeNfcCardService()),
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
