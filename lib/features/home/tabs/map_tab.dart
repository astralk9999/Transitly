import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/widgets/route_card.dart';
import '../../map/map_config.dart';
import '../../map/map_data_cache.dart';
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

  @override
  void dispose() {
    _sheetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final cache = ref.read(mapDataCacheProvider);
    final closest = _findClosestRoute(point, cache);
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

  String? _findClosestRoute(LatLng point, MapDataCache cache) {
    const thresholdDeg = 0.003; // ~300m at Jerez latitude
    String? bestRouteId;
    double bestDist = double.infinity;

    for (final entry in cache.routePathsLod.entries) {
      final lodData = entry.value;
      final points = lodData[4] ?? lodData.values.last;
      for (int i = 0; i < points.length - 1; i++) {
        final d = _distToSegment(point, points[i], points[i + 1]);
        if (d < bestDist) {
          bestDist = d;
          bestRouteId = entry.key;
        }
      }
    }

    for (final entry in cache.routeStopsMap.entries) {
      if (cache.routePathsLod.containsKey(entry.key)) continue;
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
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);

    final mockData = ref.watch(mockDataServiceProvider);
    final realtimeTrips = ref.watch(realtimeTripsProvider);
    final liveTrips = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    final routes = mockData.routes;
    final stops = mockData.stops;
    final cache = ref.watch(mapDataCacheProvider);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          // Map
          TransitMap(
            isDark: isDark,
            controller: _mapController,
            routes: routes,
            routePathsLod: cache.routePathsLod,
            routeStopsMap: cache.routeStopsMap,
            routeBounds: cache.routeBounds,
            stops: stops,
            hubStopIds: cache.hubStopIds,
            selectedRouteId: _selectedRouteId,
            activeTrips: liveTrips,
            routeMap: cache.routeMap,
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
