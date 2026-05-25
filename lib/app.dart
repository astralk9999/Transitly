import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/accessibility_matrix.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/models/user_preferences.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_notifier.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/widgets/background_wrapper.dart';

class TransitlyApp extends ConsumerWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    // `themeModeProvider` es la fuente de verdad que cambian los toggles del
    // appearance section. `themeNotifier.brightness` es estado interno de
    // paleta — antes app.dart lo leía y nunca cambiaba al toggle, por eso el
    // modo claro solo afectaba al mapa (que sí usa themeModeProvider).
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Transitly',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: themeNotifier.buildTheme(Brightness.light),
      darkTheme: themeNotifier.buildTheme(Brightness.dark),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        Widget result = BackgroundWrapper(child: child!);

        if (themeNotifier.colorBlindMode != ColorBlindMode.none) {
          result = ColorFiltered(
            colorFilter: ColorFilter.matrix(
              AccessibilityMatrix.forMode(themeNotifier.colorBlindMode.name),
            ),
            child: result,
          );
        }

        // `.scale(1.0)` devuelve el factor multiplicador (no un tamaño en px).
        // Usar `.scale(14)` aquí multiplicaba todo por 14× antes del clamp y
        // dejaba el texto fijo en 2.5× → overflows masivos.
        final systemScale = MediaQuery.textScalerOf(context).scale(1.0);
        final combined = (systemScale * themeNotifier.fontScale).clamp(0.8, 2.5);
        return FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(combined),
            ),
            child: result,
          ),
        );
      },
    );
  }
}
