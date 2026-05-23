import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/route_feedback/local/route_feedback_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_feedback_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

RouteFeedbackModel _fb(String id) => RouteFeedbackModel(
      id: id,
      userId: 'u-1',
      routeId: 'L1',
      feedbackType: FeedbackType.scheduleOutdated,
      description: 'desc',
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late RouteFeedbackMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.feedbacks).thenReturn([_fb('fb-1')]);
    repo = RouteFeedbackMockRepository(mockData);
  });

  group('RouteFeedbackMockRepository edge', () {
    test('updateStatus for nonexistent id throws', () {
      expect(
        () => repo.updateStatus('ghost', 'accepted'),
        throwsA(isA<StateError>()),
      );
    });

    test('byAuthor returns empty for unknown author', () async {
      final results = await repo.byAuthor('ghost-author');
      expect(results, isEmpty);
    });

    test('multiple ephemeral creates are all visible', () async {
      await repo.create(_fb('fb-a'));
      await repo.create(_fb('fb-b'));
      await repo.create(_fb('fb-c'));
      final all = await repo.listAll();
      expect(all.length, 4); // 1 mock + 3 ephemeral
      expect(all.map((f) => f.id), containsAll(['fb-1', 'fb-a', 'fb-b', 'fb-c']));
    });
  });
}
