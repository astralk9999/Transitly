import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/incident/local/incident_mock_repository.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/incident_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

IncidentModel _inc(String id) => IncidentModel(
      id: id,
      reporterId: 'u-1',
      routeId: 'L1',
      incidentType: IncidentType.delay,
      category: IncidentCategory.service,
      status: 'open',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  late MockMockDataService mockData;
  late IncidentMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.incidents).thenReturn([_inc('inc-1')]);
    repo = IncidentMockRepository(mockData);
  });

  group('IncidentMockRepository edge', () {
    test('updateStatus for nonexistent id throws', () {
      expect(
        () => repo.updateStatus('ghost', 'resolved'),
        throwsA(isA<StateError>()),
      );
    });

    test('byAuthor returns empty for unknown author', () async {
      final results = await repo.byAuthor('ghost-author');
      expect(results, isEmpty);
    });

    test('updateStatus then listAll reflects change', () async {
      await repo.updateStatus('inc-1', 'resolved');
      final all = await repo.listAll();
      final updated = all.firstWhere((i) => i.id == 'inc-1');
      expect(updated.status, 'resolved');
    });
  });
}
