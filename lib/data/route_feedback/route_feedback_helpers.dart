import '../../shared/models/enums.dart';

FeedbackStatus feedbackStatusFromString(String s) => switch (s) {
      'open' => FeedbackStatus.submitted,
      'in_review' => FeedbackStatus.inReview,
      'resolved' || 'applied' => FeedbackStatus.applied,
      'rejected' => FeedbackStatus.rejected,
      _ => FeedbackStatus.submitted,
    };
