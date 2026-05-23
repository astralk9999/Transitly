import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/feature_request/local/feature_request_mock_repository.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/feature_request.dart';

class MockMockDataService extends Mock implements MockDataService {}

FeatureRequest _testFeature(String id) => FeatureRequest(
      id: id,
      title: 'Add night routes',
      description: 'Need routes after 10pm',
      submittedBy: 'user-1',
      category: FeatureRequestCategory.newRoute,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late FeatureRequestMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    repo = FeatureRequestMockRepository(mockData);
  });

  group('FeatureRequestMockRepository', () {
    test('list returns empty initially', () async {
      final results = await repo.list();
      expect(results, isEmpty);
    });

    test('create adds feature request', () async {
      final fr = _testFeature('fr-1');
      final created = await repo.create(fr);
      expect(created.id, 'fr-1');

      final results = await repo.list();
      expect(results.length, 1);
    });

    test('castVote increments votes', () async {
      final fr = _testFeature('fr-vote');
      await repo.create(fr);

      final count = await repo.castVote('fr-vote');
      expect(count, greaterThan(0));
    });
  });
}
