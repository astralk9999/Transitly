import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'route_changelog_model.freezed.dart';

@freezed
abstract class RouteChangelogModel with _$RouteChangelogModel {
  const RouteChangelogModel._();

  const factory RouteChangelogModel({
    required String id,
    required String routeId,
    required ChangeType changeType,
    required String description,
    required String changedBy,
    required DateTime createdAt,
  }) = _RouteChangelogModel;

  static RouteChangelogModel fromJson(Map<String, dynamic> j) =>
      RouteChangelogModel(
        id: j['id'] as String,
        routeId: j['routeId'] as String,
        changeType: ChangeType.fromString(j['changeType'] as String),
        description: j['description'] as String,
        changedBy: j['changedBy'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
