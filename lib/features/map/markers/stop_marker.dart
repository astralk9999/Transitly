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
  LatLngBounds? visibleBounds,
  bool ignoreZoomCutoff = false,
}) {
  if (!ignoreZoomCutoff && currentZoom < 13.0) return [];

  // Zoom 13-14: only show hub stops to reduce marker count.
  // When the caller pinned a specific route we always show its stops.
  final bool hubsOnly = !ignoreZoomCutoff && currentZoom < 14.5;

  final c = TransitColorScheme.of(isDark);
  final markers = <Marker>[];

  for (final stop in stops) {
    final isHub = hubStopIds.contains(stop.id);

    // Skip non-hub stops at medium zoom
    if (hubsOnly && !isHub) continue;

    // Viewport culling
    if (visibleBounds != null) {
      if (stop.lat < visibleBounds.south ||
          stop.lat > visibleBounds.north ||
          stop.lng < visibleBounds.west ||
          stop.lng > visibleBounds.east) {
        continue;
      }
    }

    // Tamaños subidos respecto al original (10/6-8) — los iconos
    // anteriores eran demasiado pequeños y costaba tocarlos.
    final dotSize = isHub ? 16.0 : (currentZoom < 15 ? 10.0 : 12.0);

    markers.add(Marker(
      point: LatLng(stop.lat, stop.lng),
      // Área de tap más generosa (antes 20×20).
      width: 32,
      height: 32,
      child: Semantics(
        label: 'Parada ${stop.name}',
        button: onTap != null,
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
      ),
    ));
  }

  return markers;
}
