import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/route_feedback_model.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('RouteFeedbackModel', () {
    test('fromJson creates valid feedback', () {
      final json = {
        'id': '1',
        'reportedBy': 'user1',
        'lineCode': 'L1',
        'type': 'scheduleError',
        'description': 'Wrong time',
        'status': 'submitted',
        'reportedAt': '2026-05-22T00:00:00Z',
      };
      final fb = RouteFeedbackModel.fromJson(json);
      expect(fb.description, 'Wrong time');
      expect(fb.feedbackType, FeedbackType.scheduleOutdated);
    });

    test('copyWith preserves id and updates status', () {
      final fb = RouteFeedbackModel(
        id: '1',
        userId: 'u1',
        routeId: 'L1',
        feedbackType: FeedbackType.scheduleOutdated,
        description: 'test',
        status: FeedbackStatus.submitted,
        createdAt: DateTime.now(),
      );
      final updated = fb.copyWith(status: FeedbackStatus.applied);
      expect(updated.id, '1');
      expect(updated.status, FeedbackStatus.applied);
    });

    test('FeedbackStatus enum has more than 3 values', () {
      expect(FeedbackStatus.values.length, greaterThan(3));
    });
  });
}
