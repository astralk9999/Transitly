import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/features/profile/accessibility_settings_screen.dart';
import 'package:transitly/shared/providers/theme_provider.dart';

import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AccessibilitySettingsScreen', () {
    testWidgets('renders Tema, Preferencias del sistema and Idioma sections',
        (tester) async {
      await pumpApp(tester, child: const AccessibilitySettingsScreen());
      await tester.pump();

      expect(find.text('TEMA'), findsOneWidget);
      expect(find.text('PREFERENCIAS DEL SISTEMA'), findsOneWidget);
      expect(find.text('IDIOMA'), findsOneWidget);
      // 'Sistema' appears twice now: theme option + language option.
      expect(find.text('Sistema'), findsNWidgets(2));
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tapping a theme option updates themeModeProvider',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(home: AccessibilitySettingsScreen()),
          ),
        ),
      );
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.dark);

      await tester.tap(find.text('Claro'));
      await tester.pump();

      expect(container.read(themeModeProvider), ThemeMode.light);
      await unmount(tester);
    });

    testWidgets('reflects disableAnimations from MediaQuery', (tester) async {
      await pumpApp(tester, child: const AccessibilitySettingsScreen());
      await tester.pump();

      expect(find.text('Reducidas'), findsOneWidget);
      await unmount(tester);
    });
  });
}
