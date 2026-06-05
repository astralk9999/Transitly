import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class AccessibilitySection extends ConsumerWidget {
  const AccessibilitySection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reduceMotion =
        ref.watch(themeNotifierProvider.select((n) => n.reduceMotion));
    final highContrast =
        ref.watch(themeNotifierProvider.select((n) => n.highContrast));

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceAccessibilitySection,
            style: TransitTypography.sectionLabel(Colors.white),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.appearanceReduceMotion,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              Switch.adaptive(
                value: reduceMotion,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeNotifierProvider).reduceMotion = v;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appearanceHighContrast,
                          style: TransitTypography.bodyPrimary(c.textHi),
                        ),
                        Text(
                          l10n.appearanceHighContrastSubtitle,
                          style: TransitTypography.bodySmall(c.textLo),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: highContrast,
                    activeTrackColor: c.accent,
                    onChanged: (v) {
                      ref.read(themeNotifierProvider).highContrast = v;
                    },
                  ),
                ],
              ),
              if (highContrast)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Row(
                    children: [
                      Icon(Icons.subdirectory_arrow_right,
                          size: 16, color: c.textLo),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appearanceHcPreserveAccent,
                              style: TransitTypography.bodySecondary(c.textHi),
                            ),
                            Text(
                              'Si está OFF el alto contraste usa B/N puro.',
                              style: TransitTypography.bodySmall(c.textLo),
                            ),
                          ],
                        ),
                      ),
                      Switch.adaptive(
                        value: ref.watch(themeNotifierProvider
                            .select((n) => n.hcPreserveAccent)),
                        activeTrackColor: c.accent,
                        onChanged: (v) {
                          ref.read(themeNotifierProvider).hcPreserveAccent = v;
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
