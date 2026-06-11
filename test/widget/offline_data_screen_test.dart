import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/features/profile/offline_data_screen.dart';
import 'package:transitly/shared/widgets/transit_button.dart';

import '../helpers/pump_app.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockDataService mock;
  late _MockSupabaseClient supabase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // OfflineDataScreen ahora usa providers (sub-B map_data_cache mejorado)
    // que abren cajas Hive y leen el cliente Supabase; sin estos stubs el
    // árbol revienta con HiveError + 'supabase not initialized'.
    final dir = await Directory.systemTemp.createTemp('hive_offline_data_test_');
    Hive.init(dir.path);
    mock = await loadMockData();
    supabase = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.currentUser).thenReturn(null);
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
      overrides: [
        mockDataOverride(mock),
        supabaseClientProvider.overrideWithValue(supabase),
      ],
    );
    await tester.pump();

    expect(find.text('CONTENIDO'), findsOneWidget);
    expect(find.text('ARCHIVO'), findsOneWidget);
    expect(find.text('Rutas'), findsOneWidget);
    expect(find.text('Paradas'), findsOneWidget);
    expect(find.text('Tamaño'), findsOneWidget);
    expect(find.text('Cargado'), findsOneWidget);
    expect(find.text('assets/mock/comujesa_data.json'), findsOneWidget);

    // Reload button exists with expected label (la pantalla tiene además
    // botones de sincronizar y exportar, así que no podemos asumir uno solo).
    final labels = tester
        .widgetList<TransitButton>(find.byType(TransitButton))
        .map((b) => b.label);
    expect(labels, contains('Recargar desde assets'));
    await unmount(tester);
  });
}
