// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RouteShareImpl _$$RouteShareImplFromJson(Map<String, dynamic> json) =>
    _$RouteShareImpl(
      routeId: json['routeId'] as String,
      sharedWithId: json['sharedWithId'] as String,
      sharedById: json['sharedById'] as String,
      permission:
          $enumDecodeNullable(
            _$RouteSharePermissionEnumMap,
            json['permission'],
          ) ??
          RouteSharePermission.view,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
    );

Map<String, dynamic> _$$RouteShareImplToJson(_$RouteShareImpl instance) =>
    <String, dynamic>{
      'routeId': instance.routeId,
      'sharedWithId': instance.sharedWithId,
      'sharedById': instance.sharedById,
      'permission': _$RouteSharePermissionEnumMap[instance.permission]!,
      'createdAt': instance.createdAt.toIso8601String(),
      if (instance.expiresAt?.toIso8601String() case final value?)
        'expiresAt': value,
    };

const _$RouteSharePermissionEnumMap = {
  RouteSharePermission.view: 'view',
  RouteSharePermission.edit: 'edit',
};
