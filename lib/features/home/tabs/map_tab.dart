import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/route_card.dart';
import '../../map/map_config.dart';
import '../../map/map_data_cache.dart';
import '../../map/map_filter_controller.dart';
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
      _sheetController.animateTo(0.22,
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
    final offline = ref.watch(isOfflineProvider);

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
                onCenter: () {
                  _mapController.move(
                      MapConfig.defaultCenter, MapConfig.defaultZoom);
                },
                onFilter: () => showMapFilterSheet(context, ref),
                onSearch: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(AppLocalizations.of(context).mapSearchComingSoon)),
                  );
                },
              ),
            ],
          ),
          if (offline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(72, 16, 72, 0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: c.bgSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border, width: 0.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off,
                              size: 14, color: c.stateDelay),
                          const SizedBox(width: 6),
                          Text(
                            'Sin conexión · mapa offline',
                            style: TransitTypography.bodySmall(c.textMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          // DraggableScrollableSheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.22,
            minChildSize: 0.12,
            maxChildSize: 0.75,
            snap: true,
            snapSizes: const [0.12, 0.32, 0.75],
            builder: (context, scrollController) {
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(
                    top: BorderSide(color: c.border, width: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Stack(
                    children: [
                      ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: routes.length + 1, // +1 for handle
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHandle(c, routes.length);
                          }
                          final route = routes[index - 1];
                          final trip =
                              mockData.getActiveTripForRoute(route.id);
                          final routeStops =
                              mockData.getStopsForRoute(route.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: RouteCard(
                              route: route,
                              activeTrip: trip,
                              remainingStops: routeStops.length,
                              onTap: () =>
                                  context.push('/route/${route.id}'),
                            ),
                          );
                        },
                      ),
                      // Subtle bottom fade hints that more content scrolls
                      // beyond the visible region of the sheet.
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 18,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  c.bgSurface,
                                  c.bgSurface.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(TransitColorScheme c, int routeCount) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.textLo,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
          child: Row(
            children: [
              Text(
                'LÍNEAS URBANAS',
                style: TransitTypography.sectionTitle(c.textMid),
              ),
              const SizedBox(width: 8),
              Container(
                padding: TransitSpacing.paddingBadge,
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius:
                      BorderRadius.circular(TransitSpacing.radiusXs),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                child: Text(
                  '$routeCount',
                  style: TransitTypography.bodySmall(c.textLo),
                ),
              ),
              const Spacer(),
              if (_selectedRouteId != null)
                Pressable(
                  onTap: _clearSelection,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: c.accent.withValues(alpha: 0.20),
                          width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.clear, size: 14, color: c.accent),
                        const SizedBox(width: 6),
                        Text(
                          'VER TODAS',
                          style: TransitTypography.bodySmall(c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _clearSelection() {
    setState(() => _selectedRouteId = null);
    _sheetController.animateTo(
      0.22,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }
}
