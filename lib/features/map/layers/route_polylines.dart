import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';

/// Check if a route's bounding box intersects the visible viewport.
bool _routeIntersectsViewport(
    List<double> bounds, LatLngBounds viewport) {
  // bounds = [minLat, minLng, maxLat, maxLng]
  return bounds[0] <= viewport.north &&
      bounds[2] >= viewport.south &&
      bounds[1] <= viewport.east &&
      bounds[3] >= viewport.west;
}

List<Polyline> buildRoutePolylines({
  required List<RouteModel> routes,
  required Map<String, Map<int, List<LatLng>>> routePathsLod,
  required Map<String, List<StopModel>> routeStopsMap,
  Map<String, List<double>> routeBounds = const {},
  String? selectedRouteId,
  double currentZoom = 13.0,
  int lodLevel = 2,
  LatLngBounds? visibleBounds,
  Set<String> activeRouteIds = const {},
}) {
  // No polylines at very low zoom
  if (currentZoom < 11.0 && selectedRouteId == null) return [];

  final polylines = <Polyline>[];

  for (final route in routes) {
    final bool isSelected =
        selectedRouteId != null && route.id == selectedRouteId;
    final bool isActive = activeRouteIds.contains(route.id);

    // At medium zoom, only show selected or active routes
    if (currentZoom < 13.0 && !isSelected && !isActive) continue;

    // Viewport culling: skip routes outside visible area
    if (visibleBounds != null && !isSelected) {
      final bounds = routeBounds[route.id];
      if (bounds != null && !_routeIntersectsViewport(bounds, visibleBounds)) {
        continue;
      }
    }

    // Select points at appropriate LOD level, fall back to nearest available
    final lodData = routePathsLod[route.id];
    var points = lodData?[lodLevel] ?? lodData?[4] ?? lodData?.values.last;

    // Fallback: connect stop coordinates in order
    if (points == null || points.isEmpty) {
      final stops = routeStopsMap[route.id];
      if (stops == null || stops.isEmpty) continue;
      points = stops.map((s) => LatLng(s.lat, s.lng)).toList();
    }

    if (points.isEmpty) continue;

    final bool hasSel = selectedRouteId != null;

    final double opacity = hasSel
        ? (isSelected ? 0.9 : 0.15)
        : 0.6;
    final double width = isSelected ? 4.5 : 3.0;

    // Shadow/glow under selected line
    if (isSelected) {
      polylines.add(Polyline(
        points: points,
        color: route.routeColor.withValues(alpha: 0.25),
        strokeWidth: 10,
        borderColor: Colors.transparent,
        borderStrokeWidth: 0,
      ));
    }

    polylines.add(Polyline(
      points: points,
      color: route.routeColor.withValues(alpha: opacity),
      strokeWidth: width,
      borderColor: Colors.black
          .withValues(alpha: hasSel && !isSelected ? 0 : 0.15),
      borderStrokeWidth: hasSel && !isSelected ? 0 : 0.5,
    ));
  }

  return polylines;
}
