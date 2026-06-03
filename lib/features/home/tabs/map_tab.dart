import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/fmtc/fmtc_provider.dart';
import '../../../shared/providers/theme_notifier.dart';
import '../../../data/geo/location_service.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_model.dart';
import '../../../shared/models/route_stop_model.dart';
import '../../../shared/providers/center_on_stop_provider.dart';
import '../../../shared/providers/connectivity_provider.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/providers/user_favorites_provider.dart';
import '../../../shared/providers/user_location_provider.dart';
import '../../../shared/widgets/pressable.dart';
import '../../../shared/widgets/route_card.dart';
import '../../map/map_config.dart';
import '../../map/map_data_cache.dart';
import '../../map/map_filter_controller.dart';
import '../../map/widgets/map_filter_sheet.dart';
import '../../map/sheets/stop_info_sheet.dart';
import '../../map/sheets/trip_info_sheet.dart';
import '../../map/transit_map.dart';
import '../../map/widgets/map_search_sheet.dart';
import '../../map/layers/user_location_layer.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  MapController _mapController = MapController();
  final _sheetController = DraggableScrollableController();
  final _scrollController = ScrollController();
  String? _selectedRouteId;
  ServiceType? _serviceTypeFilter;
  bool _didInitialCenter = false;
  bool _loadingCenter = false;
  String? _lastMapKey;
  DateTime? _bypassFmtcUntil;

  List<RouteModel> _filteredRoutes(List<RouteModel> all) {
    var filtered = all;

    if (_serviceTypeFilter != null) {
      filtered =
          filtered.where((r) => r.serviceType == _serviceTypeFilter).toList();
    }

    final f = ref.watch(mapFilterControllerProvider);

    if (!f.showOfficial && !f.showCommunity) {
      // defensivo: si ambos off, no filtrar por status
    } else {
      if (!f.showOfficial) {
        filtered = filtered
            .where((r) => r.status != RouteStatus.official)
            .toList();
      }
      if (!f.showCommunity) {
        filtered = filtered
            .where((r) => r.status == RouteStatus.official)
            .toList();
      }
    }

    if (f.onlyAccessible) {
      final mockData = ref.read(mockDataServiceProvider);
      filtered = filtered.where((r) {
        final stops = mockData.getStopsForRoute(r.id);
        return stops.any((s) => s.isAccessible);
      }).toList();
    }

    if (f.onlyFavorites) {
      final favs = ref.read(userFavoritesProvider);
      filtered = filtered.where((r) => favs.contains(r.id)).toList();
    }

    if (f.disabledOperators.isNotEmpty) {
      filtered = filtered
          .where((r) => !f.disabledOperators.contains(r.operatorId))
          .toList();
    }
    if (f.disabledKinds.isNotEmpty) {
      filtered = filtered
          .where((r) => !f.disabledKinds.contains(r.serviceType.name))
          .toList();
    }
    if (f.disabledZones.isNotEmpty) {
      final mockData = ref.read(mockDataServiceProvider);
      filtered = filtered.where((r) {
        final op = mockData.getOperatorById(r.operatorId);
        final zone = op?.name ?? op?.region ?? r.operatorId;
        return !f.disabledZones.contains(zone);
      }).toList();
    }
    if (f.disabledLines.isNotEmpty) {
      filtered = filtered
          .where((r) => !f.disabledLines.contains(r.id))
          .toList();
    }

    if (f.nextMinutes > 0) {
      final mockData = ref.read(mockDataServiceProvider);
      final now = DateTime.now();
      final nowMins = now.hour * 60 + now.minute;
      filtered = filtered.where((r) {
        final rs = mockData.routeStops[r.id];
        if (rs == null || rs.isEmpty) return false;
        final ordered = List<RouteStopModel>.from(rs)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
        final firstStopId = ordered.first.stopId;
        final deps = mockData.getNextDepartures(r.id, firstStopId, 1);
        if (deps.isEmpty) return false;
        final parts = deps.first.departureTime.split(':');
        final depMins = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        return depMins >= nowMins && (depMins - nowMins) <= f.nextMinutes;
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _mapController.dispose();
    _sheetController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    final cache = ref.read(mapDataCacheProvider);
    final mockData = ref.read(mockDataServiceProvider);
    // Solo permitir seleccionar rutas que estén visibles segun filtros.
    // Sin este filtro, el tap encuentra polylines desactivadas (no
    // dibujadas) y mostraria sus paradas/direcciones aunque la linea
    // este desactivada en el filtro.
    final visibleIds =
        _filteredRoutes(mockData.routes).map((r) => r.id).toSet();
    final closest = _findClosestRoute(point, cache, visibleIds);
    if (closest != null && closest != _selectedRouteId) {
      setState(() => _selectedRouteId = closest);
      _sheetController.animateTo(0.35,
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
      _scrollToRoute(closest);
      final route = mockData.getRouteById(closest);
      if (route != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Línea ${route.code} · ${route.name}'),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.fromLTRB(16, 0, 16, 100 + MediaQuery.of(context).padding.bottom),
          duration: const Duration(seconds: 2),
        ));
      }
    } else if (closest == null && _selectedRouteId != null) {
      setState(() => _selectedRouteId = null);
      _sheetController.animateTo(0.22,
          duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
    }
  }

  String? _findClosestRoute(
      LatLng point, MapDataCache cache, Set<String> visibleIds) {
    final z = _mapController.camera.zoom.clamp(12.0, 18.0);
    final thresholdDeg = (0.05 / (z * z)).clamp(0.0003, 0.005);
    String? bestRouteId;
    double bestDist = double.infinity;

    for (final entry in cache.routePathsLod.entries) {
      if (!visibleIds.contains(entry.key)) continue;
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
      if (!visibleIds.contains(entry.key)) continue;
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
        idx * 88.0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _requestLocationPermission().then((_) => _tryInitialCenter());
  }

  Future<void> _tryInitialCenter() async {
    if (_didInitialCenter) return;
    try {
      final fix = await ref
          .read(userLocationStreamProvider.future)
          .timeout(const Duration(seconds: 4));
      if (fix != null && mounted) {
        final dist = const Distance().as(
          LengthUnit.Meter,
          fix.position,
          MapConfig.defaultCenter,
        );
        if (dist <= 50000) {
          _mapController.move(fix.position, 14);
        } else {
          _mapController.move(
              MapConfig.defaultCenter, MapConfig.defaultZoom);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Estás a ${(dist / 1000).round()} km de Jerez. '
                  'El mapa muestra las líneas de COMUJESA en Jerez.'),
              duration: const Duration(seconds: 4),
            ));
          }
        }
        _didInitialCenter = true;
      }
    } on TimeoutException {
      return;
    } catch (_) {
      return;
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      await ref.read(userLocationPermissionProvider.future);
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(l10n.mapLocationPermissionDenied),
            action: SnackBarAction(
              label: l10n.actionOpenSettings,
              onPressed: Geolocator.openLocationSettings,
            ),
            duration: const Duration(seconds: 5),
          ),
        );
    }
  }

  Future<void> _centerOnUser() async {
    final locFix = ref.read(userLocationStreamProvider).valueOrNull;
    if (locFix != null) {
      _mapController.move(locFix.position, 16);
      return;
    }

    setState(() => _loadingCenter = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final granted = await Geolocator.requestPermission();
        if (granted != LocationPermission.whileInUse &&
            granted != LocationPermission.always) {
          return;
        }
        ref.invalidate(userLocationPermissionProvider);

        // Prewarm: forzar geolocator a verificar permiso
        final service = ref.read(userLocationServiceProvider);
        final firstPos = await service.prewarm();
        if (firstPos != null && mounted) {
          _mapController.move(LocationService.toLatLng(firstPos), 16);
          if (mounted) setState(() => _loadingCenter = false);
          return;
        }

        ref.invalidate(userLocationStreamProvider);
        try {
          final fix = await ref
              .read(userLocationStreamProvider.future)
              .timeout(const Duration(seconds: 6));
          if (fix != null && mounted) {
            _mapController.move(fix.position, 16);
            if (mounted) setState(() => _loadingCenter = false);
            return;
          }
        } on TimeoutException {
          // fall through to getCurrentPosition
        }
      } else if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(l10n.mapLocationPermissionDenied),
                action: SnackBarAction(
                  label: l10n.actionOpenSettings,
                  onPressed: Geolocator.openLocationSettings,
                ),
                duration: const Duration(seconds: 5),
              ),
            );
        }
        return;
      }

      final service = ref.read(userLocationServiceProvider);
      final pos = await service.getCurrent(
        timeout: const Duration(seconds: 10),
      );
      if (pos != null && mounted) {
        _mapController.move(LocationService.toLatLng(pos), 16);
      } else if (mounted) {
        _mapController.move(
            MapConfig.defaultCenter, MapConfig.defaultZoom);
      }
    } catch (_) {
      if (mounted) {
        _mapController.move(
            MapConfig.defaultCenter, MapConfig.defaultZoom);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCenter = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);

    final userLocationFix = ref.watch(userLocationStreamProvider).valueOrNull;

    final mockData = ref.watch(mockDataServiceProvider);
    final realtimeTrips = ref.watch(realtimeTripsProvider);
    final liveTrips = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    final routes = mockData.routes;
    final filteredRoutes = _filteredRoutes(routes);
    final stops = mockData.stops;
    final cache = ref.watch(mapDataCacheProvider);
    final offline = ref.watch(isOfflineProvider);
    final mapStyle = ref.watch(themeNotifierProvider.select((n) => n.mapStyle));
    final fmtcTp = ref.watch(fmtcTileProviderProvider(mapStyle));
    final showAllStops = ref.watch(
        mapFilterControllerProvider.select((s) => s.showAllStops));

    final currentKey = '${isDark ? "d" : "l"}-$mapStyle';

    ref.listen(centerOnStopIdProvider, (prev, next) {
      if (next != null) {
        final stop = mockData.getStopById(next);
        if (stop != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _mapController.move(LatLng(stop.lat, stop.lng), 17);
          });
        }
        ref.read(centerOnStopIdProvider.notifier).state = null;
      }
    });
    final bool bypassFmtc;
    if (_lastMapKey != null && _lastMapKey != currentKey) {
      _bypassFmtcUntil = DateTime.now().add(const Duration(seconds: 3));
      bypassFmtc = true;
      final savedCenter = _mapController.camera.center;
      final savedZoom = _mapController.camera.zoom;
      _mapController.dispose();
      _mapController = MapController();
      _didInitialCenter = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mapController.move(savedCenter, savedZoom);
      });
    } else {
      bypassFmtc = _bypassFmtcUntil != null &&
          DateTime.now().isBefore(_bypassFmtcUntil!);
      if (!bypassFmtc && _bypassFmtcUntil != null) {
        _bypassFmtcUntil = null;
      }
    }
    _lastMapKey = currentKey;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          TransitMap(
            key: ValueKey('${isDark ? "d" : "l"}-$mapStyle'),
            isDark: isDark,
            mapStyle: mapStyle,
            controller: _mapController,
            fmtcTileProvider: bypassFmtc ? null : fmtcTp,
            additionalLayers: [
              if (userLocationFix != null)
                UserLocationLayer(
                  fix: userLocationFix,
                  isDark: isDark,
                ),
            ],
            routes: filteredRoutes,
            showAllStops: showAllStops,
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
            overlayWidgets: const [],
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
                            'Sin conexion . mapa offline',
                            style: TransitTypography.bodySmall(c.textMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
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
                      NotificationListener<ScrollNotification>(
                        onNotification: (n) {
                          if (_sheetController.size < 0.18 && n.metrics.pixels > 0) {
                            return true;
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: scrollController,
                        padding: EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          24 +
                              TransitSpacing.heightNavBar +
                              bottomPadding,
                        ),
                        itemCount: filteredRoutes.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _buildHandle(c, filteredRoutes.length, l10n);
                          }
                          final route = filteredRoutes[index - 1];
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
                              onGoToLine: () {
                                setState(() => _selectedRouteId = route.id);
                                final bounds = cache.routeBounds[route.id];
                                if (bounds != null && bounds.length == 4) {
                                  _mapController.fitCamera(
                                    CameraFit.bounds(
                                      bounds: LatLngBounds(
                                        LatLng(bounds[2], bounds[3]),
                                        LatLng(bounds[0], bounds[1]),
                                      ),
                                      padding: const EdgeInsets.all(40),
                                    ),
                                  );
                                  _didInitialCenter = true;
                                  _sheetController.animateTo(0.12,
                                      duration: const Duration(
                                          milliseconds: 250),
                                      curve: Curves.easeInOut);
                                }
                              },
                            ),
                          );
                        },
                      ),
                      ), // NotificationListener end
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
          _AnchoredMapControls(
            sheetController: _sheetController,
            isDark: isDark,
            loadingCenter: _loadingCenter,
            onCenter: _centerOnUser,
            onFilter: () => showMapFilterSheet(context, ref),
            onSearch: () => showMapSearchSheet(
              context,
              ref,
              _mapController,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandle(
      TransitColorScheme c, int routeCount, AppLocalizations l10n) {
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
                l10n.mapLinesSectionTitle.toUpperCase(),
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
                          l10n.actionClose.toUpperCase(),
                          style: TransitTypography.bodySmall(c.accent),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildServiceTypeFilter(c),
      ],
    );
  }

  Widget _buildServiceTypeFilter(TransitColorScheme c) {
    final filterTypes = <ServiceType?>[null, ...ServiceType.values];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: filterTypes.map((type) {
          final selected = _serviceTypeFilter == type;
          String label;
          if (type == null) {
            label = 'Todas';
          } else {
            label = type.label;
          }
          return GestureDetector(
            onTap: () => setState(() => _serviceTypeFilter = type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? c.accent : c.bgRaised,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? c.textHi : c.textMid,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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

class _AnchoredMapControls extends StatefulWidget {
  const _AnchoredMapControls({
    required this.sheetController,
    required this.isDark,
    required this.loadingCenter,
    required this.onCenter,
    required this.onFilter,
    required this.onSearch,
  });

  final DraggableScrollableController sheetController;
  final bool isDark;
  final bool loadingCenter;
  final VoidCallback onCenter;
  final VoidCallback onFilter;
  final VoidCallback onSearch;

  @override
  State<_AnchoredMapControls> createState() => _AnchoredMapControlsState();
}

class _AnchoredMapControlsState extends State<_AnchoredMapControls> {
  double _sheetFraction = 0.22;

  @override
  void initState() {
    super.initState();
    widget.sheetController.addListener(_onSheet);
  }

  void _onSheet() {
    if (!widget.sheetController.isAttached) return;
    final s = widget.sheetController.size;
    if ((s - _sheetFraction).abs() > 0.005) {
      setState(() => _sheetFraction = s);
    }
  }

  @override
  void dispose() {
    widget.sheetController.removeListener(_onSheet);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = MediaQuery.of(context).size.height;
    final sheetTop = screenH * (1 - _sheetFraction);
    final fabBottom = screenH - sheetTop - 4;  // 4px overlap para sensación de anclado
    final c = TransitColorScheme.of(widget.isDark);

    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 16,
            left: 16,
            child: _FabButton(
              icon: Icons.search,
              colors: c,
              onTap: widget.onSearch,
            ),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: _FabButton(
              icon: Icons.tune,
              colors: c,
              onTap: widget.onFilter,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 80),
            right: 16,
            bottom: fabBottom,
            child: _FabButton(
              icon: Icons.my_location,
              colors: c,
              onTap: widget.loadingCenter ? () {} : widget.onCenter,
              loading: widget.loadingCenter,
            ),
          ),
        ],
      ),
    );
  }
}

class _FabButton extends StatelessWidget {
  const _FabButton({
    required this.icon,
    required this.colors,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final TransitColorScheme colors;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: loading
            ? Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colors.textHi),
                  ),
                ),
              )
            : Icon(icon, size: 20, color: colors.textHi),
      ),
    );
  }
}
