import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/accessibility_matrix.dart';
import 'l10n/generated/app_localizations.dart';
import 'shared/models/user_preferences.dart';
import 'shared/providers/geo_alerts_in_radius_provider.dart';
import 'shared/providers/locale_provider.dart';
import 'shared/providers/theme_notifier.dart';
import 'shared/providers/theme_provider.dart';
import 'shared/services/widget_sync_service.dart';
import 'shared/widgets/background_wrapper.dart';

class TransitlyApp extends ConsumerWidget {
  const TransitlyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeNotifier = ref.watch(themeNotifierProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    ref.watch(widgetSyncListenerProvider);
    // Detector de avisos geo en radio → inserta notificaciones cuando
    // el usuario entra en zona de un aviso nuevo.
    ref.watch(geoAlertsAutoNotifyProvider);

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
        final rebuildKey = '${themeNotifier.visualKey}|${themeMode.name}';

        Widget result = KeyedSubtree(
          key: ValueKey(rebuildKey),
          child: BackgroundWrapper(child: child!),
        );

        if (themeNotifier.colorBlindMode != ColorBlindMode.none) {
          result = ColorFiltered(
            colorFilter: ColorFilter.matrix(
              AccessibilityMatrix.forMode(themeNotifier.colorBlindMode.name),
            ),
            child: result,
          );
        }

        final rawSystem = MediaQuery.textScalerOf(context).scale(1.0);
        final systemScale =
            rawSystem.isFinite && rawSystem > 0 ? rawSystem : 1.0;
        final notifierScale = themeNotifier.fontScale.isFinite &&
                themeNotifier.fontScale > 0
            ? themeNotifier.fontScale
            : 1.0;
        final combined =
            (systemScale * notifierScale).clamp(0.8, 2.5);

        if (!combined.isFinite || combined <= 0) {
          return result;
        }
        final mq = MediaQuery.of(context);
        return FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(combined),
              disableAnimations:
                  themeNotifier.reduceMotion || mq.disableAnimations,
            ),
            child: result,
          ),
        );
      },
    );
  }
}
