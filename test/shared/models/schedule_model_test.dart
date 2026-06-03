import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/schedule_model.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  group('ScheduleModel', () {
    test('fromJson creates valid schedule with weekday dayType', () {
      final json = {
        'id': 's1',
        'routeId': 'L1',
        'departureTime': '08:00',
        'dayType': 'weekday',
        'direction': 'outbound',
      };
      final s = ScheduleModel.fromJson(json);
      expect(s.id, 's1');
      expect(s.routeId, 'L1');
      expect(s.departureTime, '08:00');
      expect(s.dayType, DayType.weekday);
      expect(s.direction, RouteDirection.outbound);
      expect(s.daysOfWeek, isEmpty);
    });

    test('fromJson parses daysOfWeek and defaults direction', () {
      final json = {
        'id': 's2',
        'routeId': 'L2',
        'departureTime': '14:30',
        'dayType': 'saturday',
        'daysOfWeek': [1, 3, 5],
      };
      final s = ScheduleModel.fromJson(json);
      expect(s.daysOfWeek, [1, 3, 5]);
      expect(s.dayType, DayType.saturday);
      expect(s.direction, RouteDirection.outbound);
    });

    test('toJson roundtrips correctly', () {
      final s = const ScheduleModel(
        id: 's1',
        routeId: 'L1',
        departureTime: '08:00',
        dayType: DayType.weekday,
        direction: RouteDirection.outbound,
      );
      final j = s.toJson();
      expect(j['id'], 's1');
      expect(j['routeId'], 'L1');
      expect(j['departureTime'], '08:00');
      expect(j['dayType'], 'weekday');
      expect(j['direction'], 'outbound');
    });
  });
}
