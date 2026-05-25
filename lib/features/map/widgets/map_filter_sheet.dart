import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/transit_button.dart';
import '../map_filter_controller.dart';

void showMapFilterSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return Consumer(
        builder: (ctx, ref, _) {
          final f = ref.watch(mapFilterControllerProvider);
          final ctrl = ref.read(mapFilterControllerProvider.notifier);

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
                  Text(AppLocalizations.of(context).mapFilterTitle,
                      style: TransitTypography.heading(c.textHi)),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title:
                          AppLocalizations.of(context).mapFilterRouteSource),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _FilterChip(
                        label:
                            AppLocalizations.of(context).mapFilterOfficial,
                        selected: f.showOfficial,
                        c: c,
                        onTap: () =>
                            ctrl.setShowOfficial(!f.showOfficial),
                      ),
                      _FilterChip(
                        label: AppLocalizations.of(context)
                            .mapFilterCommunity,
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
                      title:
                          AppLocalizations.of(context).mapFilterUpcoming),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [15, 30, 60]
                        .map((m) => _FilterChip(
                              label: AppLocalizations.of(context)
                                  .mapFilterMinutes(m),
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
                      title: AppLocalizations.of(context)
                          .mapFilterAccessibility),
                  _FilterChip(
                    label: AppLocalizations.of(context)
                        .mapFilterOnlyAccessible,
                    selected: f.onlyAccessible,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyAccessible(!f.onlyAccessible),
                  ),
                  const SizedBox(height: 16),

                  _SectionTitle(
                      c: c,
                      title: AppLocalizations.of(context)
                          .mapFilterFavorites),
                  _FilterChip(
                    label: AppLocalizations.of(context)
                        .mapFilterOnlyFavorites,
                    selected: f.onlyFavorites,
                    c: c,
                    onTap: () =>
                        ctrl.setOnlyFavorites(!f.onlyFavorites),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: TransitButton(
                          label: AppLocalizations.of(context)
                              .actionReset
                              .toUpperCase(),
                          isPrimary: false,
                          isSmall: true,
                          onPressed: ctrl.reset,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TransitButton(
                          label: AppLocalizations.of(context)
                              .actionApply
                              .toUpperCase(),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.2) : c.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.accent : c.border,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.accent : c.textMid,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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
      child:
          Text(title, style: TransitTypography.sectionTitle(c.textMid)),
    );
  }
}
