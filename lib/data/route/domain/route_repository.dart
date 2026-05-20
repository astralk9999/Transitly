import 'package:latlong2/latlong.dart';

import '../../../shared/models/route_model.dart';

enum RouteRepositoryError {
  notFound,
  network,
  parse,
  denied,
  unknown,
}

class RouteRepositoryException implements Exception {
  const RouteRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final RouteRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'RouteRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Rutas (oficiales y comunitarias). La visibilidad por usuario está
/// gobernada por RLS en Supabase; el repositorio no la duplica.
///
/// Consumido por:
/// - MapTab — `intersectingBbox()` al pan/zoom.
/// - RouteDetailScreen — `byId()` y `watch()`.
/// - F8 city picker — `byOperator()`.
/// - MyContributions / route editor — `community(ownerId)`.
abstract class RouteRepository {
  Future<List<RouteModel>> byOperator(String operatorId, {int? limit, int? offset});

  Future<RouteModel?> byId(String id);

  /// Snapshot + cambios subsiguientes (Realtime en F13).
  Stream<RouteModel?> watch(String id);

  /// Rutas comunitarias creadas por [ownerId] en cualquier status.
  /// Pensado para "Mis rutas" del editor.
  Future<List<RouteModel>> community(String ownerId);

  /// Rutas cuya geometría intersecta el viewport. Coordenadas SW
  /// (esquina inferior-izquierda) y NE (esquina superior-derecha).
  Future<List<RouteModel>> intersectingBbox(LatLng sw, LatLng ne);
}
