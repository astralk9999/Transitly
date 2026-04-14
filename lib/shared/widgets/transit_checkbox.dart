import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class TransitCheckbox extends StatelessWidget {
  const TransitCheckbox(
    this.value,
    this.onChanged,
    this.label, {
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: value ? c.accent : Colors.transparent,
              border: Border.all(
                color: value ? c.accent : c.border,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
            child: value
                ? Icon(Icons.check, size: 14, color: c.bgRoot)
                : null,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TransitTypography.subheading(c.textHi),
          ),
        ],
      ),
    );
  }
}
