import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ReputationHistoryList extends StatelessWidget {
  const ReputationHistoryList({
    required this.c,
    required this.l10n,
    super.key,
  });

  static final _events = const [
    ('incidentCreated', Icons.warning_amber, 5),
    ('feedbackSubmitted', Icons.feedback, 3),
    ('feedbackAccepted', Icons.check_circle, 10),
    ('suggestionCreated', Icons.lightbulb, 5),
    ('suggestionVoteReceived', Icons.thumb_up, 2),
    ('suggestionVerified', Icons.verified, 20),
    ('suggestionOfficial', Icons.auto_awesome, 50),
    ('duplicateReport', Icons.content_copy, 1),
    ('incidentRejectedSpam', Icons.block, -10),
  ];

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: l10n.reputationHowToEarn, c: c),
        const SizedBox(height: 8),
        _EventsCard(c: c, l10n: l10n, events: _events),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.c});

  final String title;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GradientText(
        title.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        gradient: c.gradientAccent,
      ),
    );
  }
}

class _EventsCard extends StatelessWidget {
  const _EventsCard({
    required this.c,
    required this.l10n,
    required this.events,
  });

  final TransitColorScheme c;
  final AppLocalizations l10n;
  final List<(String, IconData, int)> events;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: events.map((e) {
          final eventKey = e.$1;
          final icon = e.$2;
          final pts = e.$3;
          final label = switch (eventKey) {
            'incidentCreated' => l10n.reputationEventIncidentCreated,
            'incidentRejectedSpam' => l10n.reputationEventIncidentRejectedSpam,
            'feedbackSubmitted' => l10n.reputationEventFeedbackSubmitted,
            'feedbackAccepted' => l10n.reputationEventFeedbackAccepted,
            'suggestionCreated' => l10n.reputationEventSuggestionCreated,
            'suggestionVoteReceived' => l10n.reputationEventSuggestionVoteReceived,
            'suggestionVerified' => l10n.reputationEventSuggestionVerified,
            'suggestionOfficial' => l10n.reputationEventSuggestionOfficial,
            'duplicateReport' => l10n.reputationEventDuplicateReport,
            _ => eventKey,
          };
          final sign = pts >= 0 ? '+' : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                ),
                Text(
                  '$sign$pts',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pts >= 0 ? c.stateOnTime : c.stateCancelled,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
