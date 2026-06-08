import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'home_tab_item.dart';

/// Custom side navigation for desktop/tablet layouts.
class HomeSideNav extends StatelessWidget {
  const HomeSideNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
    this.extended = false,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeTabItem> tabs;
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
            // Logo de la marca (web/escritorio). En modo extendido el logo
            // va acompañado del nombre.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: extended
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          isDark
                              ? 'assets/branding/transitly_logo_white_square.png'
                              : 'assets/branding/transitly_logo.png',
                          width: 32,
                          height: 32,
                          filterQuality: FilterQuality.high,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            AppLocalizations.of(context).appTitle.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.asset(
                      isDark
                          ? 'assets/branding/transitly_logo_white_square.png'
                          : 'assets/branding/transitly_logo.png',
                      width: 36,
                      height: 36,
                      filterQuality: FilterQuality.high,
                    ),
            ),
            const SizedBox(height: 32),
            ...List.generate(tabs.length, (i) {
              final tab = tabs[i];
              final isActive = tab.branchIndex == currentIndex;
              return _SideNavItem(
                icon: isActive ? tab.activeIcon : tab.icon,
                label: tab.label,
                isActive: isActive,
                extended: extended,
                accent: c.accent,
                textColor: c.textLo,
                onTap: () => onTap(tab.branchIndex),
              );
            }),
            const Spacer(),
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
