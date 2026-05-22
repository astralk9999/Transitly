import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/route_feedback/local/route_feedback_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_feedback_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

RouteFeedbackModel _feedback(String id) => RouteFeedbackModel(
      id: id,
      userId: 'user-1',
      routeId: 'L1',
      feedbackType: FeedbackType.scheduleOutdated,
      description: 'Test',
      status: FeedbackStatus.submitted,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late RouteFeedbackMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.feedbacks).thenReturn([
      _feedback('fb-1'),
      _feedback('fb-2').copyWith(userId: 'user-2', routeId: 'L2'),
    ]);
    repo = RouteFeedbackMockRepository(mockData);
  });

  group('RouteFeedbackMockRepository provider', () {
    test('forRoute filtra por routeId', () async {
      final results = await repo.forRoute('L1');
      expect(results.length, 1);
      expect(results.first.id, 'fb-1');
    });

    test('create agrega y devuelve el feedback', () async {
      final fb = _feedback('new-fb');
      final result = await repo.create(fb);
      expect(result.id, 'new-fb');
      final all = await repo.listAll();
      expect(all.length, 3);
    });

    test('updateStatus with invalid id throws StateError', () async {
      expect(
        () => repo.updateStatus('nonexistent', 'applied'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
