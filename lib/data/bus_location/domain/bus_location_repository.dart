import '../../../shared/models/bus_location.dart';

enum BusLocationRepositoryError {
  notFound,
  network,
  parse,
  denied,
  unknown,
}

class BusLocationRepositoryException implements Exception {
  const BusLocationRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final BusLocationRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'BusLocationRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Posiciones GPS de buses. Lectura intensiva, escritura desde
/// driver/edge-functions (no contemplada en este repo — la inserción
/// en `bus_positions` la hace `BusPositionSource.driver` vía RLS).
///
/// El stream es un stub hoy: emite snapshot del cache + del remoto y
/// termina. F13 lo cambiará por una suscripción a Supabase Realtime
/// sobre `public:bus_positions:route_id=eq.<id>`.
abstract class BusLocationRepository {
  /// Última posición conocida del bus que opera [routeId]. `null` si
  /// no hay ninguna en la última hora (más allá la consideramos
  /// expirada — `expires_at` de la tabla cubre la limpieza).
  Future<BusLocation?> latestForRoute(String routeId);

  /// Stream que emite la posición conocida y, cuando F13 lo conecte
  /// a Realtime, las actualizaciones subsiguientes. Hoy emite una o
  /// dos veces y se cierra.
  Stream<BusLocation?> streamForRoute(String routeId);
}
