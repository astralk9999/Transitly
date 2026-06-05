import 'package:flutter/material.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../core/theme/transit_typography.dart';
import '../../../../shared/widgets/transit_button.dart';
import '../../../../shared/widgets/transit_input.dart';
import '../editor_controller.dart';

class StepInfo extends StatelessWidget {
  const StepInfo({
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
    final canContinue =
        controller.codeCtrl.text.isNotEmpty && controller.nameCtrl.text.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Código de línea',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          TransitInput(
            hint: 'Ej: L12',
            controller: controller.codeCtrl,
            onChanged: (_) => controller.refresh(),
          ),
          const SizedBox(height: 16),
          Text('Nombre de la ruta',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          TransitInput(
            hint: 'Ej: Esteve - San Telmo',
            controller: controller.nameCtrl,
            onChanged: (_) => controller.refresh(),
          ),
          const SizedBox(height: 16),
          Text('Tipo de servicio',
              style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          // P2-02: ChoiceChips horizontales scrollables.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: const [
                _ServiceTypeChip(value: 'urban', label: 'Urbano', icon: Icons.directions_bus),
                _ServiceTypeChip(value: 'metropolitan', label: 'Metropolitano', icon: Icons.directions_transit),
                _ServiceTypeChip(value: 'interurban', label: 'Interurbano', icon: Icons.route),
                _ServiceTypeChip(value: 'special', label: 'Especial', icon: Icons.star_outline),
              ]
                  .map((chip) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _ServiceTypeChipBuilder(
                          chip: chip,
                          selected: controller.serviceType == chip.value,
                          onSelected: () {
                            controller.serviceTypeValue = chip.value;
                          },
                          c: c,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Operador', style: TransitTypography.bodySecondary(c.textMid)),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: c.bgInput,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('COMUJESA',
                style: TransitTypography.bodyPrimary(c.textMid)),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: AppLocalizations.of(context).actionNext.toUpperCase(),
              onPressed: canContinue ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceTypeChip {
  const _ServiceTypeChip({
    required this.value,
    required this.label,
    required this.icon,
  });
  final String value;
  final String label;
  final IconData icon;
}

class _ServiceTypeChipBuilder extends StatelessWidget {
  const _ServiceTypeChipBuilder({
    required this.chip,
    required this.selected,
    required this.onSelected,
    required this.c,
  });
  final _ServiceTypeChip chip;
  final bool selected;
  final VoidCallback onSelected;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: Icon(
        chip.icon,
        size: 18,
        color: selected ? Colors.white : c.accent,
      ),
      label: Text(chip.label),
      labelStyle: TransitTypography.bodyPrimary(
        selected ? Colors.white : c.textHi,
      ),
      selectedColor: c.accent,
      backgroundColor: c.bgRaised,
      side: BorderSide(
        color: selected ? c.accent : c.border,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
