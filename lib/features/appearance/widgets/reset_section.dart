import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_preferences.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';

class ResetSection extends ConsumerWidget {
  const ResetSection({required this.c, required this.l10n, super.key});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, ref),
            icon: Icon(Icons.restore, color: c.textMid, size: 18),
            label: Text(
              l10n.appearanceResetButton,
              style: TransitTypography.bodyPrimary(c.textMid),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: c.border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
        title: Text(l10n.appearanceResetButton,
            style: TransitTypography.heading(c.textHi)),
        content: Text(l10n.appearanceResetConfirm,
            style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.actionCancel,
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              final tn = ref.read(themeNotifierProvider);
              tn.paletteId = 'default';
              tn.backgroundId = 'smoke';
              tn.backgroundEnabled = true;
              tn.backgroundOpacity = 1.0;
              tn.fontScale = 1.0;
              tn.colorBlindMode = ColorBlindMode.none;
              tn.dyslexiaFontEnabled = false;
              tn.reduceMotion = false;
              tn.highContrast = false;
              tn.mapStyle = 'streets';
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.appearanceResetDone),
                  backgroundColor: c.bgRaised,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: Text(l10n.appearanceResetButton,
                style: TransitTypography.bodyPrimary(c.accent)),
          ),
        ],
      ),
    );
  }
}
