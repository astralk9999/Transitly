import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class DataFreshnessIndicator extends StatelessWidget {
  const DataFreshnessIndicator(
    this.lastUpdated, {
    super.key,
    this.pendingFeedback = 0,
  });

  final DateTime lastUpdated;
  final int pendingFeedback;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final days = DateTime.now().difference(lastUpdated).inDays;

    IconData icon;
    Color color;
    String text;

    if (days < 7) {
      icon = Icons.check_circle_outline;
      color = c.accent;
      text = days == 0
          ? 'Actualizado hoy'
          : days == 1
              ? 'Actualizado ayer'
              : 'Actualizado hace $days días';
    } else if (days <= 30) {
      icon = Icons.access_time;
      color = c.textMid;
      text = 'Actualizado hace $days días';
    } else {
      icon = Icons.warning_amber;
      color = c.stateDelay;
      text = 'Actualizado hace $days días';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TransitTypography.bodySmall(color)),
        if (pendingFeedback > 0) ...[
          Text(
            ' · $pendingFeedback pendientes',
            style: TransitTypography.bodySmall(c.stateDelay),
          ),
        ],
      ],
    );
  }
}
