import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../shared/models/active_trip_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import 'layers/route_polylines.dart';
import 'map_config.dart';
import 'markers/bus_marker.dart';
import 'markers/stop_marker.dart';

class TransitMap extends StatefulWidget {
  const TransitMap({
    super.key,
    required this.isDark,
    this.center,
    this.zoom,
    this.controller,
    this.additionalLayers = const [],
    this.routes = const [],
    this.routePaths = const {},
    this.routeStopsMap = const {},
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
  final Map<String, List<LatLng>> routePaths;
  final Map<String, List<StopModel>> routeStopsMap;
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

  @override
  void initState() {
    super.initState();
    _currentZoom = widget.zoom ?? MapConfig.defaultZoom;
  }

  @override
  Widget build(BuildContext context) {
    final polylines = buildRoutePolylines(
      routes: widget.routes,
      routePaths: widget.routePaths,
      routeStopsMap: widget.routeStopsMap,
      selectedRouteId: widget.selectedRouteId,
    );

    final stopMarkers = buildStopMarkers(
      stops: widget.stops,
      currentZoom: _currentZoom,
      hubStopIds: widget.hubStopIds,
      onTap: widget.onStopTap,
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
            onPositionChanged: (camera, hasGesture) {
              if (camera.zoom != _currentZoom) {
                setState(() => _currentZoom = camera.zoom);
              }
            },
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
