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
    test('listAll devuelve todos los incidents', () async {
      final results = await repo.listAll();

      expect(results.length, 1);
      expect(results.first.id, 'inc-1');
    });

    test('updateStatus cambia el status de un incident existente', () async {
      final updated = await repo.updateStatus('inc-1', 'resolved');

      expect(updated.id, 'inc-1');
      expect(updated.status, 'resolved');

      final all = await repo.listAll();
      expect(all.first.status, 'resolved');
    });

    test('updateStatus lanza excepción si el id no existe', () async {
      expect(
        () => repo.updateStatus('nonexistent', 'resolved'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
