import '../../../shared/models/user_preferences.dart';

enum UserPreferencesRepositoryError {
  notFound,
  network,
  parse,
  denied,
  validation,
  unknown,
}

class UserPreferencesRepositoryException implements Exception {
  const UserPreferencesRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final UserPreferencesRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'UserPreferencesRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Preferencias del usuario autenticado. Singleton por uid — un solo
/// registro por cuenta, creado automáticamente por el trigger
/// `on_auth_user_created` en Supabase.
///
/// Usado por:
/// - F4 (auth) — lee preferencias al hidratar la sesión.
/// - F17 (apariencia) — persiste paleta y fondo personalizados.
/// - F18 (accesibilidad) — persiste fontScale, colorBlindMode, etc.
abstract class UserPreferencesRepository {
  /// Preferencias del usuario autenticado. Devuelve defaults si no
  /// existe aún el registro en el backend (arranque en frío).
  Future<UserPreferences> getMine();

  /// Guarda las preferencias en backend y caché. Si la red falla,
  /// la cache local se actualiza igual y la mutación se encola.
  Future<UserPreferences> update(UserPreferences prefs);
}
