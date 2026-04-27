import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Tab metadata shared between side-rail and bottom nav.
class HomeTabItem {
  const HomeTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// The five tabs rendered by [HomeShell]. Order must match the routes in
/// `app_router.dart` (inicio / mapa / buscar / tarjeta / perfil).
List<HomeTabItem> homeTabsOf(AppLocalizations l10n) => <HomeTabItem>[
      HomeTabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: l10n.tabHome.toUpperCase(),
      ),
      HomeTabItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
        label: l10n.tabMap.toUpperCase(),
      ),
      HomeTabItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: l10n.tabSearch.toUpperCase(),
      ),
      HomeTabItem(
        icon: Icons.nfc_outlined,
        activeIcon: Icons.nfc,
        label: l10n.tabCard.toUpperCase(),
      ),
      HomeTabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.tabProfile.toUpperCase(),
      ),
    ];
