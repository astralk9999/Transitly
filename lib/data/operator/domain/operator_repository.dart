import 'package:latlong2/latlong.dart';

import '../../../shared/models/operator_model.dart';

/// Tipos de fallo que puede emitir cualquier implementación de
/// [OperatorRepository]. Mismo enum tipado en repositorio remoto y
/// local — la UI no necesita distinguir el origen para localizar.
enum OperatorRepositoryError {
  notFound,
  network,
  parse,
  denied,
  conflict,
  unknown,
}

class OperatorRepositoryException implements Exception {
  const OperatorRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final OperatorRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'OperatorRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Operadores de transporte. Usado por:
/// - F8 (city picker) — `nearby()` con la posición del usuario.
/// - F2 (lazy multi-operador) — `list()` y `byId()`.
abstract class OperatorRepository {
  /// Todos los operadores conocidos. Pensado para listas pequeñas
  /// (< 100). Para datasets grandes, usa [limit] y [offset].
  Future<List<OperatorModel>> list({int? limit, int? offset});

  Future<OperatorModel?> byId(String id);

  /// Operadores cuya bounding box cae dentro de un radio (m) en
  /// torno a [center]. Por defecto 50 km — radio típico de búsqueda
  /// urbana extendida.
  Future<List<OperatorModel>> nearby(
    LatLng center, {
    double radiusM = 50000,
  });

  Future<OperatorModel> create(OperatorModel operator);

  Future<OperatorModel> update(OperatorModel operator);

  Future<void> delete(String id);
}
