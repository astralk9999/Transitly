import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/transit_button.dart';
import '../map_filter_controller.dart';
import 'zone_company_line_tree.dart';

void showMapFilterSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
      useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final f = ref.watch(mapFilterControllerProvider);
          final ctrl = ref.read(mapFilterControllerProvider.notifier);
          final l10n = AppLocalizations.of(context);

          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: c.bgRoot,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(ctx).padding.bottom,
                ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: c.textLo.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Líneas y zonas'),
                  const ZoneCompanyLineTree(),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterRouteSource),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label: l10n.mapFilterOfficial,
                        selected: f.showOfficial,
                        c: c,
                        onTap: () =>
                            ctrl.setShowOfficial(!f.showOfficial),
                      ),
                      _FilterChip(
                        label: l10n.mapFilterCommunity,
                        selected: f.showCommunity,
                        c: c,
                        onTap: () =>
                            ctrl.setShowCommunity(!f.showCommunity),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterUpcoming),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 60]
                        .map((m) => _FilterChip(
                              label: l10n.mapFilterMinutes(m),
                              selected: f.nextMinutes == m,
                              c: c,
                              onTap: () => ctrl.setNextMinutes(
                                  f.nextMinutes == m ? 0 : m),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterAccessibility),
                  _FilterChip(
                    label: l10n.mapFilterOnlyAccessible,
                    selected: f.onlyAccessible,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyAccessible(!f.onlyAccessible),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: l10n.mapFilterFavorites),
                  _FilterChip(
                    label: l10n.mapFilterOnlyFavorites,
                    selected: f.onlyFavorites,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyFavorites(!f.onlyFavorites),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(c: c, title: 'Paradas'),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Mostrar paradas',
                            style: TransitTypography.bodyPrimary(c.textHi)),
                      ),
                      Switch.adaptive(
                        value: f.showAllStops,
                        activeTrackColor: c.accent,
                        onChanged: (v) => ctrl.setShowAllStops(v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: l10n.actionReset.toUpperCase(),
                          isPrimary: false,
                          isSmall: true,
                          onPressed: ctrl.reset,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TransitButton(
                          label: l10n.actionApply.toUpperCase(),
                          isSmall: true,
                          onPressed: () => Navigator.of(sheetCtx).pop(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );
    },
    );
  }

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.c,
    this.onTap,
  });
  final String label;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.2) : c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? c.accent.withValues(alpha: 0.6) : c.border.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.accent : c.textLo,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.c, required this.title});
  final TransitColorScheme c;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: TransitTypography.sectionTitle(c.textMid)),
    );
  }
}
