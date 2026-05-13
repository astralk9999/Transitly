import 'dart:math';
import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';
import '../../../shared/models/route_stop_model.dart';
import '../../../shared/models/schedule_model.dart';
import '../../../shared/models/stop_model.dart';

/// Posición estimada de un bus en una ruta basada en su horario de
/// salida y velocidad media. Se usa cuando no hay datos GTFS-Realtime
/// ni posición de conductor.
class EstimatedBus {
  const EstimatedBus({
    required this.routeId,
    required this.position,
    required this.bearing,
    required this.nextStopId,
    required this.nextStopEtaMinutes,
    required this.schedule,
  });

  final String routeId;
  final LatLng position;
  final double bearing;
  final String? nextStopId;
  final int nextStopEtaMinutes;
  final ScheduleModel schedule;
}

/// Función pura: estima la posición de un bus en una ruta.
/// Sin dependencias de estado externo — el provider la consume.
EstimatedBus? estimateBusPosition({
  required RouteModel route,
  required ScheduleModel schedule,
  required List<RouteStopModel> orderedStops,
  required List<StopModel> stops,
  required DateTime now,
  double? avgSpeedMps,
  int dwellTimeSeconds = 30,
}) {
  // Parsear hora de salida
  final departureParts = schedule.departureTime.split(':');
  final depHour = int.tryParse(departureParts[0]) ?? 0;
  final depMin = int.tryParse(departureParts[1]) ?? 0;
  final departure = DateTime(now.year, now.month, now.day, depHour, depMin);

  final tOffset = now.difference(departure).inSeconds;

  // Si aún no ha salido, poner en primera parada
  if (tOffset <= 0) {
    if (orderedStops.isNotEmpty && stops.isNotEmpty) {
      final firstStopId = orderedStops.first.stopId;
      final firstStop =
          stops.where((s) => s.id == firstStopId).firstOrNull;
      if (firstStop != null) {
        return EstimatedBus(
          routeId: route.id,
          position: LatLng(firstStop.lat, firstStop.lng),
          bearing: 0,
          nextStopId: firstStopId,
          nextStopEtaMinutes: 0,
          schedule: schedule,
        );
      }
    }
    return null;
  }

  // Velocidad media
  final speed = avgSpeedMps ?? _estimateSpeed(orderedStops, stops);

  // Distancia total recorrida desde la salida
  final totalDwells =
      orderedStops.isNotEmpty ? (orderedStops.length - 1) * dwellTimeSeconds : 0;
  final travelTime = tOffset - totalDwells;
  if (travelTime < 0) return null;

  final distanceTraveled = speed * travelTime;

  // Calcular punto sobre la polilínea entre paradas
  double accumulated = 0;
  LatLng? position;
  double bearing = 0;
  String? nextStopId;
  int nextEta = 0;

  for (int i = 0; i < orderedStops.length - 1; i++) {
    final fromStopId = orderedStops[i].stopId;
    final toStopId = orderedStops[i + 1].stopId;
    final fromStop = stops.where((s) => s.id == fromStopId).firstOrNull;
    final toStop = stops.where((s) => s.id == toStopId).firstOrNull;
    if (fromStop == null || toStop == null) continue;

    final seg = _haversineMeters(
        fromStop.lat, fromStop.lng, toStop.lat, toStop.lng);

    if (accumulated + seg >= distanceTraveled) {
      final remaining = distanceTraveled - accumulated;
      final fraction = seg > 0 ? (remaining / seg).clamp(0.0, 1.0) : 1.0;
      final lat = fromStop.lat + (toStop.lat - fromStop.lat) * fraction;
      final lng = fromStop.lng + (toStop.lng - fromStop.lng) * fraction;
      position = LatLng(lat, lng);

      // Bearing hacia la siguiente parada
      bearing = _bearing(
          fromStop.lat, fromStop.lng, toStop.lat, toStop.lng);

      // Calcular ETA a la siguiente parada
      final remainingDist = seg - remaining;
      nextEta = speed > 0 ? (remainingDist / speed / 60).round() : 1;
      nextStopId = toStopId;

      break;
    }
    accumulated += seg;
  }

  // Si llegó al final
  if (position == null) {
    final lastStop = stops
        .where((s) => s.id == orderedStops.last.stopId)
        .firstOrNull;
    if (lastStop != null) {
      position = LatLng(lastStop.lat, lastStop.lng);
      bearing = 0;
      nextStopId = null;
      nextEta = 0;
    }
  }

  if (position == null) return null;

  return EstimatedBus(
    routeId: route.id,
    position: position,
    bearing: bearing,
    nextStopId: nextStopId,
    nextStopEtaMinutes: nextEta,
    schedule: schedule,
  );
}

double _estimateSpeed(
    List<RouteStopModel> orderedStops, List<StopModel> stops) {
  double totalDist = 0;
  for (int i = 0; i < orderedStops.length - 1; i++) {
    final from = stops
        .where((s) => s.id == orderedStops[i].stopId)
        .firstOrNull;
    final to = stops
        .where((s) => s.id == orderedStops[i + 1].stopId)
        .firstOrNull;
    if (from == null || to == null) continue;
    totalDist += _haversineMeters(from.lat, from.lng, to.lat, to.lng);
  }

  final lastMinutes = orderedStops.isNotEmpty
      ? orderedStops.last.timeFromStartMinutes
      : null;
  final effectiveMinutes = (lastMinutes != null && lastMinutes > 0)
      ? lastMinutes
      : 30;

  return (totalDist / (effectiveMinutes * 60));
}

double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLng = (lng2 - lng1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
          sin(dLng / 2) * sin(dLng / 2);
  return 2 * r * atan2(sqrt(a), sqrt(1 - a));
}

double _bearing(double lat1, double lng1, double lat2, double lng2) {
  final dLng = (lng2 - lng1) * pi / 180;
  final lat1r = lat1 * pi / 180;
  final lat2r = lat2 * pi / 180;
  final y = sin(dLng) * cos(lat2r);
  final x = cos(lat1r) * sin(lat2r) -
      sin(lat1r) * cos(lat2r) * cos(dLng);
  return (atan2(y, x) * 180 / pi + 360) % 360;
}
