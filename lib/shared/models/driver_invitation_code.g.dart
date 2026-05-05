// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'driver_invitation_code.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DriverInvitationCodeImpl _$$DriverInvitationCodeImplFromJson(
  Map<String, dynamic> json,
) => _$DriverInvitationCodeImpl(
  code: json['code'] as String,
  operatorId: json['operatorId'] as String,
  createdBy: json['createdBy'] as String,
  maxUses: (json['maxUses'] as num?)?.toInt() ?? 1,
  uses: (json['uses'] as num?)?.toInt() ?? 0,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  kind:
      $enumDecodeNullable(_$InvitationKindEnumMap, json['kind']) ??
      InvitationKind.driver,
);

Map<String, dynamic> _$$DriverInvitationCodeImplToJson(
  _$DriverInvitationCodeImpl instance,
) => <String, dynamic>{
  'code': instance.code,
  'operatorId': instance.operatorId,
  'createdBy': instance.createdBy,
  'maxUses': instance.maxUses,
  'uses': instance.uses,
  'expiresAt': instance.expiresAt.toIso8601String(),
  'kind': _$InvitationKindEnumMap[instance.kind]!,
};

const _$InvitationKindEnumMap = {
  InvitationKind.driver: 'driver',
  InvitationKind.operatorAdmin: 'operatorAdmin',
};
