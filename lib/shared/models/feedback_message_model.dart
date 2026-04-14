class FeedbackMessageModel {
  const FeedbackMessageModel({
    required this.id,
    required this.feedbackId,
    required this.userId,
    required this.message,
    this.isFromManager = false,
    required this.createdAt,
  });

  final String id;
  final String feedbackId;
  final String userId;
  final String message;
  final bool isFromManager;
  final DateTime createdAt;

  factory FeedbackMessageModel.fromJson(Map<String, dynamic> j) =>
      FeedbackMessageModel(
        id: j['id'] as String,
        feedbackId: j['feedbackId'] as String,
        userId: j['userId'] as String,
        message: j['message'] as String,
        isFromManager: j['isFromManager'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
