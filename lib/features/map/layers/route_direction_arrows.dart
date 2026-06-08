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
      arrows.addAll(
          _arrowsForLine(points, color, spacingMeters, maxArrows, distance));
    }
    return arrows;
  }

  /// Flechas de dirección a partir de una polilínea suelta (rutas de
  /// comunidad, que no tienen LOD precalculado).
  static List<Marker> buildFromPoints({
    required List<LatLng> points,
    required int zoom,
    required Color color,
    int minZoom = 14,
    int maxArrows = 50,
  }) {
    if (zoom < minZoom || points.length < 2) return [];
    return _arrowsForLine(
        points, color, 400.0, maxArrows, const Distance());
  }

  static List<Marker> _arrowsForLine(List<LatLng> points, Color color,
      double spacingMeters, int maxArrows, Distance distance) {
    final arrows = <Marker>[];
    final segLengths = <double>[];
    double totalLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      final d = distance.as(LengthUnit.Meter, points[i], points[i + 1]);
      segLengths.add(d);
      totalLength += d;
    }

    final n = (totalLength / spacingMeters).floor().clamp(0, maxArrows);
    if (n == 0) return arrows;

    for (int k = 1; k <= n; k++) {
      final target = k * spacingMeters;
      double accumulated = 0;

      for (int i = 0; i < points.length - 1; i++) {
        final segLen = segLengths[i];
        if (accumulated + segLen >= target) {
          final t = segLen > 0 ? (target - accumulated) / segLen : 0.0;
          final a = points[i];
          final b = points[i + 1];
          final lat = a.latitude + (b.latitude - a.latitude) * t;
          final lng = a.longitude + (b.longitude - a.longitude) * t;
          final angle = atan2(
              b.latitude - a.latitude,
              (b.longitude - a.longitude) * cos(a.latitude * pi / 180));

          arrows.add(Marker(
            point: LatLng(lat, lng),
            width: 20,
            height: 20,
            child: Transform.rotate(
              angle: -angle + pi / 2,
              child: Icon(Icons.arrow_upward, size: 14, color: color),
            ),
          ));
          break;
        }
        accumulated += segLen;
      }
    }

    return arrows;
  }
}
