import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/providers/widget_appearance_config_provider.dart';
import '../../../shared/widgets/glass_card.dart';

/// Panel reutilizable con los 3 selectores de apariencia del widget:
/// tamaño, tema independiente y frecuencia de refresco. Se inserta al
/// final de cada pantalla de configuración de widget.
class WidgetAppearancePanel extends ConsumerWidget {
  const WidgetAppearancePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final cfg = ref.watch(widgetAppearanceConfigProvider);
    final notifier = ref.read(widgetAppearanceConfigProvider.notifier);

    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('APARIENCIA DEL WIDGET',
              style: TransitTypography.sectionTitle(c.textMid)),
          const SizedBox(height: 14),

          Text('Tamaño', style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<WidgetSize>(
            segments: const [
              ButtonSegment(value: WidgetSize.small, label: Text('S')),
              ButtonSegment(value: WidgetSize.medium, label: Text('M')),
              ButtonSegment(value: WidgetSize.large, label: Text('L')),
            ],
            selected: {cfg.size},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setSize(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 14),

          Text('Tema', style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<WidgetTheme>(
            segments: const [
              ButtonSegment(value: WidgetTheme.auto, label: Text('Auto')),
              ButtonSegment(value: WidgetTheme.light, label: Text('Claro')),
              ButtonSegment(value: WidgetTheme.dark, label: Text('Oscuro')),
              ButtonSegment(value: WidgetTheme.brand, label: Text('Marca')),
            ],
            selected: {cfg.theme},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setTheme(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 14),

          Text('Frecuencia de refresco',
              style: TransitTypography.bodySecondary(c.textHi)),
          const SizedBox(height: 6),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 15, label: Text('15 min')),
              ButtonSegment(value: 30, label: Text('30 min')),
              ButtonSegment(value: 60, label: Text('1 h')),
            ],
            selected: {cfg.refreshMinutes},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) notifier.setRefreshMinutes(s.first);
            },
            style: _segmentedStyle(c),
          ),
          const SizedBox(height: 8),
          Text(
            'La frecuencia se aplica al refresco periódico cuando esté '
            'disponible; por ahora el widget se actualiza al abrir la app '
            'y con el botón Refrescar / TEST.',
            style: TransitTypography.bodySmall(c.textLo),
          ),
        ],
      ),
    );
  }

  ButtonStyle _segmentedStyle(TransitColorScheme c) {
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return c.accent;
        return c.bgRaised;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return c.textMid;
      }),
      side: WidgetStateProperty.all(
        BorderSide(color: c.border, width: 1),
      ),
    );
  }
}
