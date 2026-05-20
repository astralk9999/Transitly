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
/// Cada valor se lee de `String.fromEnvironment` en tiempo de compilación.
/// Las claves "críticas" (sin las cuales la app no puede arrancar) se
/// validan vía [_required]. Las "opcionales" (telemetría, mapas premium)
/// devuelven `null` cuando la integración no está configurada.
///
/// Para desarrollo, pasar las variables en la línea de comandos:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
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

  // ── Mapas (opcional, F20) ───────────────────────────────────

  static String? get mapTilerApiKey => _optional('MAPTILER_API_KEY');

  // ── Helpers privados ────────────────────────────────────────

  static String _required(String key) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) {
      throw EnvException(
        error: EnvError.missing,
        key: key,
        message: 'No definido en --dart-define (o vacío)',
      );
    }
    return value;
  }

  static String? _optional(String key) {
    final value = String.fromEnvironment(key);
    if (value.isEmpty) return null;
    return value;
  }
}
