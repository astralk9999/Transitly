import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/route_feedback/route_feedback_helpers.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('feedbackStatusFromString', () {
    test('maps open to submitted', () {
      expect(feedbackStatusFromString('open'), FeedbackStatus.submitted);
    });

    test('maps in_review to inReview', () {
      expect(feedbackStatusFromString('in_review'), FeedbackStatus.inReview);
    });

    test('maps resolved and applied to applied', () {
      expect(feedbackStatusFromString('resolved'), FeedbackStatus.applied);
      expect(feedbackStatusFromString('applied'), FeedbackStatus.applied);
    });

    test('maps rejected to rejected', () {
      expect(feedbackStatusFromString('rejected'), FeedbackStatus.rejected);
    });

    test('unknown strings fallback to submitted', () {
      expect(feedbackStatusFromString('unknown'), FeedbackStatus.submitted);
      expect(feedbackStatusFromString(''), FeedbackStatus.submitted);
      expect(feedbackStatusFromString('bogus'), FeedbackStatus.submitted);
    });
  });
}
