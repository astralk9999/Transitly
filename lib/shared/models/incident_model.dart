import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'incident_model.freezed.dart';

@freezed
class IncidentModel with _$IncidentModel {
  const IncidentModel._();

  const factory IncidentModel({
    required String id,
    required String reporterId,
    required String routeId,
    String? stopId,
    required IncidentType incidentType,
    required IncidentCategory category,
    String? comment,
    required String status,
    @Default(0) int confirmations,
    required DateTime createdAt,
  }) = _IncidentModel;

  static IncidentModel fromJson(Map<String, dynamic> j) => IncidentModel(
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
        'delay' ||
        'noShow' ||
        'busFull' ||
        'dangerousDriving' =>
          IncidentCategory.service,
        'stopBlocked' ||
        'shelterDamaged' ||
        'signageMissing' =>
          IncidentCategory.infrastructure,
        'punctual' ||
        'driverKind' ||
        'stopClean' =>
          IncidentCategory.positive,
        _ => IncidentCategory.service,
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'reportedBy': reporterId,
        'lineCode': routeId,
        if (stopId != null) 'stopName': stopId,
        'type': incidentType.name,
        if (comment != null) 'description': comment,
        'status': status,
        'confirmations': confirmations,
        'reportedAt': createdAt.toIso8601String(),
      };
}
