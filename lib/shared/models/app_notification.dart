import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

enum AppNotificationType {
  incidentResolved,
  routePromoted,
  shareReceived,
  featureRequestReplied,
  busApproachingFavorite,
  custom,
}

/// Notificación in-app dirigida a un usuario. F21 la conecta con FCM
/// para entrega push y con un inbox dentro de la app.
@freezed
class AppNotification with _$AppNotification {
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
