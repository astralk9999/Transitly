/// Tipos de fallo al cargar configuración de entorno.
enum EnvError { missing, malformed }

class EnvException implements Exception {
  const EnvException({
    required this.error,
    required this.key,
    this.message,
  });

  final EnvError error;
  final String key;
  final String? message;

  @override
  String toString() {
    final base = 'EnvException(${error.name}, key=$key)';
    return message == null ? base : '$base — $message';
  }
}

/// Acceso tipado a las variables de entorno compiladas vía `--dart-define`.
///
/// Cada valor se declara como `const String.fromEnvironment('LITERAL')` para
/// que el AOT compiler de Dart lo embeba en el binario en release. **Importante:**
/// el nombre DEBE ser un literal en la llamada — `String.fromEnvironment(varName)`
/// con un parámetro variable devuelve cadena vacía en release (no se const-foldea).
///
/// Para desarrollo, pasar las variables en la línea de comandos:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
/// O usar un fichero: `--dart-define-from-file=dart_defines.json`.
abstract final class Env {
  Env._();

  // ── Constantes embebidas en build (AOT-friendly) ────────────

  static const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const String _supabaseFunctionsUrl =
      String.fromEnvironment('SUPABASE_FUNCTIONS_URL');
  static const String _postHogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
  static const String _postHogHost = String.fromEnvironment('POSTHOG_HOST');
  static const String _sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String _tosUrl = String.fromEnvironment('TRANSITLY_TOS_URL');
  static const String _privacyUrl = String.fromEnvironment('TRANSITLY_PRIVACY_URL');
  static const String _mapTilerApiKey = String.fromEnvironment('MAPTILER_API_KEY');

  // ── Supabase (críticas) ─────────────────────────────────────

  static String get supabaseUrl => _requireNonEmpty(_supabaseUrl, 'SUPABASE_URL');
  static String get supabaseAnonKey =>
      _requireNonEmpty(_supabaseAnonKey, 'SUPABASE_ANON_KEY');

  /// Por defecto deriva de [supabaseUrl] (`<url>/functions/v1`). Solo
  /// hace falta override si se usa un dominio dedicado para Edge.
  static String get supabaseFunctionsUrl => _supabaseFunctionsUrl.isEmpty
      ? '$supabaseUrl/functions/v1'
      : _supabaseFunctionsUrl;

  // ── Telemetría (opcionales) ─────────────────────────────────

  static String? get postHogApiKey =>
      _postHogApiKey.isEmpty ? null : _postHogApiKey;
  static String get postHogHost =>
      _postHogHost.isEmpty ? 'https://eu.posthog.com' : _postHogHost;
  static String? get sentryDsn => _sentryDsn.isEmpty ? null : _sentryDsn;

  // ── Legal (opcionales) ──────────────────────────────────────

  static String get tosUrl =>
      _tosUrl.isEmpty ? 'https://transitly.app/terms' : _tosUrl;
  static String get privacyUrl =>
      _privacyUrl.isEmpty ? 'https://transitly.app/privacy' : _privacyUrl;

  // ── Mapas (opcional, F20) ───────────────────────────────────

  static String? get mapTilerApiKey =>
      _mapTilerApiKey.isEmpty ? null : _mapTilerApiKey;

  // ── Helpers privados ────────────────────────────────────────

  static String _requireNonEmpty(String value, String key) {
    if (value.isEmpty) {
      throw EnvException(
        error: EnvError.missing,
        key: key,
        message: 'No definido en --dart-define (o vacío)',
      );
    }
    return value;
  }
}
