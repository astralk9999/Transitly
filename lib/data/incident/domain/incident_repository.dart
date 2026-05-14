import '../../../shared/models/incident_model.dart';

enum IncidentRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class IncidentRepositoryException implements Exception {
  const IncidentRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final IncidentRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'IncidentRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Reportes de incidencia. Es el primer repositorio con escritura
/// (`create`) que integra la cola offline de F3.3 — si la red falla
/// al crear, la mutación se encola y se devuelve éxito optimista.
abstract class IncidentRepository {
  Future<List<IncidentModel>> byAuthor(String authorId);

  Future<List<IncidentModel>> forRoute(String routeId);

  /// Crea un incident. Si la red falla, encola en
  /// `pending_actions` y devuelve `incident` con el id que tendrá
  /// cuando el drainer lo sincronice (UUID v4 generado en cliente).
  Future<IncidentModel> create(IncidentModel incident);

  Future<List<IncidentModel>> listAll();

  Future<IncidentModel> updateStatus(String id, String status);
}
