import '../../../shared/models/route_feedback_model.dart';

enum RouteFeedbackRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class RouteFeedbackRepositoryException implements Exception {
  const RouteFeedbackRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final RouteFeedbackRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'RouteFeedbackRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Feedback de información (cambio de parada, error de horario,
/// corrección de info, etc.). Mismo patrón que [IncidentRepository]:
/// `create` con cola offline + cache local solo lectura.
abstract class RouteFeedbackRepository {
  Future<List<RouteFeedbackModel>> byAuthor(String authorId);

  Future<List<RouteFeedbackModel>> forRoute(String routeId);

  Future<RouteFeedbackModel> create(RouteFeedbackModel feedback);

  Future<List<RouteFeedbackModel>> listAll();

  Future<RouteFeedbackModel> updateStatus(String id, String status);
}
