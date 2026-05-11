import '../../../shared/models/enums.dart';
import '../../../shared/models/schedule_model.dart';

enum ScheduleRepositoryError {
  notFound,
  network,
  parse,
  denied,
  unknown,
}

class ScheduleRepositoryException implements Exception {
  const ScheduleRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final ScheduleRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'ScheduleRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Horarios de una ruta. Consumido por:
/// - RouteDetailScreen — `forRoute(id, dayType)` para el grid.
/// - HomeTab.habitualTrip + `_buildNearbyStop` — `nextDepartures` para
///   el countdown.
/// - F0.5.B `upcomingDeparturesForRouteProvider` — migra a este repo
///   en F3.4.
abstract class ScheduleRepository {
  Future<List<ScheduleModel>> forRoute(String routeId, {DayType? dayType});

  /// Próximas [count] salidas desde ahora en el día actual (lógica
  /// del día computada por el caller mediante [DateTime.now]).
  Future<List<ScheduleModel>> nextDepartures(String routeId, int count);
}
