import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/providers/notification_stream_provider.dart';
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
    final unreadCount = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final screen = ResponsiveScaffold.screenSizeOf(context);
    final useRail = screen != ScreenSize.compact;
    final extendedRail = screen == ScreenSize.large;
    final tabs = homeTabsOf(AppLocalizations.of(context));

    if (useRail) {
      return FocusTraversalGroup(
        child: Scaffold(
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
                      Positioned(
                        top: TransitSpacing.space8,
                        right: TransitSpacing.space16,
                        child: _NotificationBell(
                          unreadCount: unreadCount,
                          c: c,
                          onTap: () => context.push('/notifications'),
                        ),
                      ),
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
      ),
      );
    }

    return FocusTraversalGroup(
      child: Scaffold(
      backgroundColor: c.bgRoot,
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          navigationShell,
          Positioned(
            top: TransitSpacing.space8,
            right: TransitSpacing.space16,
            child: SafeArea(
              bottom: false,
              child: _NotificationBell(
                unreadCount: unreadCount,
                c: c,
                onTap: () => context.push('/notifications'),
              ),
            ),
          ),
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

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({
    required this.unreadCount,
    required this.c,
    required this.onTap,
  });

  final int unreadCount;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: c.bgSurface.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: c.border, width: 0.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                unreadCount > 0
                    ? Icons.notifications_active
                    : Icons.notifications_outlined,
                color: c.textHi,
                size: 22,
              ),
              if (unreadCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
