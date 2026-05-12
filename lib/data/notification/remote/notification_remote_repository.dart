import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/app_notification.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/notification_repository.dart';

class NotificationRemoteRepository implements NotificationRepository {
  NotificationRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:Notification:Remote';

  @override
  Future<List<AppNotification>> forUser(String userId) async {
    try {
      final rows = await _client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      return rows.map(_fromRow).toList();
    } catch (e, st) {
      throw _mapError(e, st, 'forUser($userId)');
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update(<String, dynamic>{'read': true})
          .eq('id', notificationId);
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'markRead($notificationId)');
    } catch (e) {
      AppLogger.warn(_logTag, 'markRead network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: 'mark-read-$notificationId',
          kind: PendingActionKind.markNotificationRead,
          payload: <String, dynamic>{'id': notificationId},
          createdAt: DateTime.now().toUtc(),
        ),
      );
    }
  }

  @override
  Future<int> unreadCount(String userId) async {
    try {
      final result = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', userId)
          .eq('read', false);

      return result.length;
    } catch (e) {
      AppLogger.warn(_logTag, 'unreadCount failed, returning 0', e);
      return 0;
    }
  }

  AppNotification _fromRow(Map<String, dynamic> row) {
    return AppNotification(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      type: AppNotificationType.values.firstWhere(
        (t) => t.name == row['type'],
        orElse: () => AppNotificationType.custom,
      ),
      payload: row['payload'] != null
          ? Map<String, dynamic>.from(row['payload'] as Map)
          : const <String, dynamic>{},
      read: row['read'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  NotificationRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == '42501') {
        return NotificationRepositoryException(
          error: NotificationRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return NotificationRepositoryException(
        error: NotificationRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return NotificationRepositoryException(
      error: NotificationRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
