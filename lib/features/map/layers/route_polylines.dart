import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';
import '../../../shared/models/stop_model.dart';

List<Polyline> buildRoutePolylines({
  required List<RouteModel> routes,
  required Map<String, List<LatLng>> routePaths,
  required Map<String, List<StopModel>> routeStopsMap,
  String? selectedRouteId,
}) {
  final polylines = <Polyline>[];

  for (final route in routes) {
    var points = routePaths[route.id];

    // Fallback: connect stop coordinates in order
    if (points == null || points.isEmpty) {
      final stops = routeStopsMap[route.id];
      if (stops == null || stops.isEmpty) continue;
      points = stops.map((s) => LatLng(s.lat, s.lng)).toList();
    }

    if (points.isEmpty) continue;

    final bool isSelected = selectedRouteId != null && route.id == selectedRouteId;
    final bool hasSel = selectedRouteId != null;

    final double opacity = hasSel
        ? (isSelected ? 1.0 : 0.3)
        : 0.7;
    final double width = isSelected ? 4.0 : 3.0;

    polylines.add(Polyline(
      points: points,
      color: route.routeColor.withValues(alpha: opacity),
      strokeWidth: width,
    ));
  }

  return polylines;
}
