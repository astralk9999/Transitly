// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_share.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RouteShare _$RouteShareFromJson(Map<String, dynamic> json) => _RouteShare(
  routeId: json['routeId'] as String,
  sharedWithId: json['sharedWithId'] as String,
  sharedById: json['sharedById'] as String,
  permission:
      $enumDecodeNullable(_$RouteSharePermissionEnumMap, json['permission']) ??
      RouteSharePermission.view,
  createdAt: DateTime.parse(json['createdAt'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
);

Map<String, dynamic> _$RouteShareToJson(_RouteShare instance) =>
    <String, dynamic>{
      'routeId': instance.routeId,
      'sharedWithId': instance.sharedWithId,
      'sharedById': instance.sharedById,
      'permission': _$RouteSharePermissionEnumMap[instance.permission]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': ?instance.expiresAt?.toIso8601String(),
    };

const _$RouteSharePermissionEnumMap = {
  RouteSharePermission.view: 'view',
  RouteSharePermission.edit: 'edit',
};
