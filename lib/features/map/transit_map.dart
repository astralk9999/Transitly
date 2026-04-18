import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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
  });

  final bool isDark;
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

    final stopMarkers = buildStopMarkers(
      stops: widget.stops,
      currentZoom: _currentZoom,
      isDark: widget.isDark,
      hubStopIds: widget.hubStopIds,
      onTap: widget.onStopTap,
      visibleBounds: _visibleBounds,
    );

    final busMarkers = buildBusMarkers(
      activeTrips: widget.activeTrips,
      routeMap: widget.routeMap,
      onTap: widget.onTripTap,
    );

    return Stack(
      children: [
        FlutterMap(
          mapController: widget.controller,
          options: MapOptions(
            initialCenter: widget.center ?? MapConfig.defaultCenter,
            initialZoom: widget.zoom ?? MapConfig.defaultZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
            onTap: widget.onMapTap,
            onPositionChanged: _onPositionChanged,
          ),
          children: [
            TileLayer(
              urlTemplate: MapConfig.tileUrl(widget.isDark),
              subdomains: MapConfig.subdomains,
              retinaMode: true,
            ),
            if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
            if (stopMarkers.isNotEmpty) MarkerLayer(markers: stopMarkers),
            if (busMarkers.isNotEmpty) MarkerLayer(markers: busMarkers),
            ...widget.additionalLayers,
          ],
        ),
        ...widget.overlayWidgets,
      ],
    );
  }
}
