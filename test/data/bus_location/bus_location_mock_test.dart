import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/bus_location/local/bus_location_mock_repository.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/models.dart';

class MockMockDataService extends Mock implements MockDataService {}

void main() {
  group('BusLocationMockRepository', () {
    test('latestForRoute returns null when no active trips', () async {
      final mockData = MockMockDataService();
      when(() => mockData.activeTrips).thenReturn([]);

      final repo = BusLocationMockRepository(mockData);
      final result = await repo.latestForRoute('L1');

      expect(result, isNull);
    });

    test('latestForRoute returns BusLocation from active trip', () async {
      final mockData = MockMockDataService();
      final trip = ActiveTripModel(
        id: 't1',
        routeId: 'L1',
        currentLat: 36.5,
        currentLng: -6.3,
        currentBearing: 90.0,
        startedAt: DateTime.utc(2026, 5, 1, 12, 0),
        status: TripStatus.onTime,
        capacity: BusCapacity.seatsAvailable,
      );
      when(() => mockData.activeTrips).thenReturn(<ActiveTripModel>[trip]);

      final repo = BusLocationMockRepository(mockData);
      final result = await repo.latestForRoute('L1');

      expect(result, isNotNull);
      expect(result!.lat, 36.5);
      expect(result.lng, -6.3);
      expect(result.bearing, 90.0);
    });

    test('latestForRoute filters out cancelled and completed trips', () async {
      final mockData = MockMockDataService();
      final completed = ActiveTripModel(
        id: 't1',
        routeId: 'L1',
        status: TripStatus.completed,
        currentLat: 36.5,
        currentLng: -6.3,
        startedAt: DateTime.utc(2026, 5, 1, 12, 0),
        capacity: BusCapacity.seatsAvailable,
      );
      when(() => mockData.activeTrips).thenReturn(<ActiveTripModel>[completed]);

      final repo = BusLocationMockRepository(mockData);
      final result = await repo.latestForRoute('L1');

      expect(result, isNull);
    });
  });
}
