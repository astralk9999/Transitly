import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/bus_location/domain/bus_location_repository.dart';
import 'package:transitly/data/bus_location/local/bus_location_local_repository.dart';
import 'package:transitly/shared/models/bus_location.dart';

void main() {
  group('BusLocation', () {
    test('creates with required fields and optional fields', () {
      final loc = BusLocation(
        lat: 36.527,
        lng: -6.288,
        bearing: 90.5,
        accuracy: 10.0,
        recordedAt: DateTime.utc(2026, 5, 1, 12, 0),
      );
      expect(loc.lat, 36.527);
      expect(loc.lng, -6.288);
      expect(loc.bearing, 90.5);
      expect(loc.accuracy, 10.0);
    });

    test('BusLocationRepositoryError enum has all 5 cases', () {
      expect(BusLocationRepositoryError.values.length, 5);
      expect(BusLocationRepositoryError.values,
          contains(BusLocationRepositoryError.notFound));
      expect(BusLocationRepositoryError.values,
          contains(BusLocationRepositoryError.network));
      expect(BusLocationRepositoryError.values,
          contains(BusLocationRepositoryError.parse));
      expect(BusLocationRepositoryError.values,
          contains(BusLocationRepositoryError.denied));
      expect(BusLocationRepositoryError.values,
          contains(BusLocationRepositoryError.unknown));
    });

    test('BusLocationLocalRepository caches and returns within TTL', () async {
      final repo =
          BusLocationLocalRepository(ttl: const Duration(seconds: 60));
      final loc = BusLocation(
        lat: 36.5,
        lng: -6.3,
        recordedAt: DateTime.utc(2026, 5, 1),
      );
      repo.upsert('L1', loc);
      final cached = await repo.latestForRoute('L1');
      expect(cached, isNotNull);
      expect(cached!.lat, 36.5);
      expect(cached.lng, -6.3);
    });
  });
}
