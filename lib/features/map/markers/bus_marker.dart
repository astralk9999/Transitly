import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/active_trip_model.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/route_model.dart';

List<Marker> buildBusMarkers({
  required List<ActiveTripModel> activeTrips,
  required Map<String, RouteModel> routeMap,
  ValueChanged<ActiveTripModel>? onTap,
}) {
  return activeTrips
      .where((t) =>
          t.currentLat != null &&
          t.currentLng != null &&
          t.status != TripStatus.cancelled)
      .map((trip) {
    final route = routeMap[trip.routeId];
    final color = route?.routeColor ?? const Color(0xFF00C896);

    return Marker(
      point: LatLng(trip.currentLat!, trip.currentLng!),
      width: 32,
      height: 32,
      child: GestureDetector(
        onTap: onTap != null ? () => onTap(trip) : null,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          alignment: Alignment.center,
          child: Text(
            route?.code ?? '?',
            style: GoogleFonts.ibmPlexMono(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }).toList();
}
