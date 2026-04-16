import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/enums.dart';

class CapacityIndicator extends StatelessWidget {
  const CapacityIndicator(this.capacity, {super.key, this.showLabel = false});

  final BusCapacity capacity;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final Color dotColor;
    switch (capacity) {
      case BusCapacity.empty:
      case BusCapacity.seatsAvailable:
        dotColor = c.accent;
      case BusCapacity.halfFull:
        dotColor = c.stateDelay;
      case BusCapacity.full:
      case BusCapacity.overcrowded:
        dotColor = c.stateCancelled;
    }

    return Semantics(
      label: 'Ocupación: ${capacity.label}',
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            capacity.label,
            style: TransitTypography.bodySmall(dotColor),
          ),
        ],
      ],
    ),
    );
  }
}
