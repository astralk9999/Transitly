import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RouteDirectionArrows {
  static List<Marker> build({
    required Map<String, Map<int, List<LatLng>>> routePathsLod,
    required List<String> routeIds,
    required int zoom,
    required Color color,
    int minZoom = 14,
    int maxArrows = 50,
  }) {
    if (zoom < minZoom) return [];

    final arrows = <Marker>[];
    const spacingMeters = 400.0;
    final distance = const Distance();

    for (final routeId in routeIds) {
      final lodData = routePathsLod[routeId];
      if (lodData == null) continue;

      final points = lodData[4] ?? lodData.values.last;
      if (points.length < 2) continue;

      double accumulated = 0;

      for (int i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];

        final segmentDist =
            distance.as(LengthUnit.Meter, a, b);
        accumulated += segmentDist;

        if (accumulated >= spacingMeters || i == 0) {
          accumulated = 0;
          final angle = atan2(
              b.latitude - a.latitude,
              (b.longitude - a.longitude) * cos(a.latitude * pi / 180));
          final mid = LatLng(
            (a.latitude + b.latitude) / 2,
            (a.longitude + b.longitude) / 2,
          );

          arrows.add(Marker(
            point: mid,
            width: 20,
            height: 20,
            child: Transform.rotate(
              angle: -angle + pi / 2,
              child: Icon(Icons.arrow_upward, size: 14, color: color),
            ),
          ));

          if (arrows.length >= maxArrows) break;
        }
      }

      if (arrows.length >= maxArrows) break;
    }

    return arrows;
  }
}
