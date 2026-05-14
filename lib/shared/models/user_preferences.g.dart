// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserPreferencesImpl _$$UserPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$UserPreferencesImpl(
  userId: json['userId'] as String,
  themePaletteId: json['themePaletteId'] as String? ?? 'default',
  customColors: (json['customColors'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, e as String),
  ),
  backgroundId: json['backgroundId'] as String? ?? 'smoke',
  backgroundEnabled: json['backgroundEnabled'] as bool? ?? true,
  backgroundOpacity: (json['backgroundOpacity'] as num?)?.toDouble() ?? 1.0,
  fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
  colorBlindMode:
      $enumDecodeNullable(_$ColorBlindModeEnumMap, json['colorBlindMode']) ??
      ColorBlindMode.none,
  dyslexiaFontEnabled: json['dyslexiaFontEnabled'] as bool? ?? false,
  reduceMotion: json['reduceMotion'] as bool? ?? false,
  highContrast: json['highContrast'] as bool? ?? false,
);

Map<String, dynamic> _$$UserPreferencesImplToJson(
  _$UserPreferencesImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'themePaletteId': instance.themePaletteId,
  if (instance.customColors case final value?) 'customColors': value,
  'backgroundId': instance.backgroundId,
  'backgroundEnabled': instance.backgroundEnabled,
  'backgroundOpacity': instance.backgroundOpacity,
  'fontScale': instance.fontScale,
  'colorBlindMode': _$ColorBlindModeEnumMap[instance.colorBlindMode]!,
  'dyslexiaFontEnabled': instance.dyslexiaFontEnabled,
  'reduceMotion': instance.reduceMotion,
  'highContrast': instance.highContrast,
};

const _$ColorBlindModeEnumMap = {
  ColorBlindMode.none: 'none',
  ColorBlindMode.protanopia: 'protanopia',
  ColorBlindMode.deuteranopia: 'deuteranopia',
  ColorBlindMode.tritanopia: 'tritanopia',
};
