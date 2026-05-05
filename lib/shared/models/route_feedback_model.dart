import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'route_feedback_model.freezed.dart';

@freezed
class RouteFeedbackModel with _$RouteFeedbackModel {
  const RouteFeedbackModel._();

  const factory RouteFeedbackModel({
    required String id,
    required String userId,
    required String routeId,
    String? stopId,
    required FeedbackType feedbackType,
    required String description,
    @Default(<String>[]) List<String> photoUrls,
    required FeedbackStatus status,
    @Default(Priority.medium) Priority autoPriority,
    @Default(0) int similarFeedbackCount,
    required DateTime createdAt,
  }) = _RouteFeedbackModel;

  static RouteFeedbackModel fromJson(Map<String, dynamic> j) =>
      RouteFeedbackModel(
        id: j['id'] as String,
        userId: j['reportedBy'] as String? ?? '',
        routeId: j['lineCode'] as String,
        stopId: j['stopName'] as String?,
        feedbackType: FeedbackType.fromString(j['type'] as String),
        description: j['description'] as String,
        status: FeedbackStatus.fromString(j['status'] as String),
        autoPriority:
            Priority.fromString(j['priority'] as String? ?? 'medium'),
        createdAt: DateTime.parse(j['reportedAt'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'reportedBy': userId,
        'lineCode': routeId,
        if (stopId != null) 'stopName': stopId,
        'type': feedbackType.name,
        'description': description,
        if (photoUrls.isNotEmpty) 'photoUrls': photoUrls,
        'status': status.name,
        'priority': autoPriority.name,
        'reportedAt': createdAt.toIso8601String(),
      };
}
