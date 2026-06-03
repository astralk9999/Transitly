import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/transit_checkbox.dart';

class StepSummary extends StatelessWidget {
  const StepSummary({
    super.key,
    required this.routeName,
    required this.routeColor,
    required this.serviceType,
    required this.stopsCount,
    required this.schedulesCount,
    required this.visibility,
    required this.proposeAsCommunity,
    required this.onProposeChanged,
  });

  final String routeName;
  final String routeColor;
  final String serviceType;
  final int stopsCount;
  final int schedulesCount;
  final String visibility;
  final bool proposeAsCommunity;
  final ValueChanged<bool> onProposeChanged;

  static const _serviceTypeLabels = {
    'urban': 'Urbano',
    'interurban': 'Interurbano',
    'long_distance': 'Larga distancia',
    'school': 'Escolar',
    'on_demand': 'A demanda',
    'custom': 'Personalizado',
  };

  static const _visibilityLabels = {
    'public': 'Pública',
    'unlisted': 'Solo con código / enlace',
    'private': 'Privada',
  };

  Color? _parseColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '');
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = TransitColorScheme.of(isDark);
    final typeLabel = _serviceTypeLabels[serviceType] ?? serviceType;
    final visibilityLabel = _visibilityLabels[visibility] ?? visibility;
    final parsedColor = _parseColor(routeColor);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen',
            style: TransitTypography.heading(colors.textHi),
          ),
          const SizedBox(height: TransitSpacing.space4),
          Text(
            'Revisa tu ruta antes de publicarla.',
            style: TransitTypography.bodySecondary(colors.textMid),
          ),
          const SizedBox(height: TransitSpacing.space24),

          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(TransitSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (parsedColor != null)
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: parsedColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (parsedColor != null)
                      const SizedBox(width: TransitSpacing.space8),
                    Expanded(
                      child: Text(
                        routeName.isNotEmpty
                            ? routeName
                            : '(sin nombre)',
                        style: TransitTypography.heading(colors.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space16),
                Row(
                  children: [
                    _StatItem(
                      icon: Icons.directions_bus,
                      label: '$stopsCount paradas',
                      colors: colors,
                    ),
                    const SizedBox(width: TransitSpacing.space16),
                    _StatItem(
                      icon: Icons.schedule,
                      label: '$schedulesCount horarios',
                      colors: colors,
                    ),
                    const SizedBox(width: TransitSpacing.space16),
                    _StatItem(
                      icon: Icons.category,
                      label: typeLabel,
                      colors: colors,
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space8),
                _StatItem(
                  icon: _visibilityIcon(visibility),
                  label: visibilityLabel,
                  colors: colors,
                ),
              ],
            ),
          ),

          const SizedBox(height: TransitSpacing.space24),

          GlassCard(
            borderRadius: 12,
            padding: const EdgeInsets.all(TransitSpacing.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.emoji_events,
                        size: 20, color: colors.accent),
                    const SizedBox(width: TransitSpacing.space8),
                    Expanded(
                      child: Text(
                        'Contribución comunitaria',
                        style: TransitTypography.bodyPrimary(colors.textHi),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: TransitSpacing.space12),
                TransitCheckbox(
                  proposeAsCommunity,
                  onProposeChanged,
                  'Proponer como ruta comunitaria oficial',
                ),
                const SizedBox(height: TransitSpacing.space8),
                Text(
                  'Si se aprueba, aparecerá en el buscador público como ruta verificada.',
                  style: TransitTypography.bodySmall(colors.textLo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _visibilityIcon(String v) {
    switch (v) {
      case 'public':
        return Icons.public;
      case 'unlisted':
        return Icons.link;
      case 'private':
        return Icons.lock;
      default:
        return Icons.visibility;
    }
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final TransitColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.textLo),
        const SizedBox(width: TransitSpacing.space4),
        Text(
          label,
          style: TransitTypography.bodySmall(colors.textMid),
        ),
      ],
    );
  }
}
