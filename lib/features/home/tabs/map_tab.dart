import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../map/transit_map.dart';

class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final mockData = ref.watch(mockDataServiceProvider);
    final routes = mockData.routes;
    final stops = mockData.stops;

    // Build routePaths from polylines or fallback to stop coords
    final routePaths = <String, List<LatLng>>{};
    final routeStopsMap = <String, List<StopModel>>{};
    for (final route in routes) {
      final polyCoords = mockData.polylines[route.id];
      if (polyCoords != null && polyCoords.isNotEmpty) {
        routePaths[route.id] =
            polyCoords.map((c) => LatLng(c[0], c[1])).toList();
      }
      routeStopsMap[route.id] = mockData.getStopsForRoute(route.id);
    }

    // Hub stops: appear in more than one route
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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: TransitMap(
        isDark: isDark,
        routes: routes,
        routePaths: routePaths,
        routeStopsMap: routeStopsMap,
        stops: stops,
        hubStopIds: hubStopIds,
      ),
    );
  }
}
