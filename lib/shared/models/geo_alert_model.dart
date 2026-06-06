import 'package:freezed_annotation/freezed_annotation.dart';

part 'geo_alert_model.freezed.dart';

/// Sub P2-#55: aviso geolocalizado creado por admin.
enum GeoAlertSeverity { info, warning, critical }

@freezed
abstract class GeoAlertModel with _$GeoAlertModel {
  const GeoAlertModel._();

  const factory GeoAlertModel({
    required String id,
    required String title,
    required String body,
    @Default(GeoAlertSeverity.info) GeoAlertSeverity severity,
    required double centerLat,
    required double centerLng,
    required int radiusM,
    @Default(true) bool active,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) = _GeoAlertModel;

  static GeoAlertModel fromJson(Map<String, dynamic> j) => GeoAlertModel(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        severity: switch (j['severity'] as String?) {
          'warning' => GeoAlertSeverity.warning,
          'critical' => GeoAlertSeverity.critical,
          _ => GeoAlertSeverity.info,
        },
        centerLat: (j['center_lat'] as num).toDouble(),
        centerLng: (j['center_lng'] as num).toDouble(),
        radiusM: (j['radius_m'] as num).toInt(),
        active: j['active'] as bool? ?? true,
        createdBy: j['created_by'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        expiresAt: j['expires_at'] != null
            ? DateTime.tryParse(j['expires_at'] as String)
            : null,
      );

  Map<String, dynamic> toInsertJson(String createdByUserId) => {
        'title': title,
        'body': body,
        'severity': severity.name,
        'center_lat': centerLat,
        'center_lng': centerLng,
        'radius_m': radiusM,
        'active': active,
        'created_by': createdByUserId,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
