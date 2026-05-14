import 'enums.dart';

class AchievementModel {
  const AchievementModel({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.category,
    required this.threshold,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final AchievementCategory category;
  final int threshold;

  factory AchievementModel.fromJson(Map<String, dynamic> j) =>
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
