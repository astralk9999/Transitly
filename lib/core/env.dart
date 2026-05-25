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

/// Acceso tipado a las variables de entorno compiladas vía `--dart-define`
/// con fallback hardcodeado para desarrollo.
///
/// Cada valor se lee de `String.fromEnvironment` en tiempo de compilación.
/// Si no está definido, se usa un fallback hardcodeado (solo para APK demo).
/// Las claves "críticas" (sin las cuales la app no puede arrancar) se
/// validan vía [_required].
abstract final class Env {
  Env._();

  // ── Supabase (críticas) ─────────────────────────────────────

  static String get supabaseUrl => _required('SUPABASE_URL');
  static String get supabaseAnonKey => _required('SUPABASE_ANON_KEY');

  /// Por defecto deriva de [supabaseUrl] (`<url>/functions/v1`). Solo
  /// hace falta override si se usa un dominio dedicado para Edge.
  static String get supabaseFunctionsUrl =>
      _optional('SUPABASE_FUNCTIONS_URL') ?? '$supabaseUrl/functions/v1';

  // ── Telemetría (opcionales) ─────────────────────────────────

  static String? get postHogApiKey => _optional('POSTHOG_API_KEY');
  static String get postHogHost =>
      _optional('POSTHOG_HOST') ?? 'https://eu.posthog.com';
  static String? get sentryDsn => _optional('SENTRY_DSN');

  // ── Legal (opcionales) ──────────────────────────────────────

  static String get tosUrl =>
      _optional('TRANSITLY_TOS_URL') ?? 'https://transitly.app/terms';

  static String get privacyUrl =>
      _optional('TRANSITLY_PRIVACY_URL') ?? 'https://transitly.app/privacy';

  // ── Mapas (opcional, F20) ───────────────────────────────────

  static String? get mapTilerApiKey => _optional('MAPTILER_API_KEY');

  // ── Helpers privados ────────────────────────────────────────

  static String _required(String key) {
    final value = String.fromEnvironment(key);
    if (value.isNotEmpty) return value;
    // Fallback a hardcode para APK demo/desarrollo.
    // En producción usar --dart-define (SEC2).
    const hardcoded = <String, String>{
      'SUPABASE_URL': 'https://mmzahxtiaurkgtmtehxk.supabase.co',
      'SUPABASE_ANON_KEY': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1temFoeHRpYXVya2d0bXRlaHhrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY4MTA3MTksImV4cCI6MjA5MjM4NjcxOX0.wtFxK6ha6WrQXhtN3Jg-Ob7iwOeKhfk7G127gbXGuK8',
    };
    final fallback = hardcoded[key];
    if (fallback != null && fallback.isNotEmpty) return fallback;
    throw EnvException(
      error: EnvError.missing,
      key: key,
      message: 'No definido en --dart-define ni hardcodeado',
    );
  }

  static String? _optional(String key) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) return null;
    return value;
  }
}
