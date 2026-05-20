import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_achievement_model.freezed.dart';

@freezed
abstract class UserAchievementModel with _$UserAchievementModel {
  const UserAchievementModel._();

  const factory UserAchievementModel({
    required String achievementId,
    required int progress,
    required bool unlocked,
    DateTime? unlockedAt,
  }) = _UserAchievementModel;

  static UserAchievementModel fromJson(Map<String, dynamic> j) =>
      UserAchievementModel(
        achievementId: j['id'] as String,
        progress: j['userProgress'] as int? ?? 0,
        unlocked: j['earned'] as bool? ?? false,
        unlockedAt: j['earnedAt'] != null
            ? DateTime.tryParse(j['earnedAt'] as String)
            : null,
      );
}
