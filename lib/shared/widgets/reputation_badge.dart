import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../models/enums.dart';

class ReputationBadge extends StatelessWidget {
  const ReputationBadge(this.level, {super.key});

  final ReputationLevel level;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final Color color;
    switch (level) {
      case ReputationLevel.new_:
        color = c.textLo;
      case ReputationLevel.contributor:
        color = c.textMid;
      case ReputationLevel.trusted:
        color = c.accent;
      case ReputationLevel.expert:
        color = c.stateOnTime;
    }

    return Semantics(
      label: 'Reputación: ${level.label}',
      child: Container(
        padding: TransitSpacing.paddingBadge,
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(color: color, width: TransitSpacing.strokeThin),
          borderRadius: BorderRadius.circular(TransitSpacing.radiusXs),
        ),
        child: Text(
          level.label.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }
}
