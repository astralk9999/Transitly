import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/alert_model.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('AlertModel', () {
    test('fromJson creates valid alert with warning severity', () {
      final json = {
        'id': 'a1',
        'type': 'warning',
        'title': 'Desvío L1',
        'description': 'La línea L1 estará desviada por obras.',
        'lineCode': 'L1',
        'startDate': '2026-05-20T08:00:00.000',
        'endDate': '2026-05-25T20:00:00.000',
      };
      final a = AlertModel.fromJson(json);
      expect(a.id, 'a1');
      expect(a.severity, AlertSeverity.warning);
      expect(a.title, 'Desvío L1');
      expect(a.body, 'La línea L1 estará desviada por obras.');
      expect(a.routeId, 'L1');
      expect(a.activeFrom, DateTime.parse('2026-05-20T08:00:00.000'));
      expect(a.activeUntil, DateTime.parse('2026-05-25T20:00:00.000'));
      expect(a.operatorId, 'comujesa');
    });

    test('fromJson defaults missing fields', () {
      final json = {
        'id': 'a2',
        'type': 'info',
        'title': 'Aviso general',
        'description': 'Sin novedades.',
      };
      final a = AlertModel.fromJson(json);
      expect(a.severity, AlertSeverity.info);
      expect(a.routeId, isNull);
      expect(a.activeFrom, isNull);
      expect(a.activeUntil, isNull);
    });

    test('toJson roundtrips correctly', () {
      final now = DateTime.parse('2026-05-20T08:00:00.000');
      final later = DateTime.parse('2026-05-25T20:00:00.000');
      final a = AlertModel(
        id: 'a1',
        operatorId: 'comujesa',
        severity: AlertSeverity.critical,
        title: 'Corte total',
        body: 'Servicio suspendido.',
        routeId: 'L2',
        activeFrom: now,
        activeUntil: later,
      );
      final j = a.toJson();
      expect(j['id'], 'a1');
      expect(j['type'], 'critical');
      expect(j['title'], 'Corte total');
      expect(j['description'], 'Servicio suspendido.');
      expect(j['lineCode'], 'L2');
      expect(j['startDate'], now.toIso8601String());
      expect(j['endDate'], later.toIso8601String());
    });
  });
}
