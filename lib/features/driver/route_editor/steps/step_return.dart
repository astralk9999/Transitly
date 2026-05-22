import 'package:flutter/material.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../editor_controller.dart';

class StepReturn extends StatelessWidget {
  const StepReturn({
    super.key,
    required this.controller,
    required this.onNext,
  });

  final RouteEditorController controller;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('¿Cómo es la vuelta?',
              style: TransitTypography.heading(c.textHi)),
          const SizedBox(height: 16),
          _Option(
            c: c,
            value: 'invert',
            selected: controller.returnChoice,
            icon: Icons.swap_horiz,
            title: 'Invertir recorrido',
            subtitle:
                'Genera automáticamente la vuelta invirtiendo las paradas',
            onSelect: () => controller.returnChoiceValue = 'invert',
          ),
          const SizedBox(height: 8),
          _Option(
            c: c,
            value: 'new',
            selected: controller.returnChoice,
            icon: Icons.edit,
            title: 'Trazar nueva vuelta',
            subtitle: 'Dibujar un recorrido diferente para la vuelta',
            onSelect: () => controller.returnChoiceValue = 'new',
          ),
          const SizedBox(height: 8),
          _Option(
            c: c,
            value: 'oneway',
            selected: controller.returnChoice,
            icon: Icons.arrow_forward,
            title: 'Solo ida',
            subtitle: 'Esta línea no tiene recorrido de vuelta',
            onSelect: () => controller.returnChoiceValue = 'oneway',
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: AppLocalizations.of(context).actionNext.toUpperCase(),
              onPressed:
                  controller.returnChoice.isNotEmpty ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.c,
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onSelect,
  });

  final TransitColorScheme c;
  final String value;
  final String selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.bgSurface,
          border: Border.all(
            color: isSelected ? c.accent : c.border,
            width: isSelected ? 1 : 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: isSelected ? c.accent : c.textMid),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TransitTypography.bodyPrimary(c.textHi)),
                  Text(subtitle,
                      style: TransitTypography.bodySmall(c.textMid)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, size: 20, color: c.accent),
          ],
        ),
      ),
    );
  }
}
