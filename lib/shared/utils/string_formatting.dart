/// Devuelve un badge de 2 caracteres de [s] en mayúsculas, seguro
/// contra strings de longitud < 2.
String safeBadge(String s) {
  if (s.isEmpty) return '··';
  if (s.length == 1) return '${s.toUpperCase()}·';
  return s.substring(0, 2).toUpperCase();
}
