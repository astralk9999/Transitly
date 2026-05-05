import 'package:flutter_dotenv/flutter_dotenv.dart';

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

/// Acceso tipado a las variables del `.env` de la app.
///
/// La carga se hace una sola vez en `main()` mediante [Env.load]; tras
/// ello, los getters resuelven en O(1) y lanzan [EnvException] si una
/// clave crítica falta o está vacía.
///
/// Las claves "críticas" (sin las cuales la app no puede arrancar) se
/// validan vía [_required]. Las "opcionales" (telemetría, mapas
/// premium) devuelven `null` cuando la integración no está configurada
/// — quien las consume decide si silenciar o degradar.
class Env {
  Env._();

  /// Carga `.env` en memoria. Llamar antes de cualquier otro getter.
  static Future<void> load({String fileName = '.env'}) =>
      dotenv.load(fileName: fileName);

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
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw EnvException(
        error: EnvError.missing,
        key: key,
        message: 'No definido en .env (o vacío)',
      );
    }
    return value;
  }

  static String? _optional(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
