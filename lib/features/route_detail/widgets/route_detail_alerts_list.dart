import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/alert_model.dart';
import '../../../shared/models/enums.dart';

class RouteDetailAlertsList extends StatelessWidget {
  const RouteDetailAlertsList({super.key, required this.alerts});

  final List<AlertModel> alerts;

  Color _severityColor(TransitColorScheme c, AlertSeverity severity) {
    return switch (severity) {
      AlertSeverity.info => c.accent,
      AlertSeverity.warning => c.stateDelay,
      AlertSeverity.critical => c.stateCancelled,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final alert in alerts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: c.bgSurface,
                border: Border(
                  left: BorderSide(
                    color: _severityColor(c, alert.severity),
                    width: 3,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.title,
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  const SizedBox(height: 4),
                  Text(alert.body,
                      style: TransitTypography.bodySecondary(c.textMid)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
