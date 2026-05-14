import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_notifier.dart';

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
    );
  }
}
