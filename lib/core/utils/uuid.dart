import 'dart:math';

/// Genera un UUID v4 conforme a RFC 4122 sin depender del paquete
/// `uuid`. Uso pensado para ids client-side de mutaciones optimistas:
/// el cliente lo envía a Supabase y Postgres lo respeta como PK
/// (la columna `id UUID PRIMARY KEY DEFAULT gen_random_uuid()` acepta
/// inserts con id explícito).
///
/// Se basa en [Random.secure] — adecuado para identificadores que
/// no quieren colisionar, no para uso criptográfico fuerte.
String generateUuidV4() {
  final rng = Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  // version (4) y variant (10xx)
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join();
  return '${hex.substring(0, 8)}-'
      '${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-'
      '${hex.substring(20)}';
}
