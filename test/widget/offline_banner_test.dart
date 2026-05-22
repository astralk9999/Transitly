import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/offline_sync_provider.dart';
import 'package:transitly/shared/providers/connectivity_provider.dart';
import 'package:transitly/shared/widgets/offline_banner.dart';
import '../helpers/pump_app.dart';

void main() {
  group('OfflineBanner', () {
    testWidgets('renders when isOffline is true', (tester) async {
      await pumpApp(
        tester,
        child: const OfflineBanner(),
        overrides: [
          isOfflineProvider.overrideWithValue(true),
          pendingActionsCountProvider.overrideWith(
            (ref) => Stream<int>.value(0),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Sin conexión'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('hidden when offline and no pending actions', (tester) async {
      await pumpApp(
        tester,
        child: const OfflineBanner(),
        overrides: [
          isOfflineProvider.overrideWithValue(false),
          pendingActionsCountProvider.overrideWith(
            (ref) => Stream<int>.value(0),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.byType(OfflineBanner), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders with pending actions count', (tester) async {
      await pumpApp(
        tester,
        child: const OfflineBanner(),
        overrides: [
          isOfflineProvider.overrideWithValue(true),
          pendingActionsCountProvider.overrideWith(
            (ref) => Stream<int>.value(3),
          ),
        ],
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('3'), findsOneWidget);
      await unmount(tester);
    });
  });
}
