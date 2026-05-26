import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/incident/domain/incident_repository.dart';
import 'package:transitly/shared/models/incident_model.dart';

void main() {
  group('IncidentModel status transitions', () {
    final baseJson = <String, dynamic>{
      'id': 'inc1',
      'reportedBy': 'user1',
      'lineCode': 'L1',
      'type': 'delay',
      'status': 'pending',
      'reportedAt': DateTime(2026, 5, 23).toIso8601String(),
    };

    test('pending is default status from json', () {
      final inc = IncidentModel.fromJson(baseJson);
      expect(inc.status, 'pending');
    });

    test('status can be ongoing', () {
      final json = {...baseJson, 'status': 'ongoing'};
      final inc = IncidentModel.fromJson(json);
      expect(inc.status, 'ongoing');
    });

    test('status can be resolved', () {
      final json = {...baseJson, 'status': 'resolved'};
      final inc = IncidentModel.fromJson(json);
      expect(inc.status, 'resolved');
    });

    test('status can be dismissed', () {
      final json = {...baseJson, 'status': 'dismissed'};
      final inc = IncidentModel.fromJson(json);
      expect(inc.status, 'dismissed');
    });

    test('IncidentRepositoryException creates correctly', () {
      final ex = IncidentRepositoryException(
        error: IncidentRepositoryError.network,
        message: 'Connection failed',
      );
      expect(ex.error, IncidentRepositoryError.network);
      expect(ex.message, 'Connection failed');
      expect(ex.cause, isNull);
      expect(ex.stackTrace, isNull);
    });

    test('IncidentRepositoryException with cause includes cause in toString', () {
      final cause = Exception('Timeout');
      final ex = IncidentRepositoryException(
        error: IncidentRepositoryError.unknown,
        message: 'Something broke',
        cause: cause,
      );
      expect(ex.toString(), contains('Timeout'));
    });
  });
}
