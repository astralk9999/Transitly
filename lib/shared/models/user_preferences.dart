import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_preferences.freezed.dart';
part 'user_preferences.g.dart';

enum ColorBlindMode { none, protanopia, deuteranopia, tritanopia }

/// Preferencias de presentación y accesibilidad de un usuario. Habilita
/// el panel custom de F17 (apariencia) y la accesibilidad ampliada de
/// F18, manteniendo la configuración persistente entre sesiones.
@freezed
class UserPreferences with _$UserPreferences {
  const factory UserPreferences({
    required String userId,
    @Default('default') String themePaletteId,
    Map<String, String>? customColors,
    @Default('smoke') String backgroundId,
    @Default(true) bool backgroundEnabled,
    @Default(1.0) double backgroundOpacity,
    @Default(1.0) double fontScale,
    @Default(ColorBlindMode.none) ColorBlindMode colorBlindMode,
    @Default(false) bool dyslexiaFontEnabled,
    @Default(false) bool reduceMotion,
    @Default(false) bool highContrast,
    @Default('streets') String mapStyle,
  }) = _UserPreferences;

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      _$UserPreferencesFromJson(json);
}
