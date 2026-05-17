import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/incident_model.dart';

class ResolvedIncidentItem extends StatelessWidget {
  const ResolvedIncidentItem({
    required this.incident,
    required this.c,
    required this.onTap,
    super.key,
  });

  final IncidentModel incident;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Color.lerp(c.bgSurface, c.stateCancelled, 0.08) ?? c.bgSurface,
          border: Border.all(color: c.border, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  incident.incidentType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const Spacer(),
                Text(
                  incident.status,
                  style: TransitTypography.bodySmall(
                      incident.status == 'resolved'
                          ? c.stateOnTime
                          : c.stateCancelled),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              incident.comment ?? incident.category.label,
              style: TransitTypography.bodySecondary(c.textHi),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
