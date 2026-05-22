import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transitly/data/geo/geo_providers.dart';
import 'package:transitly/data/geo/location_service.dart';

void main() {
  group('geo providers', () {
    test('locationServiceProvider creates a LocationService instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final svc = container.read(locationServiceProvider);
      expect(svc, isA<LocationService>());
    });

    test('currentLocationProvider defaults to null and can be set', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(currentLocationProvider), isNull);

      const pos = LatLng(36.685, -6.13);
      container.read(currentLocationProvider.notifier).state = pos;
      expect(container.read(currentLocationProvider), pos);
    });

    test('activeOperatorProvider default is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final op = container.read(activeOperatorProvider);
      expect(op, isNull);
    });
  });
}
