import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'achievement_model.freezed.dart';

@freezed
abstract class AchievementModel with _$AchievementModel {
  const AchievementModel._();

  const factory AchievementModel({
    required String id,
    required String code,
    required String name,
    required String description,
    required String icon,
    required AchievementCategory category,
    required int threshold,
  }) = _AchievementModel;

  static AchievementModel fromJson(Map<String, dynamic> j) =>
      AchievementModel(
        id: (j['code'] ?? j['id']) as String,
        code: (j['code'] ?? j['id']) as String,
        name: j['name'] as String,
        description: j['description'] as String,
        icon: j['icon'] as String? ?? 'award',
        category:
            AchievementCategory.fromString(j['category'] as String? ?? 'usage'),
        threshold: (j['threshold'] ?? j['requirement']) as int? ?? 1,
      );
}
