import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/route_suggestion/local/route_suggestion_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_suggestion_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

RouteSuggestionModel _testSuggestion(String id) => RouteSuggestionModel(
      id: id,
      suggestedBy: 'user-1',
      originText: 'Centro',
      destinationText: 'Norte',
      status: SuggestionStatus.idea,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late RouteSuggestionMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.routeSuggestions)
        .thenReturn([_testSuggestion('sg-1')]);
    repo = RouteSuggestionMockRepository(mockData);
  });

  group('RouteSuggestionMockRepository', () {
    test('list returns mock suggestions', () async {
      final results = await repo.list();
      expect(results.length, 1);
      expect(results.first.id, 'sg-1');
    });

    test('create adds suggestion', () async {
      final sg = _testSuggestion('sg-new');
      final created = await repo.create(sg);
      expect(created.id, 'sg-new');

      final results = await repo.list();
      expect(results.length, 2);
    });

    test('castVote increments vote count', () async {
      final count = await repo.castVote('sg-1');
      expect(count, greaterThan(0));
    });
  });
}
