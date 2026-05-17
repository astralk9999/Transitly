import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_feedback_model.dart';

class ResolvedFeedbackItem extends StatelessWidget {
  const ResolvedFeedbackItem({
    required this.feedback,
    required this.c,
    required this.onTap,
    super.key,
  });

  final RouteFeedbackModel feedback;
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
                  feedback.feedbackType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const Spacer(),
                Text(
                  feedback.status.label,
                  style: TransitTypography.bodySmall(
                      feedback.status == FeedbackStatus.applied
                          ? c.stateOnTime
                          : c.stateCancelled),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              feedback.description,
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
