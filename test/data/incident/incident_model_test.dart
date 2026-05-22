import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/incident_model.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('IncidentModel', () {
    test('fromJson creates valid incident', () {
      final json = {
        'id': '1',
        'reportedBy': 'user1',
        'lineCode': 'L1',
        'stopName': 'JER-001',
        'type': 'delay',
        'status': 'open',
        'reportedAt': '2026-05-22T00:00:00Z',
      };
      final incident = IncidentModel.fromJson(json);
      expect(incident.id, '1');
      expect(incident.routeId, 'L1');
      expect(incident.stopId, 'JER-001');
      expect(incident.incidentType, IncidentType.delay);
    });

    test('copyWith updates status', () {
      final incident = IncidentModel(
        id: '1',
        reporterId: 'user1',
        routeId: 'L1',
        stopId: 'JER-001',
        incidentType: IncidentType.delay,
        category: IncidentCategory.service,
        status: 'open',
        createdAt: DateTime.now(),
      );
      final updated = incident.copyWith(status: 'resolved');
      expect(updated.status, 'resolved');
      expect(updated.id, '1');
    });

    test('toJson roundtrips', () {
      final incident = IncidentModel(
        id: '1',
        reporterId: 'user1',
        routeId: 'L1',
        stopId: 'JER-001',
        incidentType: IncidentType.delay,
        category: IncidentCategory.service,
        status: 'open',
        createdAt: DateTime(2026, 5, 22),
      );
      final json = incident.toJson();
      expect(json['id'], '1');
      expect(json['lineCode'], 'L1');
    });

    test('IncidentType enum has expected values', () {
      expect(IncidentType.values.length, greaterThan(4));
    });
  });
}
