import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/mock/mock_data_service.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';

/// Precomputed, immutable map data derived once from [MockDataService].
///
/// Used to be built inline inside [build()] of `MapTab`; that made cached
/// values stale under hot reload or test-time provider overrides. Exposing
/// it as a Riverpod-derived value gives us correct invalidation.
class MapDataCache {
  const MapDataCache({
    required this.routePathsLod,
    required this.routeStopsMap,
    required this.routeMap,
    required this.routeBounds,
    required this.hubStopIds,
  });

  final Map<String, Map<int, List<LatLng>>> routePathsLod;
  final Map<String, List<StopModel>> routeStopsMap;
  final Map<String, RouteModel> routeMap;
  final Map<String, List<double>> routeBounds;
  final Set<String> hubStopIds;
}

/// Provider that builds [MapDataCache] from [mockDataServiceProvider].
///
/// Riverpod caches the result and re-runs only when mockData changes.
final mapDataCacheProvider = Provider<MapDataCache>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);

  final routePathsLod = <String, Map<int, List<LatLng>>>{};
  final routeStopsMap = <String, List<StopModel>>{};
  final routeMap = <String, RouteModel>{};

  for (final route in mockData.routes) {
    routeMap[route.id] = route;

    final lodData = mockData.polylinesLod[route.id];
    if (lodData != null) {
      final lodLatLng = <int, List<LatLng>>{};
      for (final entry in lodData.entries) {
        lodLatLng[entry.key] =
            entry.value.map((p) => LatLng(p[0], p[1])).toList();
      }
      routePathsLod[route.id] = lodLatLng;
    }
    routeStopsMap[route.id] = mockData.getStopsForRoute(route.id);
  }

  final stopRouteCounts = <String, int>{};
  for (final rs in mockData.routeStops.values) {
    for (final r in rs) {
      stopRouteCounts[r.stopId] = (stopRouteCounts[r.stopId] ?? 0) + 1;
    }
  }
  final hubStopIds = stopRouteCounts.entries
      .where((e) => e.value > 1)
      .map((e) => e.key)
      .toSet();

  return MapDataCache(
    routePathsLod: routePathsLod,
    routeStopsMap: routeStopsMap,
    routeMap: routeMap,
    routeBounds: mockData.routeBounds,
    hubStopIds: hubStopIds,
  );
});
