import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/incident_model.dart';
import '../../../shared/models/route_feedback_model.dart';
import '../../../shared/models/route_suggestion_model.dart';
import 'action_button.dart';

class InboxActionSheets {
  InboxActionSheets._();

  static void showFeedbackSheet(
    BuildContext context, {
    required RouteFeedbackModel feedback,
    required VoidCallback onMarkInReview,
    required VoidCallback onResolve,
    required VoidCallback onReject,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isOpen = feedback.status == FeedbackStatus.submitted ||
        feedback.status == FeedbackStatus.inReview;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  feedback.feedbackType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feedback.description,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      feedback.status.label,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(feedback.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxMarkInReview,
                          color: c.accent,
                          onTap: () {
                            Navigator.pop(ctx);
                            onMarkInReview();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxResolve,
                          color: c.stateOnTime,
                          onTap: () {
                            Navigator.pop(ctx);
                            onResolve();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxReject,
                          color: c.stateCancelled,
                          onTap: () {
                            Navigator.pop(ctx);
                            onReject();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showIncidentSheet(
    BuildContext context, {
    required IncidentModel incident,
    required VoidCallback onMarkInReview,
    required VoidCallback onResolve,
    required VoidCallback onReject,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isOpen =
        incident.status == 'open' || incident.status == 'in_review';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  incident.incidentType.label.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.comment ?? incident.category.label,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      incident.status,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm').format(incident.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                if (isOpen) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxMarkInReview,
                          color: c.accent,
                          onTap: () {
                            Navigator.pop(ctx);
                            onMarkInReview();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxResolve,
                          color: c.stateOnTime,
                          onTap: () {
                            Navigator.pop(ctx);
                            onResolve();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ActionButton(
                          label: l10n.managerInboxReject,
                          color: c.stateCancelled,
                          onTap: () {
                            Navigator.pop(ctx);
                            onReject();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showSuggestionSheet(
    BuildContext context, {
    required RouteSuggestionModel suggestion,
    required VoidCallback onOpen,
  }) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.managerInboxSuggestions.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${suggestion.originText} → ${suggestion.destinationText}',
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
                if (suggestion.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    suggestion.notes!,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${l10n.managerInboxStatus}: ',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                    Text(
                      suggestion.status.label,
                      style: TransitTypography.bodySmall(c.accent),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('dd/MM/yy HH:mm')
                          .format(suggestion.createdAt),
                      style: TransitTypography.bodySmall(c.textLo),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ActionButton(
                    label: l10n.managerInboxOpen,
                    color: c.accent,
                    onTap: () {
                      Navigator.pop(ctx);
                      onOpen();
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}
