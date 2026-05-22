import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/mock/mock_data_service.dart';
import '../../../data/mock/mock_realtime_service.dart';
import '../../models/active_trip_model.dart';
import '../../models/stop_model.dart';

/// Snapshot inmutable del estado derivado de un trip activo. Compone la
/// info que la pantalla `ActiveRouteScreen` necesita para renderizar sin
/// hacer cómputo en `build()`.
///
/// `firstStop` y `lastStop` son non-nullable: si la ruta tuviera 0 stops
/// (caso patológico), el provider devuelve `null` en lugar de un detalle
/// inválido. Si la ruta tiene exactamente 1 stop, `firstStop == lastStop`.
class ActiveTripDetail {
  const ActiveTripDetail({
    required this.trip,
    required this.currentIdx,
    required this.nextStop,
    required this.firstStop,
    required this.lastStop,
  });

  final ActiveTripModel trip;
  final int currentIdx;
  final StopModel? nextStop;
  final StopModel firstStop;
  final StopModel lastStop;
}

/// Detalle del trip identificado por [tripId].
///
/// Lee primero los trips en vivo (`realtimeTripsProvider`) y, si el stream
/// aún no emitió, cae en el snapshot estático (`mockData.activeTrips`).
/// Devuelve `null` si:
/// - no existe ningún trip con ese id, o
/// - la ruta del trip no tiene stops registrados.
final activeTripDetailProvider =
    Provider.autoDispose.family<ActiveTripDetail?, String>((ref, tripId) {
  final mockData = ref.watch(mockDataServiceProvider);
  final realtime =
      ref.watch(realtimeTripsProvider).valueOrNull ?? mockData.activeTrips;

  ActiveTripModel? trip;
  for (final t in realtime) {
    if (t.id == tripId) {
      trip = t;
      break;
    }
  }
  if (trip == null) return null;

  final stops = mockData.getStopsForRoute(trip.routeId);
  if (stops.isEmpty) return null;

  final currentIdx = trip.currentStopIndex ?? 0;
  final nextStop =
      currentIdx + 1 < stops.length ? stops[currentIdx + 1] : null;

  return ActiveTripDetail(
    trip: trip,
    currentIdx: currentIdx,
    nextStop: nextStop,
    firstStop: stops.first,
    lastStop: stops.last,
  );
});
