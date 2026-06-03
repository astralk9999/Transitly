// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_filter_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapFilterState _$MapFilterStateFromJson(Map<String, dynamic> json) =>
    _MapFilterState(
      showOfficial: json['showOfficial'] as bool? ?? true,
      showCommunity: json['showCommunity'] as bool? ?? true,
      disabledOperators:
          (json['disabledOperators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      disabledKinds:
          (json['disabledKinds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      disabledLines:
          (json['disabledLines'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      disabledZones:
          (json['disabledZones'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      nextMinutes: (json['nextMinutes'] as num?)?.toInt() ?? 0,
      onlyAccessible: json['onlyAccessible'] as bool? ?? false,
      onlyFavorites: json['onlyFavorites'] as bool? ?? false,
      showAllStops: json['showAllStops'] as bool? ?? false,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 5000,
    );

Map<String, dynamic> _$MapFilterStateToJson(_MapFilterState instance) =>
    <String, dynamic>{
      'showOfficial': instance.showOfficial,
      'showCommunity': instance.showCommunity,
      'disabledOperators': instance.disabledOperators.toList(),
      'disabledKinds': instance.disabledKinds.toList(),
      'disabledLines': instance.disabledLines.toList(),
      'disabledZones': instance.disabledZones.toList(),
      'nextMinutes': instance.nextMinutes,
      'onlyAccessible': instance.onlyAccessible,
      'onlyFavorites': instance.onlyFavorites,
      'showAllStops': instance.showAllStops,
      'radiusMeters': instance.radiusMeters,
    };
