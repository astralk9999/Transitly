import '../../../shared/models/offline_region.dart';

enum OfflineRegionRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class OfflineRegionRepositoryException implements Exception {
  const OfflineRegionRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final OfflineRegionRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'OfflineRegionRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Regiones del mapa descargadas para uso offline. Patrón local-first:
/// la caché Hive es la fuente de verdad; el backend Supabase actúa
/// como copia de respaldo para sincronizar entre dispositivos.
///
/// F20 conecta esto al descargador de tiles MapTiler.
abstract class OfflineRegionRepository {
  Future<List<OfflineRegion>> forUser(String userId, {int? limit, int? offset});

  Future<OfflineRegion> add(OfflineRegion region);

  Future<void> delete(String regionId);
}
