/// Errores tipados del [MockDataService].
///
/// Sigue la convención de `ARCHITECTURE.md §4.3`: enum + `*Exception` con
/// `cause` opcional. La UI traduce el enum a una cadena localizada cuando
/// el error escala a un widget.
enum MockDataError {
  /// El asset declarado en `pubspec.yaml` no se encuentra al `loadString`.
  assetNotFound,

  /// El contenido del asset no es JSON válido (FormatException de
  /// `json.decode`).
  parseError,

  /// El JSON parsea pero la forma esperada no se cumple: falta una clave
  /// top-level requerida o un tipo no es el esperado.
  unexpectedSchema,

  /// Cualquier otro fallo no clasificable (PlatformException del canal de
  /// assets, fallo del file-system, etc.).
  unknown,
}
