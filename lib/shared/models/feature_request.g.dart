// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feature_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeatureRequestImpl _$$FeatureRequestImplFromJson(Map<String, dynamic> json) =>
    _$FeatureRequestImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      submittedBy: json['submittedBy'] as String,
      category: $enumDecode(_$FeatureRequestCategoryEnumMap, json['category']),
      priority:
          $enumDecodeNullable(
            _$FeatureRequestPriorityEnumMap,
            json['priority'],
          ) ??
          FeatureRequestPriority.normal,
      status:
          $enumDecodeNullable(_$FeatureRequestStatusEnumMap, json['status']) ??
          FeatureRequestStatus.open,
      votes: (json['votes'] as num?)?.toInt() ?? 0,
      payload: json['payload'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      adminNotes: json['adminNotes'] as String?,
      assigneeId: json['assigneeId'] as String?,
    );

Map<String, dynamic> _$$FeatureRequestImplToJson(
  _$FeatureRequestImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'submittedBy': instance.submittedBy,
  'category': _$FeatureRequestCategoryEnumMap[instance.category]!,
  'priority': _$FeatureRequestPriorityEnumMap[instance.priority]!,
  'status': _$FeatureRequestStatusEnumMap[instance.status]!,
  'votes': instance.votes,
  if (instance.payload case final value?) 'payload': value,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  if (instance.adminNotes case final value?) 'adminNotes': value,
  if (instance.assigneeId case final value?) 'assigneeId': value,
};

const _$FeatureRequestCategoryEnumMap = {
  FeatureRequestCategory.newRoute: 'newRoute',
  FeatureRequestCategory.routeOfficial: 'routeOfficial',
  FeatureRequestCategory.appFeature: 'appFeature',
  FeatureRequestCategory.dataCorrection: 'dataCorrection',
  FeatureRequestCategory.other: 'other',
};

const _$FeatureRequestPriorityEnumMap = {
  FeatureRequestPriority.low: 'low',
  FeatureRequestPriority.normal: 'normal',
  FeatureRequestPriority.high: 'high',
};

const _$FeatureRequestStatusEnumMap = {
  FeatureRequestStatus.open: 'open',
  FeatureRequestStatus.inReview: 'inReview',
  FeatureRequestStatus.accepted: 'accepted',
  FeatureRequestStatus.rejected: 'rejected',
  FeatureRequestStatus.scheduled: 'scheduled',
  FeatureRequestStatus.done: 'done',
};
