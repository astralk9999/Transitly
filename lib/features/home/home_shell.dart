import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/smoke_background.dart';
import '../driver/driver_panel.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'INICIO'),
    _TabItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'MAPA'),
    _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'BUSCAR'),
    _TabItem(icon: Icons.nfc_outlined, activeIcon: Icons.nfc, label: 'TARJETA'),
    _TabItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'PERFIL'),
  ];

  void _onTap(int index) {
    navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDriver = ref.watch(isDriverModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final screen = ResponsiveScaffold.screenSizeOf(context);
    final useRail = screen != ScreenSize.compact;
    final extendedRail = screen == ScreenSize.large;

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
                _SideNav(
                  currentIndex: navigationShell.currentIndex,
                  onTap: _onTap,
                  tabs: _tabs,
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
                          child: _driverFab(context, c),
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
              child: _driverFab(context, c),
            ),
        ],
      ),
      bottomNavigationBar: _GlassNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        tabs: _tabs,
      ),
    );
  }

  Widget _driverFab(BuildContext context, TransitColorScheme c) {
    return Material(
      color: c.accent.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: c.accent.withValues(alpha: 0.3), width: 0.5),
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
          child: Icon(Icons.directions_bus, color: c.accent, size: 24),
        ),
      ),
    );
  }
}

/// Custom side navigation for desktop/tablet layouts.
class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    this.extended = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;
  final bool extended;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final width = extended ? 180.0 : 72.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: c.bgRoot.withValues(alpha: 0.85),
        border: Border(
          right: BorderSide(
            color: c.border.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: extended
                  ? Text(
                      'TRANSITLY',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                        color: c.accent,
                      ),
                    )
                  : Text(
                      'T',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: c.accent,
                      ),
                    ),
            ),
            const SizedBox(height: 32),
            // Nav items
            ...List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              final tab = tabs[i];
              return _SideNavItem(
                icon: isActive ? tab.activeIcon : tab.icon,
                label: tab.label,
                isActive: isActive,
                extended: extended,
                accent: c.accent,
                textColor: c.textLo,
                onTap: () => onTap(i),
              );
            }),
            const Spacer(),
            // Version tag at bottom
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                extended ? 'v0.1.0' : '·',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: c.textLo.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SideNavItem extends StatefulWidget {
  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.extended,
    required this.accent,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final bool extended;
  final Color accent;
  final Color textColor;
  final VoidCallback onTap;

  @override
  State<_SideNavItem> createState() => _SideNavItemState();
}

class _SideNavItemState extends State<_SideNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive
        ? widget.accent
        : _hovered
            ? widget.textColor.withValues(alpha: 0.8)
            : widget.textColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Tooltip(
            message: widget.label,
            waitDuration: const Duration(milliseconds: 600),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: widget.extended ? 14 : 0,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: widget.isActive
                    ? widget.accent.withValues(alpha: 0.12)
                    : _hovered
                        ? widget.accent.withValues(alpha: 0.05)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: widget.isActive
                    ? Border.all(
                        color: widget.accent.withValues(alpha: 0.2),
                        width: 0.5,
                      )
                    : null,
              ),
              child: widget.extended
                  ? Row(
                      children: [
                        Icon(widget.icon, size: 20, color: color),
                        const SizedBox(width: 12),
                        Text(
                          widget.label,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: widget.isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                            letterSpacing: 0.5,
                            color: color,
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Icon(widget.icon, size: 22, color: color),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Apple-style navigation bar for mobile with pill indicator.
class _GlassNav extends StatelessWidget {
  const _GlassNav({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
          decoration: BoxDecoration(
            color: isDark ? c.bgSurface : c.bgSurface,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? c.border
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 56,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final tabWidth = constraints.maxWidth / tabs.length;
                  final pillLeft =
                      tabWidth * currentIndex + (tabWidth - 28) / 2;

                  return Stack(
                    children: [
                      // Pill indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOutCubic,
                        top: 4,
                        left: pillLeft,
                        child: Container(
                          width: 28,
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1.5),
                            color: c.accent,
                            boxShadow: [
                              BoxShadow(
                                color: c.accent.withValues(alpha: 0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tab items
                      Row(
                        children: List.generate(tabs.length, (i) {
                          final isActive = i == currentIndex;
                          final tab = tabs[i];
                          return Expanded(
                            child: Semantics(
                              label: tab.label,
                              button: true,
                              selected: isActive,
                              child: Tooltip(
                                message: tab.label,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => onTap(i),
                                    child: SizedBox(
                                      height: 56,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 4),
                                          AnimatedOpacity(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            opacity: isActive ? 1.0 : 0.35,
                                            child: Icon(
                                              isActive
                                                  ? tab.activeIcon
                                                  : tab.icon,
                                              size: 21,
                                              color: isActive
                                                  ? c.accent
                                                  : c.textHi,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          AnimatedDefaultTextStyle(
                                            duration: const Duration(
                                                milliseconds: 200),
                                            style: GoogleFonts.ibmPlexMono(
                                              fontSize: 9,
                                              fontWeight: isActive
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: isActive
                                                  ? c.accent
                                                  : c.textHi.withValues(
                                                      alpha: 0.35),
                                              letterSpacing: 0.5,
                                            ),
                                            child: Text(tab.label),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
  }
}

class _TabItem {
  const _TabItem(
      {required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
