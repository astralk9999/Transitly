import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_message_model.freezed.dart';

@freezed
abstract class FeedbackMessageModel with _$FeedbackMessageModel {
  const FeedbackMessageModel._();

  const factory FeedbackMessageModel({
    required String id,
    required String feedbackId,
    required String userId,
    required String message,
    @Default(false) bool isFromManager,
    required DateTime createdAt,
  }) = _FeedbackMessageModel;

  static FeedbackMessageModel fromJson(Map<String, dynamic> j) =>
      FeedbackMessageModel(
        id: j['id'] as String,
        feedbackId: j['feedbackId'] as String,
        userId: j['userId'] as String,
        message: j['message'] as String,
        isFromManager: j['isFromManager'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
