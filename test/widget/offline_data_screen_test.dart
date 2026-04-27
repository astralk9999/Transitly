import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/features/profile/offline_data_screen.dart';
import 'package:transitly/shared/widgets/transit_button.dart';

import '../helpers/pump_app.dart';

void main() {
  late MockDataService mock;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mock = await loadMockData();
  });

  testWidgets('OfflineDataScreen renders stats + metadata + reload button',
      (tester) async {
    // Taller viewport so the whole ListView builds eagerly.
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpApp(
      tester,
      child: const OfflineDataScreen(),
      overrides: [mockDataOverride(mock)],
    );
    await tester.pump();

    expect(find.text('CONTENIDO'), findsOneWidget);
    expect(find.text('ARCHIVO'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Paradas'), findsOneWidget);
    expect(find.text('Tamaño'), findsOneWidget);
    expect(find.text('Cargado'), findsOneWidget);
    expect(find.text('assets/mock/comujesa_data.json'), findsOneWidget);

    // Reload button exists with expected label.
    final button = tester.widget<TransitButton>(find.byType(TransitButton));
    expect(button.label, 'Recargar desde assets');
    await unmount(tester);
  });
}
