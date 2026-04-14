import 'enums.dart';

class IncidentModel {
  const IncidentModel({
    required this.id,
    required this.reporterId,
    required this.routeId,
    this.stopId,
    required this.incidentType,
    required this.category,
    this.comment,
    required this.status,
    this.confirmations = 0,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String routeId;
  final String? stopId;
  final IncidentType incidentType;
  final IncidentCategory category;
  final String? comment;
  final String status;
  final int confirmations;
  final DateTime createdAt;

  factory IncidentModel.fromJson(Map<String, dynamic> j) => IncidentModel(
        id: j['id'] as String,
        reporterId: j['reportedBy'] as String? ?? '',
        routeId: j['lineCode'] as String,
        stopId: j['stopName'] as String?,
        incidentType: IncidentType.fromString(j['type'] as String),
        category: _categoryFor(j['type'] as String),
        comment: j['description'] as String?,
        status: j['status'] as String? ?? 'pending',
        confirmations: j['confirmations'] as int? ?? 0,
        createdAt: DateTime.parse(j['reportedAt'] as String),
      );

  static IncidentCategory _categoryFor(String type) => switch (type) {
        'delay' || 'noShow' || 'busFull' || 'dangerousDriving' => IncidentCategory.service,
        'stopBlocked' || 'shelterDamaged' || 'signageMissing' => IncidentCategory.infrastructure,
        'punctual' || 'driverKind' || 'stopClean' => IncidentCategory.positive,
        _ => IncidentCategory.service,
      };
}
