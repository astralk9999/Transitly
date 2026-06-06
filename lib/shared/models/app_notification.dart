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

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);
}
