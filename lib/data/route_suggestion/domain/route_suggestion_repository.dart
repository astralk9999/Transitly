import '../../../shared/models/route_suggestion_model.dart';

enum RouteSuggestionRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class RouteSuggestionRepositoryException implements Exception {
  const RouteSuggestionRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final RouteSuggestionRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'RouteSuggestionRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Propuestas de nuevas rutas. La operación `castVote` invoca la
/// función SQL `cast_suggestion_vote` (F2.5) que es idempotente por
/// usuario y devuelve el nuevo total. Si la red falla, el voto se
/// encola y se devuelve un total optimista (+1 sobre el cacheado).
abstract class RouteSuggestionRepository {
  Future<List<RouteSuggestionModel>> list();

  Future<RouteSuggestionModel?> byId(String id);

  Future<RouteSuggestionModel> create(RouteSuggestionModel suggestion);

  /// Devuelve el conteo de votos tras aplicar el del caller.
  Future<int> castVote(String suggestionId);

  Future<RouteSuggestionModel> updateStatus(String id, String status);
}
