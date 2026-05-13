// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PendingActionImpl _$$PendingActionImplFromJson(Map<String, dynamic> json) =>
    _$PendingActionImpl(
      id: json['id'] as String,
      kind: $enumDecode(_$PendingActionKindEnumMap, json['kind']),
      payload:
          json['payload'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      createdAt: DateTime.parse(json['createdAt'] as String),
      attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      lastError: json['lastError'] as String?,
    );

Map<String, dynamic> _$$PendingActionImplToJson(_$PendingActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kind': _$PendingActionKindEnumMap[instance.kind]!,
      'payload': instance.payload,
      'createdAt': instance.createdAt.toIso8601String(),
      'attempts': instance.attempts,
      if (instance.lastError case final value?) 'lastError': value,
    };

const _$PendingActionKindEnumMap = {
  PendingActionKind.createIncident: 'createIncident',
  PendingActionKind.createRouteFeedback: 'createRouteFeedback',
  PendingActionKind.createRouteSuggestion: 'createRouteSuggestion',
  PendingActionKind.createFeatureRequest: 'createFeatureRequest',
  PendingActionKind.createCommunityRoute: 'createCommunityRoute',
  PendingActionKind.updateUserPrefs: 'updateUserPrefs',
  PendingActionKind.submitOfficialRequest: 'submitOfficialRequest',
  PendingActionKind.claimInvitationCode: 'claimInvitationCode',
  PendingActionKind.voteSuggestion: 'voteSuggestion',
  PendingActionKind.voteFeatureRequest: 'voteFeatureRequest',
  PendingActionKind.markFavorite: 'markFavorite',
  PendingActionKind.markNotificationRead: 'markNotificationRead',
};
