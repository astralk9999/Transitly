import 'enums.dart';

class RouteChangelogModel {
  const RouteChangelogModel({
    required this.id,
    required this.routeId,
    required this.changeType,
    required this.description,
    required this.changedBy,
    required this.createdAt,
  });

  final String id;
  final String routeId;
  final ChangeType changeType;
  final String description;
  final String changedBy;
  final DateTime createdAt;

  factory RouteChangelogModel.fromJson(Map<String, dynamic> j) =>
      RouteChangelogModel(
        id: j['id'] as String,
        routeId: j['routeId'] as String,
        changeType: ChangeType.fromString(j['changeType'] as String),
        description: j['description'] as String,
        changedBy: j['changedBy'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
