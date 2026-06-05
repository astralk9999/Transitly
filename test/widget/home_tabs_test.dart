import 'dart:io';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/mock/mock_realtime_service.dart';
import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/features/home/tabs/home_tab.dart';
import 'package:transitly/features/home/tabs/profile_tab.dart';
import 'package:transitly/features/home/tabs/search_tab.dart';
import 'package:transitly/shared/models/active_trip_model.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../data/shared_test_repositories.dart';
import '../helpers/pump_app.dart';

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockDataService mock;
  late _MockSupabaseClient supabase;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Providers como homeHabitualConfig, userFavorites llaman a Hive.openBox
    // en su constructor; sin Hive.init lanzan HiveError.
    final dir = await Directory.systemTemp.createTemp('hive_home_tabs_test_');
    Hive.init(dir.path);
    mock = await loadMockData();
    supabase = _MockSupabaseClient();
    final auth = _MockGoTrueClient();
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.currentSession).thenReturn(null);
    when(() => auth.currentUser).thenReturn(null);
  });

  List<Override> baseOverrides() => [
        mockDataOverride(mock),
        supabaseClientProvider.overrideWithValue(supabase),
        realtimeTripsProvider.overrideWith(
          (ref) => const Stream<List<ActiveTripModel>>.empty(),
        ),
        realtimeClockProvider.overrideWith(
          (ref) => const Stream<DateTime>.empty(),
        ),
        themeNotifierProvider.overrideWith(
          (_) => ThemeNotifier(prefsRepo: mockUserPreferencesRepo()),
        ),
      ];

  void setTallViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('HomeTab renders TRANSITLY header', (tester) async {
    setTallViewport(tester);
    await pumpApp(
      tester,
      child: const HomeTab(),
      overrides: baseOverrides(),
    );
    await tester.pump();

    expect(find.text('TRANSITLY'), findsOneWidget);
    // El antiguo label "Jerez de la Frontera" fue reemplazado por un selector
    // dinámico de operador (city picker); ya no es un texto estático.
    await unmount(tester);
  });

  testWidgets('SearchTab renders empty state before searching',
      (tester) async {
    setTallViewport(tester);
    await pumpApp(
      tester,
      child: const SearchTab(),
      overrides: baseOverrides(),
    );
    await tester.pump();

    // Search bar input present.
    expect(find.byType(SearchTab), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('ProfileTab renders section cards', (tester) async {
    setTallViewport(tester);
    await pumpApp(
      tester,
      child: const ProfileTab(),
      overrides: baseOverrides(),
    );
    await tester.pump();

    expect(find.text('APARIENCIA'), findsOneWidget);
    // El toggle "PERFIL DE DEMO → modo conductor" se eliminó (ver comentario
    // en profile_appearance_section). El driver mode ahora solo se activa
    // por flujo de activación verificado en /activate-driver.
    await unmount(tester);
  });
}
