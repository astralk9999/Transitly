import '../../../shared/models/feature_request.dart';

enum FeatureRequestRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class FeatureRequestRepositoryException implements Exception {
  const FeatureRequestRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final FeatureRequestRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'FeatureRequestRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Solicitudes genéricas (rutas nuevas, oficialización, mejoras de
/// app, correcciones de datos). Patrón análogo a [RouteSuggestion]
/// — `castVote` usa la RPC `cast_feature_request_vote` (F006).
abstract class FeatureRequestRepository {
  Future<List<FeatureRequest>> list();

  Future<FeatureRequest?> byId(String id);

  Future<FeatureRequest> create(FeatureRequest request);

  /// Devuelve el conteo de votos tras aplicar el del caller.
  Future<int> castVote(String requestId);
}
