import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class AccessibilitySection extends ConsumerWidget {
  const AccessibilitySection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _cbmLabel(ColorBlindMode mode) {
    return switch (mode) {
      ColorBlindMode.none => l10n.appearanceColorBlindNone,
      ColorBlindMode.protanopia => l10n.appearanceColorBlindProtanopia,
      ColorBlindMode.deuteranopia => l10n.appearanceColorBlindDeuteranopia,
      ColorBlindMode.tritanopia => l10n.appearanceColorBlindTritanopia,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cbm =
        ref.watch(themeNotifierProvider.select((n) => n.colorBlindMode));
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
                  l10n.appearanceColorBlindMode,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<ColorBlindMode>(
                value: cbm,
                underline: const SizedBox.shrink(),
                dropdownColor: c.bgRaised,
                style: TransitTypography.bodySmall(c.textHi),
                icon: Icon(Icons.expand_more, color: c.textMid, size: 20),
                selectedItemBuilder: (_) => ColorBlindMode.values
                    .map((m) => Align(
                          alignment: Alignment.centerRight,
                          child: Text(_cbmLabel(m),
                              style:
                                  TransitTypography.bodySmall(c.textHi)),
                        ))
                    .toList(),
                items: ColorBlindMode.values
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_cbmLabel(m)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(themeNotifierProvider).colorBlindMode = v;
                  }
                },
              ),
            ],
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
        ],
      ),
    );
  }
}
