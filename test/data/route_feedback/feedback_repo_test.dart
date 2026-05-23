import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/route_feedback/local/route_feedback_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_feedback_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

RouteFeedbackModel _testFeedback(String id) => RouteFeedbackModel(
      id: id,
      userId: 'user-1',
      routeId: 'L1',
      feedbackType: FeedbackType.scheduleOutdated,
      description: 'Test feedback',
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late RouteFeedbackMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.feedbacks).thenReturn([_testFeedback('fb-1')]);
    repo = RouteFeedbackMockRepository(mockData);
  });

  group('RouteFeedbackMockRepository', () {
    test('listAll returns mock feedbacks', () async {
      final results = await repo.listAll();
      expect(results.length, 1);
      expect(results.first.id, 'fb-1');
    });

    test('create adds ephemeral feedback', () async {
      final fb = _testFeedback('fb-new');
      final created = await repo.create(fb);
      expect(created.id, 'fb-new');

      final all = await repo.listAll();
      expect(all.length, 2);
    });

    test('byAuthor filters by userId', () async {
      final results = await repo.byAuthor('user-1');
      expect(results.length, 1);
      expect(results.first.userId, 'user-1');
    });
  });
}
