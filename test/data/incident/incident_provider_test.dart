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
    repo = IncidentMockRepository(mockData);
  });

  group('IncidentMockRepository provider', () {
    test('listAll returns empty when mock has no incidents', () async {
      when(() => mockData.incidents).thenReturn([]);
      final results = await repo.listAll();
      expect(results, isEmpty);
    });

    test('byAuthor filters by reporterId', () async {
      when(() => mockData.incidents).thenReturn([
        _testIncident('inc-1'),
        _testIncident('inc-2').copyWith(reporterId: 'user-2'),
      ]);
      final results = await repo.byAuthor('user-1');
      expect(results.length, 1);
      expect(results.first.id, 'inc-1');
    });

    test('create adds incident and returns it', () async {
      when(() => mockData.incidents).thenReturn([]);
      final incident = _testIncident('new-inc');
      final result = await repo.create(incident);
      expect(result.id, 'new-inc');
      expect(result.status, 'open');
      final all = await repo.listAll();
      expect(all.length, 1);
    });
  });
}
