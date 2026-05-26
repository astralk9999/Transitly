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
      ColorBlindMode.protanomaly => 'Protanomalía',
      ColorBlindMode.deuteranomaly => 'Deuteranomalía',
      ColorBlindMode.tritanomaly => 'Tritanomalía',
      ColorBlindMode.achromatopsia => 'Acromatopsia',
      ColorBlindMode.achromatomaly => 'Acromatomalía',
    };
  }

  void _showCbmSheet(BuildContext context, WidgetRef ref, TransitColorScheme c) {
    final cbm = ref.read(themeNotifierProvider).colorBlindMode;
    showModalBottomSheet<ColorBlindMode>(
      context: context,
      backgroundColor: c.bgRaised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.appearanceColorBlindSheetTitle,
                    style: TransitTypography.sectionLabel(c.textHi),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: ColorBlindMode.values.map((mode) {
                    return RadioListTile<ColorBlindMode>(
                      value: mode,
                      groupValue: cbm,
                      activeColor: c.accent,
                      title: Text(
                        _cbmLabel(mode),
                        style: TransitTypography.bodyPrimary(c.textHi),
                      ),
                      onChanged: (v) {
                        if (v != null) {
                          ref.read(themeNotifierProvider).colorBlindMode = v;
                        }
                        Navigator.pop(sheetContext, v);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
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
              GestureDetector(
                onTap: () => _showCbmSheet(context, ref, c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: c.bgSurface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _cbmLabel(cbm),
                        style: TransitTypography.bodySmall(c.textHi),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.unfold_more,
                        size: 16,
                        color: c.textMid,
                      ),
                    ],
                  ),
                ),
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
