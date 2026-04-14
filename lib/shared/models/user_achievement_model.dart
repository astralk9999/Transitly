class UserAchievementModel {
  const UserAchievementModel({
    required this.achievementId,
    required this.progress,
    required this.unlocked,
    this.unlockedAt,
  });

  final String achievementId;
  final int progress;
  final bool unlocked;
  final DateTime? unlockedAt;

  factory UserAchievementModel.fromJson(Map<String, dynamic> j) =>
      UserAchievementModel(
        achievementId: j['id'] as String,
        progress: j['userProgress'] as int? ?? 0,
        unlocked: j['earned'] as bool? ?? false,
        unlockedAt: j['earnedAt'] != null
            ? DateTime.tryParse(j['earnedAt'] as String)
            : null,
      );
}
