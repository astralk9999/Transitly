import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/schedule/local/schedule_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/schedule_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

ScheduleModel _schedule(String id, String routeId, String time) =>
    ScheduleModel(
      id: id,
      routeId: routeId,
      departureTime: time,
      dayType: DayType.weekday,
    );

void main() {
  late MockMockDataService mockData;
  late ScheduleMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    repo = ScheduleMockRepository(mockData);
  });

  group('ScheduleMockRepository provider', () {
    test('forRoute returns sorted by departure time', () async {
      when(() => mockData.getSchedulesForRoute('L1',
              dayType: any(named: 'dayType'))).thenReturn([
        _schedule('s-3', 'L1', '14:30'),
        _schedule('s-1', 'L1', '08:00'),
        _schedule('s-2', 'L1', '10:15'),
      ]);
      final results = await repo.forRoute('L1');
      expect(results.length, 3);
      expect(results[0].departureTime, '08:00');
      expect(results[1].departureTime, '10:15');
      expect(results[2].departureTime, '14:30');
    });

    test('forRoute returns empty list for unknown route', () async {
      when(() => mockData.getSchedulesForRoute('unknown',
              dayType: any(named: 'dayType'))).thenReturn([]);
      final results = await repo.forRoute('unknown');
      expect(results, isEmpty);
    });

    test('nextDepartures delegates to mock service', () async {
      when(() => mockData.getNextDepartures('L1', '', 3)).thenReturn([
        _schedule('s-1', 'L1', '09:00'),
        _schedule('s-2', 'L1', '12:00'),
      ]);
      final results = await repo.nextDepartures('L1', 3);
      expect(results.length, 2);
      expect(results.first.departureTime, '09:00');
    });
  });
}
