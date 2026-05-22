import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/bus_location.dart';

void main() {
  group('BusLocation', () {
    test('lat and lng are correctly stored', () {
      const lat = 37.3891;
      const lng = -5.9845;

      final location = BusLocation(
        lat: lat,
        lng: lng,
        recordedAt: DateTime.now(),
      );

      expect(location.lat, lat);
      expect(location.lng, lng);
    });

    test('bearing is optional and nullable', () {
      final withBearing = BusLocation(
        lat: 37.0,
        lng: -6.0,
        bearing: 180.0,
        recordedAt: DateTime.now(),
      );
      expect(withBearing.bearing, 180.0);

      final withoutBearing = BusLocation(
        lat: 37.0,
        lng: -6.0,
        recordedAt: DateTime.now(),
      );
      expect(withoutBearing.bearing, isNull);
    });

    test('recordedAt preserves the provided timestamp', () {
      final now = DateTime(2026, 5, 22, 14, 30, 0);

      final location = BusLocation(
        lat: 37.0,
        lng: -6.0,
        recordedAt: now,
      );

      expect(location.recordedAt, now);
      expect(location.recordedAt.year, 2026);
      expect(location.recordedAt.hour, 14);
    });
  });
}
