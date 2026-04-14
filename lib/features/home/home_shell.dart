import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 600;

    if (wide) {
      return Scaffold(
        backgroundColor: const Color(0xFF0C0C0C),
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: const Color(0xFF0C0C0C),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFF00C896)),
              unselectedIconTheme: const IconThemeData(color: Color(0xFF3A3A3A)),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xFF00C896),
                fontSize: 11,
                fontFamily: 'monospace',
              ),
              unselectedLabelTextStyle: const TextStyle(
                color: Color(0xFF3A3A3A),
                fontSize: 11,
                fontFamily: 'monospace',
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
            const VerticalDivider(width: 1, thickness: 0.5, color: Color(0xFF1A1A1A)),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        backgroundColor: const Color(0xFF0C0C0C),
        selectedItemColor: const Color(0xFF00C896),
        unselectedItemColor: const Color(0xFF3A3A3A),
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: [
          for (final tab in _tabs)
            BottomNavigationBarItem(
              icon: Icon(tab.icon),
              activeIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
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
