import 'enums.dart';

class RouteSuggestionModel {
  const RouteSuggestionModel({
    required this.id,
    required this.suggestedBy,
    required this.originText,
    this.originLat,
    this.originLng,
    required this.destinationText,
    this.destinationLat,
    this.destinationLng,
    this.routeCode,
    this.operatorName,
    this.serviceType,
    this.detailLevel,
    this.source,
    this.notes,
    required this.status,
    this.voteCount = 0,
    this.contributionCount = 0,
    this.priority = Priority.medium,
    required this.createdAt,
  });

  final String id;
  final String suggestedBy;
  final String originText;
  final double? originLat;
  final double? originLng;
  final String destinationText;
  final double? destinationLat;
  final double? destinationLng;
  final String? routeCode;
  final String? operatorName;
  final ServiceType? serviceType;
  final String? detailLevel;
  final String? source;
  final String? notes;
  final SuggestionStatus status;
  final int voteCount;
  final int contributionCount;
  final Priority priority;
  final DateTime createdAt;

  factory RouteSuggestionModel.fromJson(Map<String, dynamic> j) {
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
}
