import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/accessibility_matrix.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/models/user_preferences.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_notifier.dart';
import 'shared/widgets/background_wrapper.dart';

class TransitlyApp extends ConsumerWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Transitly',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
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

        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(themeNotifier.fontScale),
          ),
          child: result,
        );
      },
    );
  }
}
