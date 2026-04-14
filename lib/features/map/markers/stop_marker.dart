import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/stop_model.dart';

List<Marker> buildStopMarkers({
  required List<StopModel> stops,
  required double currentZoom,
  Set<String> hubStopIds = const {},
  ValueChanged<StopModel>? onTap,
}) {
  if (currentZoom < 13.0) return [];

  const accent = Color(0xFF00C896);
  const bgBorder = Color(0xFF0C0C0C);

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
              color: accent,
              shape: BoxShape.circle,
              border: Border.all(color: bgBorder, width: 1),
            ),
          ),
        ),
      ),
    );
  }).toList();
}
