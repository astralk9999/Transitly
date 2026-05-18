import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'route_suggestion_model.freezed.dart';

@freezed
abstract class RouteSuggestionModel with _$RouteSuggestionModel {
  const RouteSuggestionModel._();

  const factory RouteSuggestionModel({
    required String id,
    required String suggestedBy,
    required String originText,
    double? originLat,
    double? originLng,
    required String destinationText,
    double? destinationLat,
    double? destinationLng,
    String? routeCode,
    String? operatorName,
    ServiceType? serviceType,
    String? detailLevel,
    String? source,
    String? notes,
    required SuggestionStatus status,
    @Default(0) int voteCount,
    @Default(0) int contributionCount,
    @Default(Priority.medium) Priority priority,
    required DateTime createdAt,
  }) = _RouteSuggestionModel;

  static RouteSuggestionModel fromJson(Map<String, dynamic> j) {
    final title = j['title'] as String? ?? '';
    final parts = title.split(' - ');
    return RouteSuggestionModel(
      id: j['id'] as String,
      suggestedBy: j['proposedBy'] as String? ?? '',
      originText: parts.isNotEmpty ? parts.first : '',
      destinationText: parts.length > 1 ? parts.last : '',
      notes: j['description'] as String?,
      status: SuggestionStatus.fromString(j['status'] as String),
      voteCount: j['votes'] as int? ?? 0,
      contributionCount: j['contributions'] as int? ?? 0,
      createdAt: DateTime.parse(j['proposedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'proposedBy': suggestedBy,
        'title': '$originText - $destinationText',
        if (notes != null) 'description': notes,
        if (routeCode != null) 'routeCode': routeCode,
        if (operatorName != null) 'operatorName': operatorName,
        if (serviceType != null) 'serviceType': serviceType!.name,
        'status': status.name,
        'votes': voteCount,
        'contributions': contributionCount,
        'priority': priority.name,
        'proposedAt': createdAt.toIso8601String(),
      };
}
