import 'enums.dart';

class RouteFeedbackModel {
  const RouteFeedbackModel({
    required this.id,
    required this.userId,
    required this.routeId,
    this.stopId,
    required this.feedbackType,
    required this.description,
    this.photoUrls = const [],
    required this.status,
    this.autoPriority = Priority.medium,
    this.similarFeedbackCount = 0,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String routeId;
  final String? stopId;
  final FeedbackType feedbackType;
  final String description;
  final List<String> photoUrls;
  final FeedbackStatus status;
  final Priority autoPriority;
  final int similarFeedbackCount;
  final DateTime createdAt;

  factory RouteFeedbackModel.fromJson(Map<String, dynamic> j) =>
      RouteFeedbackModel(
        id: j['id'] as String,
        userId: j['reportedBy'] as String? ?? '',
        routeId: j['lineCode'] as String,
        stopId: j['stopName'] as String?,
        feedbackType: FeedbackType.fromString(j['type'] as String),
        description: j['description'] as String,
        status: FeedbackStatus.fromString(j['status'] as String),
        autoPriority: Priority.fromString(j['priority'] as String? ?? 'medium'),
        createdAt: DateTime.parse(j['reportedAt'] as String),
      );
}
