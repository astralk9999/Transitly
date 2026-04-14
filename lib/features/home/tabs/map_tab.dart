import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/route_card.dart';
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
  final _sheetController = DraggableScrollableController();
  final _scrollController = ScrollController();
  String? _selectedRouteId;

  // Precomputed data (set once in build)
  late Map<String, List<LatLng>> _routePaths;
  late Map<String, List<StopModel>> _routeStopsMap;

  @override
  void dispose() {
    _sheetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Find closest polyline to tap point
    final closest = _findClosestRoute(point);
    if (closest != null && closest != _selectedRouteId) {
      setState(() => _selectedRouteId = closest);
      _sheetController.animateTo(0.35,
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      _scrollToRoute(closest);
    } else if (closest == null && _selectedRouteId != null) {
      setState(() => _selectedRouteId = null);
      _sheetController.animateTo(0.12,
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  String? _findClosestRoute(LatLng point) {
    const thresholdDeg = 0.003; // ~300m at Jerez latitude
    String? bestRouteId;
    double bestDist = double.infinity;

    for (final entry in _routePaths.entries) {
      final points = entry.value;
      for (int i = 0; i < points.length - 1; i++) {
        final d = _distToSegment(point, points[i], points[i + 1]);
        if (d < bestDist) {
          bestDist = d;
          bestRouteId = entry.key;
        }
      }
    }

    // Also check fallback stop-based paths
    for (final entry in _routeStopsMap.entries) {
      if (_routePaths.containsKey(entry.key)) continue;
      final stops = entry.value;
      for (int i = 0; i < stops.length - 1; i++) {
        final a = LatLng(stops[i].lat, stops[i].lng);
        final b = LatLng(stops[i + 1].lat, stops[i + 1].lng);
        final d = _distToSegment(point, a, b);
        if (d < bestDist) {
          bestDist = d;
          bestRouteId = entry.key;
        }
      }
    }

    return bestDist < thresholdDeg ? bestRouteId : null;
  }

  double _distToSegment(LatLng p, LatLng a, LatLng b) {
    final dx = b.longitude - a.longitude;
    final dy = b.latitude - a.latitude;
    if (dx == 0 && dy == 0) {
      return _dist(p, a);
    }
    var t = ((p.longitude - a.longitude) * dx + (p.latitude - a.latitude) * dy) /
        (dx * dx + dy * dy);
    t = t.clamp(0.0, 1.0);
    final proj = LatLng(a.latitude + t * dy, a.longitude + t * dx);
    return _dist(p, proj);
  }

  double _dist(LatLng a, LatLng b) {
    final dLat = a.latitude - b.latitude;
    final dLng = (a.longitude - b.longitude) * cos(a.latitude * pi / 180);
    return sqrt(dLat * dLat + dLng * dLng);
  }

  void _scrollToRoute(String routeId) {
    final mockData = ref.read(mockDataServiceProvider);
    final idx = mockData.routes.indexWhere((r) => r.id == routeId);
    if (idx >= 0 && _scrollController.hasClients) {
      _scrollController.animateTo(
        idx * 88.0, // approximate card height + margin
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final c = TransitColorScheme.of(isDark);

    final mockData = ref.watch(mockDataServiceProvider);
    final routes = mockData.routes;
    final stops = mockData.stops;

    // Build data maps
    _routePaths = <String, List<LatLng>>{};
    _routeStopsMap = <String, List<StopModel>>{};
    final routeMap = <String, RouteModel>{};
    for (final route in routes) {
      routeMap[route.id] = route;
      final polyCoords = mockData.polylines[route.id];
      if (polyCoords != null && polyCoords.isNotEmpty) {
        _routePaths[route.id] =
            polyCoords.map((p) => LatLng(p[0], p[1])).toList();
      }
      _routeStopsMap[route.id] = mockData.getStopsForRoute(route.id);
    }

    // Hub stops
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
      body: Stack(
        children: [
          // Map
          TransitMap(
            isDark: isDark,
            controller: _mapController,
            routes: routes,
            routePaths: _routePaths,
            routeStopsMap: _routeStopsMap,
            stops: stops,
            hubStopIds: hubStopIds,
            selectedRouteId: _selectedRouteId,
            activeTrips: mockData.activeTrips,
            routeMap: routeMap,
            onMapTap: _onMapTap,
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
                onSearch: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Búsqueda en mapa: próximamente')),
                  );
                },
              ),
            ],
          ),
          // DraggableScrollableSheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.12,
            minChildSize: 0.08,
            maxChildSize: 0.8,
            snap: true,
            snapSizes: const [0.12, 0.35, 0.8],
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border(
                    top: BorderSide(color: c.border, width: 0.5),
                  ),
                ),
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: routes.length + 1, // +1 for handle
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHandle(c);
                    }
                    final route = routes[index - 1];
                    final trip = mockData.getActiveTripForRoute(route.id);
                    final routeStops =
                        mockData.getStopsForRoute(route.id);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: RouteCard(
                        route: route,
                        activeTrip: trip,
                        remainingStops: routeStops.length,
                        onTap: () => context.push('/route/${route.id}'),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(TransitColorScheme c) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: c.textLo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Text(
                'LÍNEAS URBANAS',
                style: TransitTypography.sectionTitle(c.textMid),
              ),
              const Spacer(),
              if (_selectedRouteId != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedRouteId = null);
                    _sheetController.animateTo(0.12,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut);
                  },
                  child: Text(
                    'VER TODAS',
                    style: TransitTypography.bodySmall(c.accent),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
