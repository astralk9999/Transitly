import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/route_feedback/route_feedback_helpers.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('feedbackStatusFromString', () {
    test('open → submitted', () {
      expect(feedbackStatusFromString('open'), FeedbackStatus.submitted);
    });

    test('in_review → inReview', () {
      expect(feedbackStatusFromString('in_review'), FeedbackStatus.inReview);
    });

    test('resolved → applied', () {
      expect(feedbackStatusFromString('resolved'), FeedbackStatus.applied);
    });

    test('applied → applied', () {
      expect(feedbackStatusFromString('applied'), FeedbackStatus.applied);
    });

    test('rejected → rejected', () {
      expect(feedbackStatusFromString('rejected'), FeedbackStatus.rejected);
    });

    test('unknown status defaults to submitted', () {
      expect(feedbackStatusFromString('unknown_status'), FeedbackStatus.submitted);
    });

    test('empty string defaults to submitted', () {
      expect(feedbackStatusFromString(''), FeedbackStatus.submitted);
    });
  });
}
