import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/transit_theme.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_provider.dart';

class TransitlyApp extends ConsumerWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Transitly',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: buildTransitTheme(false),
      darkTheme: buildTransitTheme(true),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
