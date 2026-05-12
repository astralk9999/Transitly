import 'package:hive/hive.dart';

import '../../../shared/models/app_notification.dart';
import '../domain/notification_repository.dart';

/// Cache local de notificaciones sobre Hive. Convención de clave:
/// `notif:<userId>:<notificationId>`.
class NotificationLocalRepository implements NotificationRepository {
  NotificationLocalRepository(this._box);

  final Box<AppNotification> _box;

  static String _key(String userId, String notificationId) =>
      'notif:$userId:$notificationId';

  @override
  Future<List<AppNotification>> forUser(String userId) async {
    final prefix = 'notif:$userId:';
    final result = <AppNotification>[];
    final map = _box.toMap();
    for (final entry in map.entries) {
      if ((entry.key as String).startsWith(prefix)) {
        result.add(entry.value);
      }
    }
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  @override
  Future<void> markRead(String notificationId) async {
    final map = _box.toMap();
    for (final entry in map.entries) {
      if ((entry.key as String).endsWith(':$notificationId')) {
        await _box.put(entry.key, entry.value.copyWith(read: true));
        return;
      }
    }
  }

  @override
  Future<int> unreadCount(String userId) async {
    final prefix = 'notif:$userId:';
    final map = _box.toMap();
    return map.values
        .where((n) => !n.read)
        .where((n) {
          for (final e in map.entries) {
            if (e.value == n && (e.key as String).startsWith(prefix)) {
              return true;
            }
          }
          return false;
        })
        .length;
  }

  Future<void> upsert(AppNotification notification) async {
    await _box.put(
      _key(notification.userId, notification.id),
      notification,
    );
  }

  Future<void> upsertAll(Iterable<AppNotification> notifications) async {
    final entries = <String, AppNotification>{
      for (final n in notifications) _key(n.userId, n.id): n,
    };
    await _box.putAll(entries);
  }

  Future<void> deleteByUserId(String userId) async {
    final prefix = 'notif:$userId:';
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      if ((key as String).startsWith(prefix)) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }
}
