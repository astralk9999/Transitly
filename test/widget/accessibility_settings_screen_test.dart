import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/features/profile/accessibility_settings_screen.dart';
import 'package:transitly/shared/providers/theme_notifier.dart';
import 'package:transitly/shared/providers/theme_provider.dart';
import 'package:transitly/l10n/generated/app_localizations.dart';

import '../data/shared_test_repositories.dart';
import '../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ThemeNotifier testNotifier() =>
      ThemeNotifier(prefsRepo: mockUserPreferencesRepo());

  group('AccessibilitySettingsScreen', () {
    testWidgets('renders Tema, Preferencias del sistema and Idioma sections',
        (tester) async {
      await pumpApp(
        tester,
        child: const AccessibilitySettingsScreen(),
        overrides: [
          themeNotifierProvider.overrideWith((_) => testNotifier()),
        ],
      );
      await tester.pump();

      expect(find.text('TEMA'), findsOneWidget);
      expect(find.text('PREFERENCIAS DEL SISTEMA'), findsOneWidget);
      expect(find.text('Claro'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);

      await tester.dragUntilVisible(
        find.text('IDIOMA'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.pump();

      expect(find.text('IDIOMA'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('tapping a theme option updates themeModeProvider',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          themeNotifierProvider.overrideWith((_) => testNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: AccessibilitySettingsScreen(),
            ),
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
      await pumpApp(
        tester,
        child: const AccessibilitySettingsScreen(),
        overrides: [
          themeNotifierProvider.overrideWith((_) => testNotifier()),
        ],
      );
      await tester.pump();

      expect(find.text('Reducidas'), findsOneWidget);
      await unmount(tester);
    });
  });
}
