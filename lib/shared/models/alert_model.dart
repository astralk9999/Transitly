import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'alert_model.freezed.dart';

@freezed
abstract class AlertModel with _$AlertModel {
  const AlertModel._();

  const factory AlertModel({
    required String id,
    required String operatorId,
    String? routeId,
    required AlertSeverity severity,
    required String title,
    required String body,
    DateTime? activeFrom,
    DateTime? activeUntil,
  }) = _AlertModel;

  static AlertModel fromJson(Map<String, dynamic> j) => AlertModel(
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

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        if (routeId != null) 'lineCode': routeId,
        'type': severity.name,
        'title': title,
        'description': body,
        if (activeFrom != null) 'startDate': activeFrom!.toIso8601String(),
        if (activeUntil != null) 'endDate': activeUntil!.toIso8601String(),
      };
}
