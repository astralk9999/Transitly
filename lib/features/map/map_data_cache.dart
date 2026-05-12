import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/cache/hive_box_provider.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';

/// Precomputed, immutable map data derived from repository caches
/// (when authenticated) or [MockDataService] (guest mode).
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

/// Provider that builds [MapDataCache] from the repository Hive caches
/// when a Supabase session exists, falling back to [MockDataService] in
/// guest mode.
///
/// Geo data (polylines, routeStops, routeBounds) always comes from
/// [MockDataService] since it's static bundled data not replicated to
/// Hive. F7 (importador GTFS) will populate Supabase with equivalent
/// geo data.
final mapDataCacheProvider = Provider<MapDataCache>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return _buildFromMockData(ref);
  }

  return _buildFromRepos(ref);
});

MapDataCache _buildFromMockData(Ref ref) {
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
  for (final rsList in mockData.routeStops.values) {
    for (final rs in rsList) {
      stopRouteCounts[rs.stopId] = (stopRouteCounts[rs.stopId] ?? 0) + 1;
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
}

MapDataCache _buildFromRepos(Ref ref) {
  final routesBox = ref.watch(routesBoxProvider);
  final stopsBox = ref.watch(stopsBoxProvider);
  final mockData = ref.watch(mockDataServiceProvider);

  final routePathsLod = <String, Map<int, List<LatLng>>>{};
  final routeStopsMap = <String, List<StopModel>>{};
  final routeMap = <String, RouteModel>{};

  for (final route in routesBox.values) {
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

    final stopIds = mockData
        .getStopsForRoute(route.id)
        .map((s) => s.id);
    routeStopsMap[route.id] = stopIds
        .map((id) => stopsBox.get('stop:$id'))
        .whereType<StopModel>()
        .toList();
  }

  final stopRouteCounts = <String, int>{};
  for (final rsList in mockData.routeStops.values) {
    for (final rs in rsList) {
      stopRouteCounts[rs.stopId] = (stopRouteCounts[rs.stopId] ?? 0) + 1;
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
}
