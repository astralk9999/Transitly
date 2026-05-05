// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AppNotificationImpl _$$AppNotificationImplFromJson(
  Map<String, dynamic> json,
) => _$AppNotificationImpl(
  id: json['id'] as String,
  userId: json['userId'] as String,
  type: $enumDecode(_$AppNotificationTypeEnumMap, json['type']),
  payload:
      json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  read: json['read'] as bool? ?? false,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$$AppNotificationImplToJson(
  _$AppNotificationImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'type': _$AppNotificationTypeEnumMap[instance.type]!,
  'payload': instance.payload,
  'read': instance.read,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$AppNotificationTypeEnumMap = {
  AppNotificationType.incidentResolved: 'incidentResolved',
  AppNotificationType.routePromoted: 'routePromoted',
  AppNotificationType.shareReceived: 'shareReceived',
  AppNotificationType.featureRequestReplied: 'featureRequestReplied',
  AppNotificationType.busApproachingFavorite: 'busApproachingFavorite',
  AppNotificationType.custom: 'custom',
};
