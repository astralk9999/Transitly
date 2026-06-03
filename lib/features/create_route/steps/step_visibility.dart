import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';

class StepVisibility extends StatelessWidget {
  const StepVisibility({
    super.key,
    required this.visibility,
    required this.onChanged,
  });

  final String visibility;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibilidad',
            style: TransitTypography.heading(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space4),
          Text(
            'Controla quién puede ver esta ruta.',
            style: TransitTypography.bodySecondary(colors.textMid),
          ),
          const SizedBox(height: TransitSpacing.space24),

          _VisibilityOption(
            value: 'public',
            groupValue: visibility,
            icon: Icons.public,
            title: 'Pública',
            subtitle: 'Visible en buscador global',
            onChanged: onChanged,
            colors: colors,
          ),
          const SizedBox(height: TransitSpacing.space12),

          _VisibilityOption(
            value: 'unlisted',
            groupValue: visibility,
            icon: Icons.link,
            title: 'Solo con código / enlace',
            subtitle: 'No aparece en buscador',
            onChanged: onChanged,
            colors: colors,
          ),
          const SizedBox(height: TransitSpacing.space12),

          _VisibilityOption(
            value: 'private',
            groupValue: visibility,
            icon: Icons.lock,
            title: 'Privada',
            subtitle: 'Solo tú',
            onChanged: onChanged,
            colors: colors,
          ),
        ],
      ),
    );
  }
}

class _VisibilityOption extends StatelessWidget {
  const _VisibilityOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    required this.colors,
  });

  final String value;
  final String groupValue;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return Pressable(
      onTap: () => onChanged(value),
      child: GlassCard(
        borderRadius: 12,
        useAccentBorder: selected,
        accentColor: colors.accent,
        padding: const EdgeInsets.all(TransitSpacing.space16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? colors.accent.withValues(alpha: 0.15)
                    : colors.bgInput,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 22,
                color: selected ? colors.accent : colors.textMid,
              ),
            ),
            const SizedBox(width: TransitSpacing.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TransitTypography.bodyPrimary(
                      selected ? colors.accent : colors.textHi,
                    ),
                  ),
                  const SizedBox(height: TransitSpacing.space2),
                  Text(
                    subtitle,
                    style: TransitTypography.bodySmall(colors.textLo),
                  ),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              activeColor: colors.accent,
              fillColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return colors.accent;
                }
                return colors.textLo;
              }),
            ),
          ],
        ),
      ),
    );
  }
}
