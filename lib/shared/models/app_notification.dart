import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum AppNotificationType {
  incidentResolved,
  routePromoted,
  shareReceived,
  featureRequestReplied,
  busApproachingFavorite,
  xpEarned,
  rankUp,
  custom;

  /// Parsea desde el valor crudo de Postgres (snake_case). Acepta
  /// también camelCase por compatibilidad con código antiguo. Si el
  /// valor es desconocido devuelve [custom] para no romper la UI.
  static AppNotificationType fromDbName(String? raw) {
    if (raw == null) return custom;
    return switch (raw) {
      'incident_resolved' || 'incidentResolved' => incidentResolved,
      'route_promoted' || 'routePromoted' => routePromoted,
      'share_received' || 'shareReceived' => shareReceived,
      'feature_request_replied' || 'featureRequestReplied' =>
        featureRequestReplied,
      'bus_approaching_favorite' || 'busApproachingFavorite' =>
        busApproachingFavorite,
      'xp_earned' || 'xpEarned' => xpEarned,
      'rank_up' || 'rankUp' => rankUp,
      _ => custom,
    };
  }
}

/// Notificación in-app dirigida a un usuario. F21 la conecta con FCM
/// para entrega push y con un inbox dentro de la app.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required String id,
    required String userId,
    required AppNotificationType type,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    @Default(false) bool read,
    required DateTime createdAt,
  }) = _AppNotification;

  /// Parser tolerante. Acepta:
  ///   - El JSON canónico de Hive (camelCase, generado por
  ///     [_$AppNotificationFromJson]).
  ///   - Filas Supabase (snake_case en el campo `type`).
  ///   - Tipos desconocidos: los degrada a [AppNotificationType.custom]
  ///     en lugar de lanzar — antes una notif cacheada con un tipo que
  ///     ya no existía rompía Hive.openBox en el siguiente arranque.
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    if (rawType is String) {
      return AppNotification(
        id: json['id'] as String,
        userId: (json['userId'] ?? json['user_id']) as String,
        type: AppNotificationType.fromDbName(rawType),
        payload: json['payload'] is Map
            ? Map<String, dynamic>.from(json['payload'] as Map)
            : const <String, dynamic>{},
        read: json['read'] as bool? ?? false,
        createdAt: json['createdAt'] is String
            ? DateTime.parse(json['createdAt'] as String)
            : json['created_at'] is String
                ? DateTime.parse(json['created_at'] as String)
                : DateTime.now(),
      );
    }
    return _$AppNotificationFromJson(json);
  }
}
