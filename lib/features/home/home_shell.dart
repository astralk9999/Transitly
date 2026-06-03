import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../data/auth/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/user_role.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/notification_stream_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/providers/widget_data_provider.dart';
import '../../shared/widgets/background_wrapper.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import '../driver/driver_panel.dart';
import '../notifications/widgets/notification_bell.dart';
import 'widgets/home_bottom_nav.dart';
import 'widgets/home_side_nav.dart';
import 'widgets/home_tab_item.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  DateTime? _lastBackPress;

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _handleBackPressed() {
    final nav = widget.navigationShell;
    if (nav.currentIndex != 0) {
      nav.goBranch(0);
      return;
    }
    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) >
            const Duration(seconds: 2)) {
      _lastBackPress = now;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.appExitConfirmMessage),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final isAuth =
        ref.watch(authStateProvider).valueOrNull is AuthAuthenticated;
    final isDriver =
        isAuth && ref.watch(currentUserRoleProvider) == UserRole.driver;
    final unreadCount = ref.watch(unreadCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final screen = ResponsiveScaffold.screenSizeOf(context);
    final mq = MediaQuery.sizeOf(context);
    final isLandscape = mq.width > mq.height;
    // Side rail si: no es móvil compact, O el dispositivo está en
    // landscape (móvil rotado, tablet, web). Así el menú se adapta
    // automáticamente al girar el dispositivo.
    final useRail = screen != ScreenSize.compact || isLandscape;
    final extendedRail = screen == ScreenSize.large;
    final tabs = homeTabsOf(AppLocalizations.of(context));
    const mapTabIndex = 1;
    final showNotificationBell =
        widget.navigationShell.currentIndex != mapTabIndex;

    ref.watch(widgetDataSyncProvider);

    if (useRail) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBackPressed();
        },
        child: FocusTraversalGroup(
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
                    currentIndex: widget.navigationShell.currentIndex,
                    onTap: _onTap,
                    tabs: tabs,
                    extended: extendedRail,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        ResponsiveScaffold(
                            child: widget.navigationShell),
                        if (showNotificationBell)
                          Positioned(
                            top: TransitSpacing.space8,
                            right: TransitSpacing.space16,
                            child: NotificationBell(
                              unreadCount: unreadCount,
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
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleBackPressed();
      },
      child: FocusTraversalGroup(
        child: BackgroundWrapper(
        child: Scaffold(
      backgroundColor: c.bgRoot,
      extendBody: true,
      body: Stack(
        children: [
          widget.navigationShell,
            if (showNotificationBell)
              Positioned(
                top: TransitSpacing.space8,
                right: TransitSpacing.space16,
                child: SafeArea(
                  bottom: false,
                  child: NotificationBell(
                    unreadCount: unreadCount,
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
          currentIndex: widget.navigationShell.currentIndex,
          onTap: _onTap,
          tabs: tabs,
        ),
      ),
      ), // BackgroundWrapper end
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

