// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPreferences _$UserPreferencesFromJson(Map<String, dynamic> json) =>
    _UserPreferences(
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
          $enumDecodeNullable(
            _$ColorBlindModeEnumMap,
            json['colorBlindMode'],
          ) ??
          ColorBlindMode.none,
      dyslexiaFontEnabled: json['dyslexiaFontEnabled'] as bool? ?? false,
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      highContrast: json['highContrast'] as bool? ?? false,
      mapStyle: json['mapStyle'] as String? ?? 'streets',
      notifIncidentResolved: json['notifIncidentResolved'] as bool? ?? true,
      notifRoutePromoted: json['notifRoutePromoted'] as bool? ?? true,
      notifBusApproaching: json['notifBusApproaching'] as bool? ?? true,
      notifFeatureRequestReplied:
          json['notifFeatureRequestReplied'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietHoursStart: json['quietHoursStart'] as String?,
      quietHoursEnd: json['quietHoursEnd'] as String?,
      extendedTimers: json['extendedTimers'] as bool? ?? false,
    );

Map<String, dynamic> _$UserPreferencesToJson(_UserPreferences instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'themePaletteId': instance.themePaletteId,
      'customColors': ?instance.customColors,
      'backgroundId': instance.backgroundId,
      'backgroundEnabled': instance.backgroundEnabled,
      'backgroundOpacity': instance.backgroundOpacity,
      'fontScale': instance.fontScale,
      'colorBlindMode': _$ColorBlindModeEnumMap[instance.colorBlindMode]!,
      'dyslexiaFontEnabled': instance.dyslexiaFontEnabled,
      'reduceMotion': instance.reduceMotion,
      'highContrast': instance.highContrast,
      'mapStyle': instance.mapStyle,
      'notifIncidentResolved': instance.notifIncidentResolved,
      'notifRoutePromoted': instance.notifRoutePromoted,
      'notifBusApproaching': instance.notifBusApproaching,
      'notifFeatureRequestReplied': instance.notifFeatureRequestReplied,
      'quietHoursEnabled': instance.quietHoursEnabled,
      'quietHoursStart': ?instance.quietHoursStart,
      'quietHoursEnd': ?instance.quietHoursEnd,
      'extendedTimers': instance.extendedTimers,
    };

const _$ColorBlindModeEnumMap = {
  ColorBlindMode.none: 'none',
  ColorBlindMode.protanopia: 'protanopia',
  ColorBlindMode.deuteranopia: 'deuteranopia',
  ColorBlindMode.tritanopia: 'tritanopia',
  ColorBlindMode.protanomaly: 'protanomaly',
  ColorBlindMode.deuteranomaly: 'deuteranomaly',
  ColorBlindMode.tritanomaly: 'tritanomaly',
  ColorBlindMode.achromatopsia: 'achromatopsia',
  ColorBlindMode.achromatomaly: 'achromatomaly',
};
