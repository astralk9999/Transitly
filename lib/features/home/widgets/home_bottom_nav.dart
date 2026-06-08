import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import 'home_tab_item.dart';

/// Glass-style bottom navigation bar for mobile layouts.
///
/// Renders a pill indicator that animates horizontally across tabs.
class HomeBottomNav extends StatelessWidget {
  const HomeBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  /// Altura interna del nav bar (sin contar safe area inferior).
  /// La usan los sheets/dialogs para no quedar tapados.
  /// 64 dp cumple WCAG 2.5.5 (target size) con margen.
  static const double height = 64;

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<HomeTabItem> tabs;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border(
          top: BorderSide(
            color:
                isDark ? c.border : Colors.black.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.symmetric(horizontal: 12),
        child: SizedBox(
          height: 64,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final tabWidth = constraints.maxWidth / tabs.length;
              // Posición de la pastilla según la posición VISIBLE de la tab
              // activa (no su branchIndex, que puede saltarse números si hay
              // pestañas ocultas).
              final activePos =
                  tabs.indexWhere((t) => t.branchIndex == currentIndex);
              final pillLeft =
                  tabWidth * (activePos < 0 ? 0 : activePos) + (tabWidth - 28) / 2;

              return Stack(
                children: [
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
                  Row(
                    children: List.generate(tabs.length, (i) {
                      final tab = tabs[i];
                      final isActive = tab.branchIndex == currentIndex;
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
                                onTap: () => onTap(tab.branchIndex),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 64,
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
                                          isActive ? tab.activeIcon : tab.icon,
                                          size: 21,
                                          color: isActive ? c.accent : c.textHi,
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
                                              : c.textHi.withValues(alpha: 0.35),
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
