import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/models/stop_model.dart';

List<Marker> buildStopMarkers({
  required List<StopModel> stops,
  required double currentZoom,
  bool isDark = true,
  Set<String> hubStopIds = const {},
  ValueChanged<StopModel>? onTap,
}) {
  if (currentZoom < 13.0) return [];

  final c = TransitColorScheme.of(isDark);

  return stops.map((stop) {
    final isHub = hubStopIds.contains(stop.id);
    final dotSize = isHub ? 10.0 : (currentZoom < 15 ? 6.0 : 8.0);

    return Marker(
      point: LatLng(stop.lat, stop.lng),
      width: 20,
      height: 20,
      child: GestureDetector(
        onTap: onTap != null ? () => onTap(stop) : null,
        child: Center(
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: c.accent,
              shape: BoxShape.circle,
              border: Border.all(color: c.bgRoot, width: 1),
            ),
          ),
        ),
      ),
    );
  }).toList();
}
