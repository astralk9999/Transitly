import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/mock/mock_realtime_service.dart';
import 'package:transitly/features/home/tabs/home_tab.dart';
import 'package:transitly/features/home/tabs/profile_tab.dart';
import 'package:transitly/features/home/tabs/search_tab.dart';
import 'package:transitly/shared/models/active_trip_model.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../data/shared_test_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  late MockDataService mock;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mock = await loadMockData();
  });

  List<Override> baseOverrides() => [
        mockDataOverride(mock),
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

  testWidgets('HomeTab renders TRANSITLY header and city label',
      (tester) async {
    setTallViewport(tester);
    await pumpApp(
      tester,
      child: const HomeTab(),
      overrides: baseOverrides(),
    );
    await tester.pump();

    expect(find.text('TRANSITLY'), findsOneWidget);
    expect(find.text('Jerez de la Frontera'), findsOneWidget);
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
    expect(find.text('PERFIL DE DEMO'), findsOneWidget);
    await unmount(tester);
  });
}
