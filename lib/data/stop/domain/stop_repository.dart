import 'package:latlong2/latlong.dart';

import '../../../shared/models/stop_model.dart';

enum StopRepositoryError {
  notFound,
  network,
  parse,
  denied,
  unknown,
}

class StopRepositoryException implements Exception {
  const StopRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final StopRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'StopRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Paradas del transporte. Consumido por:
/// - F8 city picker / arranque de la app — `nearby()`.
/// - StopDetailScreen — `byId()` + `watch()`.
/// - F8 multi-operador — `byOperator()`.
abstract class StopRepository {
  Future<List<StopModel>> nearby(
    LatLng center, {
    double radiusM = 1000,
    int limit = 50,
  });

  Future<StopModel?> byId(String id);

  /// Stream que emite el estado actual de la parada y, cuando F13
  /// active Supabase Realtime, los cambios subsiguientes. Hoy emite
  /// cache → fresh y termina.
  Stream<StopModel?> watch(String id);

  Future<List<StopModel>> byOperator(String operatorId, {int? limit, int? offset});
}
