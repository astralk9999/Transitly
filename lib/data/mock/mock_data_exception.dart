import 'mock_data_error.dart';

/// Excepción tipada del [MockDataService].
///
/// Patrón documentado en `ARCHITECTURE.md §4.3`: lleva un [error] del enum,
/// un [message] legible para logs y opcionalmente la causa original.
class MockDataException implements Exception {
  const MockDataException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final MockDataError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base = 'MockDataException(${error.name}): $message';
    if (cause == null) return base;
    return '$base — caused by: $cause';
  }
}
