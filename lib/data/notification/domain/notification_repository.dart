import '../../../shared/models/app_notification.dart';

enum NotificationRepositoryError {
  notFound,
  network,
  parse,
  denied,
  unknown,
}

class NotificationRepositoryException implements Exception {
  const NotificationRepositoryException({
    required this.error,
    required this.message,
    this.cause,
    this.stackTrace,
  });

  final NotificationRepositoryError error;
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() {
    final base =
        'NotificationRepositoryException(${error.name}): $message';
    return cause == null ? base : '$base — caused by: $cause';
  }
}

/// Notificaciones in-app del usuario. Las notificaciones las genera
/// el servidor (triggers, Edge Functions); el cliente solo lee y
/// marca como leídas.
///
/// F21 conecta el stream a Supabase Realtime + FCM.
abstract class NotificationRepository {
  Future<List<AppNotification>> forUser(String userId);

  Future<void> markRead(String notificationId);

  /// Marca como leídas TODAS las del usuario en una sola operación.
  Future<void> markAllRead();

  Future<int> unreadCount(String userId);
}
