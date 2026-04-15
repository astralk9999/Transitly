import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../shared/providers/user_provider.dart';
import '../driver/driver_panel.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'INICIO'),
    _TabItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'MAPA'),
    _TabItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'BUSCAR'),
    _TabItem(icon: Icons.credit_card_outlined, activeIcon: Icons.credit_card, label: 'TARJETA'),
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
    final wide = MediaQuery.sizeOf(context).width > 600;

    if (wide) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: c.bgRoot,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: c.accent),
              unselectedIconTheme: IconThemeData(color: c.textLo),
              selectedLabelTextStyle: GoogleFonts.ibmPlexMono(
                color: c.accent,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelTextStyle: GoogleFonts.ibmPlexMono(
                color: c.textLo,
                fontSize: 10,
              ),
              destinations: [
                for (final tab in _tabs)
                  NavigationRailDestination(
                    icon: Icon(tab.icon),
                    selectedIcon: Icon(tab.activeIcon),
                    label: Text(tab.label),
                  ),
              ],
            ),
            VerticalDivider(width: 1, thickness: 0.5, color: c.border),
            Expanded(
              child: Stack(
                children: [
                  navigationShell,
                  if (isDriver)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _driverFab(context, c),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          navigationShell,
          if (isDriver)
            Positioned(
              bottom: 72,
              right: 16,
              child: _driverFab(context, c),
            ),
        ],
      ),
      bottomNavigationBar: _TransitBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        tabs: _tabs,
      ),
    );
  }

  Widget _driverFab(BuildContext context, TransitColorScheme c) {
    return FloatingActionButton(
      backgroundColor: c.accent,
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => const DriverPanel(),
        );
      },
      child: Icon(Icons.directions_bus, color: c.bgRoot),
    );
  }
}

class _TransitBottomNav extends StatelessWidget {
  const _TransitBottomNav({
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
        color: c.bgRoot,
        border: Border(
          top: BorderSide(color: c.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final isActive = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActive ? tab.activeIcon : tab.icon,
                        size: 20,
                        color: isActive ? c.accent : c.textLo,
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: c.accent,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.icon, required this.activeIcon, required this.label});
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
