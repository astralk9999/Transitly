import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';

/// Tab metadata shared between side-rail and bottom nav.
class HomeTabItem {
  const HomeTabItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.branchIndex,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Índice de la rama en el StatefulShellRoute (`app_router.dart`). Es FIJO
  /// aunque alguna tab se oculte de la barra, para que goBranch siga apuntando
  /// a la pantalla correcta: inicio=0, mapa=1, buscar=2, tarjeta=3, perfil=4.
  final int branchIndex;
}

/// Tabs visibles en la barra de navegación. El orden de los branches en
/// `app_router.dart` es inicio/mapa/buscar/tarjeta/perfil (0..4). Cada tab
/// lleva su `branchIndex` fijo para poder ocultar alguna sin desalinear.
List<HomeTabItem> homeTabsOf(AppLocalizations l10n) => <HomeTabItem>[
      HomeTabItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: l10n.tabHome.toUpperCase(),
        branchIndex: 0,
      ),
      HomeTabItem(
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
        label: l10n.tabMap.toUpperCase(),
        branchIndex: 1,
      ),
      HomeTabItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search,
        label: l10n.tabSearch.toUpperCase(),
        branchIndex: 2,
      ),
      HomeTabItem(
        icon: Icons.nfc_outlined,
        activeIcon: Icons.nfc,
        label: l10n.tabCard.toUpperCase(),
        branchIndex: 3,
      ),
      HomeTabItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: l10n.tabProfile.toUpperCase(),
        branchIndex: 4,
      ),
    ];
