import 'package:flutter/material.dart';

import '../../../../core/theme/transit_colors.dart';
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
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: c.bgInput,
              border: Border.all(color: c.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: controller.serviceType,
                isExpanded: true,
                dropdownColor: c.bgSurface,
                style: TransitTypography.bodyPrimary(c.textHi),
                items: const [
                  DropdownMenuItem(value: 'urban', child: Text('Urbano')),
                  DropdownMenuItem(
                      value: 'metropolitan', child: Text('Metropolitano')),
                  DropdownMenuItem(
                      value: 'interurban', child: Text('Interurbano')),
                  DropdownMenuItem(value: 'special', child: Text('Especial')),
                ],
                onChanged: (v) {
                  if (v != null) controller.serviceTypeValue = v;
                },
              ),
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
              label: 'SIGUIENTE',
              onPressed: canContinue ? onNext : null,
            ),
          ),
        ],
      ),
    );
  }
}
