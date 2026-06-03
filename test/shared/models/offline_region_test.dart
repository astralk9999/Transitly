import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/offline_region.dart';

void main() {
  group('OfflineRegionBounds', () {
    test('fromJson parses bounding box coordinates', () {
      final json = <String, dynamic>{
        'northLat': 36.5,
        'southLat': 36.0,
        'eastLng': -5.0,
        'westLng': -5.5,
      };

      final bounds = OfflineRegionBounds.fromJson(json);

      expect(bounds.northLat, 36.5);
      expect(bounds.southLat, 36.0);
      expect(bounds.eastLng, -5.0);
      expect(bounds.westLng, -5.5);
    });

    test('toJson roundtrips correctly', () {
      final original = const OfflineRegionBounds(
        northLat: 40.4168,
        southLat: 40.3126,
        eastLng: -3.5853,
        westLng: -3.8318,
      );

      final json = original.toJson();
      final restored = OfflineRegionBounds.fromJson(json);

      expect(restored.northLat, original.northLat);
      expect(restored.southLat, original.southLat);
      expect(restored.eastLng, original.eastLng);
      expect(restored.westLng, original.westLng);
    });
  });

  group('OfflineRegion', () {
    test('fromJson parses all fields correctly', () {
      final json = <String, dynamic>{
        'id': 'region-1',
        'label': 'Jerez Centro',
        'bounds': {
          'northLat': 36.7,
          'southLat': 36.6,
          'eastLng': -6.1,
          'westLng': -6.2,
        },
        'zoomMin': 10,
        'zoomMax': 18,
        'downloadedAt': '2026-05-20T12:00:00.000Z',
        'sizeBytes': 52428800,
        'status': 'ready',
        'dataSyncedAt': '2026-05-22T08:00:00.000Z',
      };

      final region = OfflineRegion.fromJson(json);

      expect(region.id, 'region-1');
      expect(region.label, 'Jerez Centro');
      expect(region.bounds.northLat, 36.7);
      expect(region.zoomMin, 10);
      expect(region.zoomMax, 18);
      expect(region.downloadedAt, DateTime.parse('2026-05-20T12:00:00.000Z'));
      expect(region.sizeBytes, 52428800);
      expect(region.status, OfflineRegionStatus.ready);
      expect(region.dataSyncedAt, DateTime.parse('2026-05-22T08:00:00.000Z'));
    });

    test('toJson roundtrips correctly', () {
      final downloadedAt = DateTime.parse('2026-05-21T10:00:00.000Z');
      final syncedAt = DateTime.parse('2026-05-23T10:00:00.000Z');
      final original = OfflineRegion(
        id: 'region-2',
        label: 'Madrid Centro',
        bounds: const OfflineRegionBounds(
          northLat: 40.5,
          southLat: 40.3,
          eastLng: -3.6,
          westLng: -3.8,
        ),
        zoomMin: 12,
        zoomMax: 20,
        downloadedAt: downloadedAt,
        sizeBytes: 104857600,
        status: OfflineRegionStatus.downloading,
        dataSyncedAt: syncedAt,
      );

      final json = original.toJson();
      final restored = OfflineRegion.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.label, original.label);
      expect(restored.bounds.northLat, original.bounds.northLat);
      expect(restored.bounds.southLat, original.bounds.southLat);
      expect(restored.bounds.eastLng, original.bounds.eastLng);
      expect(restored.bounds.westLng, original.bounds.westLng);
      expect(restored.zoomMin, original.zoomMin);
      expect(restored.zoomMax, original.zoomMax);
      expect(restored.downloadedAt, original.downloadedAt);
      expect(restored.sizeBytes, original.sizeBytes);
      expect(restored.status, original.status);
      expect(restored.dataSyncedAt, original.dataSyncedAt);
    });

    test('dataSyncedAt is null when not provided', () {
      final json = <String, dynamic>{
        'id': 'region-3',
        'label': 'Sevilla Este',
        'bounds': {
          'northLat': 37.4,
          'southLat': 37.3,
          'eastLng': -5.9,
          'westLng': -6.0,
        },
        'zoomMin': 11,
        'zoomMax': 17,
        'downloadedAt': '2026-05-19T00:00:00.000Z',
        'sizeBytes': 26214400,
        'status': 'stale',
      };

      final region = OfflineRegion.fromJson(json);

      expect(region.dataSyncedAt, isNull);
    });
  });
}
