import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:transitly/core/router/app_router.dart';
import 'package:transitly/core/theme/transit_colors.dart';
import 'package:transitly/core/theme/transit_theme.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/mock/mock_realtime_service.dart';
import 'package:transitly/l10n/generated/app_localizations.dart';
import 'package:transitly/shared/models/active_trip_model.dart';

import '../helpers/pump_app.dart';

Future<GoRouter> pumpRouter(
  WidgetTester tester,
  MockDataService mock, {
  String initialLocation = '/home/inicio',
}) async {
  late GoRouter router;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mockDataOverride(mock),
        routerInitialLocationProvider.overrideWithValue(initialLocation),
        // Stub realtime streams so MockRealtimeService (owns two periodic
        // Timers) never initializes under test.
        realtimeTripsProvider.overrideWith(
          (ref) => const Stream<List<ActiveTripModel>>.empty(),
        ),
        realtimeClockProvider.overrideWith(
          (ref) => const Stream<DateTime>.empty(),
        ),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          router = ref.watch(routerProvider);
          return MediaQuery(
            // disableAnimations=true makes StaggerList skip its internal
            // `await Future.delayed(...)` loop (uncancelable once scheduled)
            // which would otherwise leave pending timers at test teardown.
            data: const MediaQueryData(disableAnimations: true),
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: buildTransitTheme(const TransitDarkColors()),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          );
        },
      ),
    ),
  );
  // Avoid pumpAndSettle — SmokeBackground uses a Ticker that never stops.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return router;
}

/// Unmount everything so Tickers / periodic timers finalize before the
/// binding's pending-timer assertion runs.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

String currentPath(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.path;

void main() {
  late MockDataService mock;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    mock = await loadMockData();
  });

  group('app router deeplinks', () {
    testWidgets('valid /route/<id> stays at that path', (tester) async {
      final router = await pumpRouter(tester, mock);
      final routeId = mock.routes.first.id;

      router.go('/route/$routeId');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(currentPath(router), '/route/$routeId');
      await unmount(tester);
    });

    testWidgets('invalid /route/<id> redirects to /home/inicio',
        (tester) async {
      final router = await pumpRouter(tester, mock);

      router.go('/route/DOES_NOT_EXIST_123');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(currentPath(router), '/home/inicio');
      await unmount(tester);
    });

    testWidgets('valid /stop/<id> stays at that path', (tester) async {
      final router = await pumpRouter(tester, mock);
      final stopId = mock.stops.first.id;

      router.go('/stop/$stopId');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(currentPath(router), '/stop/$stopId');
      await unmount(tester);
    });

    testWidgets('invalid /stop/<id> redirects to /home/inicio',
        (tester) async {
      final router = await pumpRouter(tester, mock);

      router.go('/stop/STOP_NOPE');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(currentPath(router), '/home/inicio');
      await unmount(tester);
    });

    testWidgets('/home/perfil is a valid shell branch', (tester) async {
      final router = await pumpRouter(tester, mock);

      router.go('/home/perfil');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(currentPath(router), '/home/perfil');
      await unmount(tester);
    });
  });
}
