// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_filter_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MapFilterState _$MapFilterStateFromJson(Map<String, dynamic> json) =>
    _MapFilterState(
      showOfficial: json['showOfficial'] as bool? ?? true,
      showCommunity: json['showCommunity'] as bool? ?? true,
      activeOperators:
          (json['activeOperators'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      activeKinds:
          (json['activeKinds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toSet() ??
          const <String>{},
      nextMinutes: (json['nextMinutes'] as num?)?.toInt() ?? 0,
      onlyAccessible: json['onlyAccessible'] as bool? ?? false,
      onlyFavorites: json['onlyFavorites'] as bool? ?? false,
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 5000,
    );

Map<String, dynamic> _$MapFilterStateToJson(_MapFilterState instance) =>
    <String, dynamic>{
      'showOfficial': instance.showOfficial,
      'showCommunity': instance.showCommunity,
      'activeOperators': instance.activeOperators.toList(),
      'activeKinds': instance.activeKinds.toList(),
      'nextMinutes': instance.nextMinutes,
      'onlyAccessible': instance.onlyAccessible,
      'onlyFavorites': instance.onlyFavorites,
      'radiusMeters': instance.radiusMeters,
    };
