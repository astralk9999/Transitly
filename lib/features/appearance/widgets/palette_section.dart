import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/palettes/app_palette.dart';
import '../../../core/theme/palettes/prefab_palettes.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class PalettesSection extends ConsumerWidget {
  const PalettesSection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paletteId =
        ref.watch(themeNotifierProvider.select((n) => n.paletteId));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearancePalettesSection,
            style: TransitTypography.sectionLabel(Colors.white),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.2,
            ),
            itemCount: prefabPalettes.length,
            itemBuilder: (_, i) {
              final p = prefabPalettes[i];
              final selected = p.id == paletteId;
              return PaletteCard(
                palette: p,
                selected: selected,
                c: c,
                onTap: () {
                  ref.read(themeNotifierProvider).paletteId = p.id;
                },
              );
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/appearance/custom'),
              icon: const Icon(Icons.add, size: 18),
              label: Text(l10n.appearanceCustomPaletteAdd,
                  style: TransitTypography.bodyPrimary(c.accent)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: c.accent.withValues(alpha: 0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaletteCard extends StatelessWidget {
  const PaletteCard({
    required this.palette,
    required this.selected,
    required this.c,
    required this.onTap,
    super.key,
  });

  final AppPalette palette;
  final bool selected;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = palette.scheme.accent;

    return Semantics(
      button: true,
      selected: selected,
      label: palette.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: accentColor.withValues(alpha: 0.10),
            border: Border.all(
              color:
                  selected ? accentColor : accentColor.withValues(alpha: 0.25),
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                palette.name,
                style: TransitTypography.bodyPrimary(
                  selected ? accentColor : c.textHi,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
