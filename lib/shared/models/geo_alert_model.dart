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
    double? centerLat,
    double? centerLng,
    int? radiusM,
    @Default(true) bool active,
    String? createdBy,
    DateTime? createdAt,
    DateTime? expiresAt,
    @Default(<String>[]) List<String> affectedRouteIds,
    @Default(false) bool isGlobal,
    String? targetRole,
    DateTime? scheduledAt,
    String? actionUrl,
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
        centerLat: (j['center_lat'] as num?)?.toDouble(),
        centerLng: (j['center_lng'] as num?)?.toDouble(),
        radiusM: (j['radius_m'] as num?)?.toInt(),
        active: j['active'] as bool? ?? true,
        createdBy: j['created_by'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
        expiresAt: j['expires_at'] != null
            ? DateTime.tryParse(j['expires_at'] as String)
            : null,
        affectedRouteIds: (j['affected_route_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const <String>[],
        isGlobal: j['is_global'] as bool? ?? false,
        targetRole: j['target_role'] as String?,
        scheduledAt: j['scheduled_at'] != null
            ? DateTime.tryParse(j['scheduled_at'] as String)
            : null,
        actionUrl: j['action_url'] as String?,
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
        'affected_route_ids': affectedRouteIds,
        'is_global': isGlobal,
        if (targetRole != null) 'target_role': targetRole,
        if (scheduledAt != null)
          'scheduled_at': scheduledAt!.toIso8601String(),
        if (actionUrl != null) 'action_url': actionUrl,
        if (expiresAt != null) 'expires_at': expiresAt!.toIso8601String(),
      };
}
