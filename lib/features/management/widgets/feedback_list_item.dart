import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_feedback_model.dart';

class FeedbackListItem extends StatelessWidget {
  const FeedbackListItem({
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
    final priorityColor = switch (feedback.autoPriority) {
      Priority.high || Priority.urgent => c.stateCancelled,
      Priority.medium => c.stateDelay,
      _ => c.textMid,
    };
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border(
              left: BorderSide(color: priorityColor, width: 2),
              top: BorderSide(color: c.border, width: 0.5),
              right: BorderSide(color: c.border, width: 0.5),
              bottom: BorderSide(color: c.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                  feedback.feedbackType.label.toUpperCase(),
                  style: TransitTypography.inboxTypeTag(c.textMid),
                  ),
                  const Spacer(),
                  Text(
                    feedback.status.label,
                    style: TransitTypography.bodySmall(c.accent),
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
      ),
    );
  }
}
