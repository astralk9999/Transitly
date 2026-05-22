import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/glass_card.dart';

class HomeAlertItem extends StatelessWidget {
  const HomeAlertItem({
    super.key,
    required this.c,
    required this.alert,
  });

  final TransitColorScheme c;
  final AlertModel alert;

  @override
  Widget build(BuildContext context) {
    final Color severityColor;
    switch (alert.severity) {
      case AlertSeverity.info:
        severityColor = c.neonBlue;
      case AlertSeverity.warning:
        severityColor = c.stateDelay;
      case AlertSeverity.critical:
        severityColor = c.stateCancelled;
    }

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 12,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 32,
            decoration: BoxDecoration(
              color: severityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.title,
              style: TransitTypography.bodySecondary(c.textHi),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
