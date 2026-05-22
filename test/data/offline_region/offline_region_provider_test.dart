import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/data/offline_region/domain/offline_region_repository.dart';
import 'package:transitly/data/offline_region/local/offline_region_mock_repository.dart';
import 'package:transitly/shared/models/offline_region.dart';

OfflineRegion _region(String id) => OfflineRegion(
      id: id,
      label: 'Region $id',
      bounds: const OfflineRegionBounds(
        northLat: 36.75,
        southLat: 36.65,
        eastLng: -6.10,
        westLng: -6.18,
      ),
      zoomMin: 12,
      zoomMax: 17,
      downloadedAt: DateTime(2026, 5, 1),
      sizeBytes: 102400,
      status: OfflineRegionStatus.ready,
    );

void main() {
  group('OfflineRegionMockRepository provider', () {
    test('forUser returns empty list initially', () async {
      final repo = OfflineRegionMockRepository();
      final results = await repo.forUser('user-1');
      expect(results, isEmpty);
    });

    test('add stores and returns region', () async {
      final repo = OfflineRegionMockRepository();
      final region = _region('region-1');
      final result = await repo.add(region);
      expect(result.id, 'region-1');
      final all = await repo.forUser('user-1');
      expect(all.length, 1);
      expect(all.first.label, 'Region region-1');
    });

    test('delete removes region by id', () async {
      final repo = OfflineRegionMockRepository();
      await repo.add(_region('region-1'));
      await repo.add(_region('region-2'));
      await repo.delete('region-1');
      final remaining = await repo.forUser('user-1');
      expect(remaining.length, 1);
      expect(remaining.first.id, 'region-2');
    });
  });
}
