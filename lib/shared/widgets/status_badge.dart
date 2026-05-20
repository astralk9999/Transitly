import 'package:flutter/material.dart';

import '../../core/theme/transit_typography.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, this.stateColor, {super.key});

  final String text;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: stateColor.withValues(alpha: 0.12),
        border: Border.all(color: stateColor.withValues(alpha: 0.25), width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TransitTypography.inboxTypeTag(stateColor),
      ),
    );
  }
}
