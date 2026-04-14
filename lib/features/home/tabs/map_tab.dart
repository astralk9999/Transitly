import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../map/map_config.dart';
import '../../map/sheets/stop_info_sheet.dart';
import '../../map/sheets/trip_info_sheet.dart';
import '../../map/transit_map.dart';
import '../../map/widgets/map_controls.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
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
    final routeMap = <String, RouteModel>{};
    for (final route in routes) {
      routeMap[route.id] = route;
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
        controller: _mapController,
        routes: routes,
        routePaths: routePaths,
        routeStopsMap: routeStopsMap,
        stops: stops,
        hubStopIds: hubStopIds,
        activeTrips: mockData.activeTrips,
        routeMap: routeMap,
        onStopTap: (stop) => showStopInfoSheet(
          context,
          stop: stop,
          mockData: mockData,
        ),
        onTripTap: (trip) => showTripInfoSheet(
          context,
          trip: trip,
          mockData: mockData,
        ),
        overlayWidgets: [
          MapControls(
            isDark: isDark,
            onZoomIn: () {
              final cam = _mapController.camera;
              _mapController.move(cam.center, cam.zoom + 1);
            },
            onZoomOut: () {
              final cam = _mapController.camera;
              _mapController.move(cam.center, cam.zoom - 1);
            },
            onCenter: () {
              _mapController.move(
                  MapConfig.defaultCenter, MapConfig.defaultZoom);
            },
            onFilter: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filtros: próximamente')),
              );
            },
          ),
        ],
      ),
    );
  }
}
