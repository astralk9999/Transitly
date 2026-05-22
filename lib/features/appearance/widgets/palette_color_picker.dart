import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';

class PaletteColorField extends StatelessWidget {
  const PaletteColorField({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
    required this.scheme,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final TransitColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label color picker',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: scheme.bgRaised,
            border: Border.all(color: scheme.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TransitTypography.bodyPrimary(scheme.textHi),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: scheme.bgInput,
                  border: Border.all(color: scheme.border),
                ),
                child: Text(
                  '#${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0').substring(2)}',
                  style: TransitTypography.errorText(scheme.textMid),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
