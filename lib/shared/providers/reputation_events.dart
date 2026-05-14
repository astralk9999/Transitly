import '../../l10n/generated/app_localizations.dart';

class ReputationEvents {
  static const int incidentCreated = 5;
  static const int incidentRejectedSpam = -10;
  static const int feedbackSubmitted = 3;
  static const int feedbackAccepted = 10;
  static const int suggestionCreated = 5;
  static const int suggestionVoteReceived = 2;
  static const int suggestionVerified = 20;
  static const int suggestionOfficial = 50;
  static const int duplicateReport = 1;

  static String labelFor(String event, AppLocalizations l10n) => switch (event) {
        'incidentCreated' => l10n.reputationEventIncidentCreated,
        'incidentRejectedSpam' => l10n.reputationEventIncidentRejectedSpam,
        'feedbackSubmitted' => l10n.reputationEventFeedbackSubmitted,
        'feedbackAccepted' => l10n.reputationEventFeedbackAccepted,
        'suggestionCreated' => l10n.reputationEventSuggestionCreated,
        'suggestionVoteReceived' => l10n.reputationEventSuggestionVoteReceived,
        'suggestionVerified' => l10n.reputationEventSuggestionVerified,
        'suggestionOfficial' => l10n.reputationEventSuggestionOfficial,
        'duplicateReport' => l10n.reputationEventDuplicateReport,
        _ => event,
      };
}
