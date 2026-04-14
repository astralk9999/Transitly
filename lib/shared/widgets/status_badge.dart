import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.text, this.stateColor, {super.key});

  final String text;
  final Color stateColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: stateColor, width: 0.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.0,
          color: stateColor,
        ),
      ),
    );
  }
}
