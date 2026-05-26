import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/core/theme/transit_colors.dart';
import 'package:transitly/data/user_preferences/domain/user_preferences_repository.dart';
import 'package:transitly/features/notifications/widgets/notification_bell.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';

import '../../../helpers/pump_app.dart';

class MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

void main() {
  late ThemeNotifier themeNotifier;

  setUp(() {
    final mockRepo = MockUserPreferencesRepository();
    themeNotifier = ThemeNotifier(prefsRepo: mockRepo);
  });

  Override themeOverride() =>
      themeNotifierProvider.overrideWith((ref) => themeNotifier);

  group('NotificationBell', () {
    testWidgets('usa border idle cuando unreadCount = 0', (tester) async {
      await pumpApp(
        tester,
        child: const NotificationBell(unreadCount: 0, onTap: _noop),
        overrides: [themeOverride()],
      );
      await tester.pump();

      final material = tester.widget<Material>(find.byType(Material).first);
      final shape = material.shape as RoundedRectangleBorder;
      final border = shape.side;
      final isDark = true;
      final c = TransitColorScheme.of(isDark);
      expect(border.color, c.border);
      expect(border.width, 0.5);

      expect(find.byType(Icon), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('usa borde accent y ancho 1.5 cuando unreadCount > 0',
        (tester) async {
      await pumpApp(
        tester,
        child: const NotificationBell(unreadCount: 3, onTap: _noop),
        overrides: [themeOverride()],
      );
      await tester.pump();

      final material = tester.widget<Material>(find.byType(Material).first);
      final shape = material.shape as RoundedRectangleBorder;
      final border = shape.side;
      final isDark = true;
      final c = TransitColorScheme.of(isDark);
      expect(border.color, c.accent);
      expect(border.width, 1.5);

      await unmount(tester);
    });

    testWidgets('badge visible con texto cuando unreadCount > 0',
        (tester) async {
      await pumpApp(
        tester,
        child: const NotificationBell(unreadCount: 5, onTap: _noop),
        overrides: [themeOverride()],
      );
      await tester.pump();

      expect(find.text('5'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('muestra 99+ cuando unreadCount > 99', (tester) async {
      await pumpApp(
        tester,
        child: const NotificationBell(unreadCount: 150, onTap: _noop),
        overrides: [themeOverride()],
      );
      await tester.pump();

      expect(find.text('99+'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('no muestra badge cuando unreadCount = 0', (tester) async {
      await pumpApp(
        tester,
        child: const NotificationBell(unreadCount: 0, onTap: _noop),
        overrides: [themeOverride()],
      );
      await tester.pump();

      expect(find.text('0'), findsNothing);

      await unmount(tester);
    });

    testWidgets('responde al tap', (tester) async {
      int tapped = 0;
      await pumpApp(
        tester,
        child: NotificationBell(
          unreadCount: 2,
          onTap: () => tapped++,
        ),
        overrides: [themeOverride()],
      );
      await tester.pump();

      await tester.tap(find.byType(NotificationBell));
      expect(tapped, 1);

      await unmount(tester);
    });
  });
}

void _noop() {}
