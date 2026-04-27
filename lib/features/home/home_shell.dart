import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import '../driver/driver_panel.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_side_nav.dart';
import 'widgets/home_tab_item.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver = ref.watch(isDriverModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final screen = ResponsiveScaffold.screenSizeOf(context);
    final useRail = screen != ScreenSize.compact;
    final extendedRail = screen == ScreenSize.large;
    final tabs = homeTabsOf(AppLocalizations.of(context));

    if (useRail) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: Stack(
          children: [
            Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark),
            ),
            Row(
              children: [
                HomeSideNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _onTap,
                  tabs: tabs,
                  extended: extendedRail,
                ),
                Expanded(
                  child: Stack(
                    children: [
                      ResponsiveScaffold(child: navigationShell),
                      if (isDriver)
                        Positioned(
                          bottom: TransitSpacing.space16,
                          right: TransitSpacing.space16,
                          child: _DriverFab(color: c),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          navigationShell,
          if (isDriver)
            Positioned(
              bottom: 80,
              right: TransitSpacing.space16,
              child: _DriverFab(color: c),
            ),
        ],
      ),
      bottomNavigationBar: HomeBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        tabs: tabs,
      ),
    );
  }
}

class _DriverFab extends StatelessWidget {
  const _DriverFab({required this.color});

  final TransitColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.accent.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: color.accent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => const DriverPanel(),
          );
        },
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.directions_bus, color: color.accent, size: 24),
        ),
      ),
    );
  }
}
