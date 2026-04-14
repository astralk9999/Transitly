import 'enums.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.operatorId,
    this.routeId,
    required this.severity,
    required this.title,
    required this.body,
    this.activeFrom,
    this.activeUntil,
  });

  final String id;
  final String operatorId;
  final String? routeId;
  final AlertSeverity severity;
  final String title;
  final String body;
  final DateTime? activeFrom;
  final DateTime? activeUntil;

  factory AlertModel.fromJson(Map<String, dynamic> j) => AlertModel(
        id: j['id'] as String,
        operatorId: 'comujesa',
        routeId: j['lineCode'] as String?,
        severity: AlertSeverity.fromString(j['type'] as String),
        title: j['title'] as String,
        body: j['description'] as String,
        activeFrom: j['startDate'] != null
            ? DateTime.tryParse(j['startDate'] as String)
            : null,
        activeUntil: j['endDate'] != null
            ? DateTime.tryParse(j['endDate'] as String)
            : null,
      );
}
