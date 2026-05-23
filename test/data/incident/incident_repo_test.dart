import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/incident/local/incident_mock_repository.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/incident_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

IncidentModel _testIncident(String id) => IncidentModel(
      id: id,
      reporterId: 'user-1',
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
    when(() => mockData.incidents).thenReturn([_testIncident('inc-1')]);
    repo = IncidentMockRepository(mockData);
  });

  group('IncidentMockRepository', () {
    test('listAll returns mock incidents', () async {
      final results = await repo.listAll();
      expect(results.length, 1);
      expect(results.first.id, 'inc-1');
    });

    test('create adds ephemeral incident', () async {
      final incident = _testIncident('inc-new');
      final created = await repo.create(incident);
      expect(created.id, 'inc-new');

      final all = await repo.listAll();
      expect(all.length, 2);
    });

    test('forRoute filters by routeId', () async {
      final results = await repo.forRoute('L1');
      expect(results.length, 1);
      expect(results.first.routeId, 'L1');
    });
  });
}
