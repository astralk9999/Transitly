import '../../../shared/models/app_notification.dart';
import '../domain/notification_repository.dart';

/// Mock repo para modo invitado. Las notificaciones requieren cuenta
/// real (las genera el servidor por trigger). En modo invitado,
/// devolvemos lista vacía.
class NotificationMockRepository implements NotificationRepository {
  final List<AppNotification> _ephemeral = <AppNotification>[];

  @override
  Future<List<AppNotification>> forUser(String userId) async =>
      _ephemeral.toList(growable: false);

  @override
  Future<void> markRead(String notificationId) async {
    final idx = _ephemeral.indexWhere((n) => n.id == notificationId);
    if (idx >= 0) {
      _ephemeral[idx] = _ephemeral[idx].copyWith(read: true);
    }
  }

  @override
  Future<void> markAllRead() async {
    for (var i = 0; i < _ephemeral.length; i++) {
      if (!_ephemeral[i].read) {
        _ephemeral[i] = _ephemeral[i].copyWith(read: true);
      }
    }
  }

  @override
  Future<int> unreadCount(String userId) async =>
      _ephemeral.where((n) => !n.read).length;
}
