import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class FontSection extends ConsumerWidget {
  const FontSection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontScale =
        ref.watch(themeNotifierProvider.select((n) => n.fontScale));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceTextSection,
            style: TransitTypography.sectionLabel(Colors.white),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceFontScale,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${(fontScale * 100).round()}%',
                  style: TransitTypography.bodySmall(c.textMid),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          Slider(
            value: fontScale,
            min: 0.85,
            max: 1.4,
            divisions: 11,
            activeColor: c.accent,
            inactiveColor: c.bgRaised,
            onChanged: (v) {
              ref.read(themeNotifierProvider).fontScale = v;
            },
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.bgRaised,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              l10n.appearanceTextPreview,
              style: TransitTypography.bodyPrimary(c.textHi).copyWith(fontSize: 13 * fontScale),
            ),
          ),
        ],
      ),
    );
  }
}
