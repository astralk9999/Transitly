import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class BrightnessSection extends ConsumerWidget {
  const BrightnessSection({
    required this.c,
    required this.l10n,
    required this.mode,
    super.key,
  });

  final TransitColorScheme c;
  final AppLocalizations l10n;
  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.appearanceBrightnessSection,
            style: TransitTypography.sectionLabel(Colors.white),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment<ThemeMode>(
                value: ThemeMode.system,
                label: Text(l10n.appearanceBrightnessSystem,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.light,
                label: Text(l10n.appearanceBrightnessLight,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
              ButtonSegment<ThemeMode>(
                value: ThemeMode.dark,
                label: Text(l10n.appearanceBrightnessDark,
                    style: TransitTypography.bodySmall(c.textHi)),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (newMode) {
              ref.read(themeModeProvider.notifier).state = newMode.first;
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return c.accent;
                return c.bgRaised;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return c.textMid;
              }),
              side: WidgetStateProperty.all(
                BorderSide(color: c.border, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
