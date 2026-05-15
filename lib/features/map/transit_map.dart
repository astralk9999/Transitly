import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/env.dart';
import '../../core/theme/transit_colors.dart';
import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import 'layers/route_polylines.dart';
import 'map_config.dart';
import 'markers/bus_marker.dart';
import 'markers/stop_marker.dart';

/// Returns LOD level 0-4 based on zoom.
int _zoomToLod(double zoom) {
  if (zoom < 12) return 0;
  if (zoom < 13) return 1;
  if (zoom < 14.5) return 2;
  if (zoom < 16) return 3;
  return 4;
}

class TransitMap extends StatefulWidget {
  const TransitMap({
    super.key,
    required this.isDark,
    this.mapStyle,
    this.center,
    this.zoom,
    this.controller,
    this.additionalLayers = const [],
    this.routes = const [],
    this.routePathsLod = const {},
    this.routeStopsMap = const {},
    this.routeBounds = const {},
    this.stops = const [],
    this.hubStopIds = const {},
    this.selectedRouteId,
    this.onStopTap,
    this.activeTrips = const [],
    this.routeMap = const {},
    this.onTripTap,
    this.overlayWidgets = const [],
    this.onMapTap,
    this.fmtcTileProvider,
  });

  final bool isDark;
  final String? mapStyle;
  final LatLng? center;
  final double? zoom;
  final MapController? controller;
  final List<Widget> additionalLayers;
  final List<RouteModel> routes;
  final Map<String, Map<int, List<LatLng>>> routePathsLod;
  final Map<String, List<StopModel>> routeStopsMap;
  final Map<String, List<double>> routeBounds;
  final List<StopModel> stops;
  final Set<String> hubStopIds;
  final String? selectedRouteId;
  final ValueChanged<StopModel>? onStopTap;
  final List<ActiveTripModel> activeTrips;
  final Map<String, RouteModel> routeMap;
  final ValueChanged<ActiveTripModel>? onTripTap;
  final List<Widget> overlayWidgets;
  final void Function(TapPosition, LatLng)? onMapTap;

  /// Optional FMTC tile provider for offline-cached tiles. When null,
  /// tiles are fetched from MapTiler URLs directly. When set, the
  /// provider serves cached tiles when offline and acts as a transparent
  /// cache when online. Set from F20 region download flow.
  final TileProvider? fmtcTileProvider;

  @override
  State<TransitMap> createState() => _TransitMapState();
}

class _TransitMapState extends State<TransitMap> {
  late double _currentZoom;
  late int _lodLevel;
  LatLngBounds? _visibleBounds;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoom ?? MapConfig.defaultZoom;
    _lodLevel = _zoomToLod(_currentZoom);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    final newLod = _zoomToLod(camera.zoom);
    final boundsChanged = _visibleBounds == null ||
        _boundsShiftedSignificantly(_visibleBounds!, camera.visibleBounds);
    final lodChanged = newLod != _lodLevel;

    // Always track raw zoom for polyline width calculations
    _currentZoom = camera.zoom;

    if (lodChanged || boundsChanged) {
      // Debounce: only rebuild after 100ms of inactivity
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) {
          setState(() {
            _lodLevel = newLod;
            _visibleBounds = camera.visibleBounds;
          });
        }
      });
    }
  }

  /// Returns true if viewport moved enough to warrant re-culling.
  bool _boundsShiftedSignificantly(LatLngBounds old, LatLngBounds current) {
    const threshold = 0.005; // ~500m shift
    return (old.north - current.north).abs() > threshold ||
        (old.south - current.south).abs() > threshold ||
        (old.east - current.east).abs() > threshold ||
        (old.west - current.west).abs() > threshold;
  }

  @override
  Widget build(BuildContext context) {
    final activeRouteIds = <String>{
      for (final t in widget.activeTrips)
        if (t.status != TripStatus.cancelled) t.routeId,
    };

    final polylines = buildRoutePolylines(
      routes: widget.routes,
      routePathsLod: widget.routePathsLod,
      routeStopsMap: widget.routeStopsMap,
      routeBounds: widget.routeBounds,
      selectedRouteId: widget.selectedRouteId,
      currentZoom: _currentZoom,
      lodLevel: _lodLevel,
      visibleBounds: _visibleBounds,
      activeRouteIds: activeRouteIds,
    );

    // Markers (buses + stops) are gated on a selected route — the map stays
    // visually quiet until the user opens a line, mirroring the way transit
    // maps surface detail on demand.
    final selectedId = widget.selectedRouteId;
    final visibleStops = selectedId == null
        ? const <StopModel>[]
        : (widget.routeStopsMap[selectedId] ?? const <StopModel>[]);
    final visibleTrips = selectedId == null
        ? const <ActiveTripModel>[]
        : widget.activeTrips
            .where((t) => t.routeId == selectedId)
            .toList(growable: false);

    final stopMarkers = buildStopMarkers(
      stops: visibleStops,
      currentZoom: _currentZoom,
      isDark: widget.isDark,
      hubStopIds: widget.hubStopIds,
      onTap: widget.onStopTap,
      visibleBounds: _visibleBounds,
      // Once a route is pinned we show every stop on it regardless of zoom.
      ignoreZoomCutoff: selectedId != null,
    );

    final busMarkers = buildBusMarkers(
      activeTrips: visibleTrips,
      routeMap: widget.routeMap,
      onTap: widget.onTripTap,
    );

    final c = TransitColorScheme.of(widget.isDark);
    // Slightly darker than `bgRaised` in light mode so the offline state
    // reads as "map area" instead of "blank page". Passed straight into
    // FlutterMap (its default 0xFFE0E0E0 was painting over our Stack).
    final fallback =
        widget.isDark ? c.bgRaised : const Color(0xFFC9CCD4);

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            initialCenter: widget.center ?? MapConfig.defaultCenter,
            initialZoom: widget.zoom ?? MapConfig.defaultZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
            backgroundColor: fallback,
            onTap: widget.onMapTap,
            onPositionChanged: _onPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: widget.fmtcTileProvider == null
                  ? MapConfig.tileUrl(
                      widget.mapStyle ?? (widget.isDark ? 'dark' : 'light'),
                      apiKey: Env.mapTilerApiKey,
                    )
                  : '',
              tileProvider: widget.fmtcTileProvider,
              subdomains: MapConfig.subdomains,
              retinaMode: false,
              userAgentPackageName: 'com.transitly.transitly',
              tileDisplay: const TileDisplay.fadeIn(
                duration: Duration(milliseconds: 200),
              ),
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (stopMarkers.isNotEmpty) MarkerLayer(markers: stopMarkers),
            if (busMarkers.isNotEmpty) MarkerLayer(markers: busMarkers),
            ...widget.additionalLayers,
          ],
        ),
        ...widget.overlayWidgets,
        Positioned(
          right: 4,
          bottom: 4,
          child: ColoredBox(
            color: const Color(0x88000000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Text(
                '\u00a9 MapTiler \u00a9 OpenStreetMap contributors',
                style: TextStyle(
                  fontSize: 9,
                  color: widget.isDark
                      ? const Color(0xCCFFFFFF)
                      : const Color(0xCC222222),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
