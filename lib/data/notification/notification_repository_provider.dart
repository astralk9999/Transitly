import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/app_notification.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/notification_repository.dart';
import 'local/notification_local_repository.dart';
import 'local/notification_mock_repository.dart';
import 'remote/notification_remote_repository.dart';

class NotificationRepositorySwr implements NotificationRepository {
  NotificationRepositorySwr({required this.local, required this.remote});

  final NotificationLocalRepository local;
  final NotificationRemoteRepository remote;

  static const _logTag = 'Repo:Notification';

  @override
  Future<List<AppNotification>> forUser(String userId) async {
    final cached = await local.forUser(userId);
    if (cached.isNotEmpty) {
      unawaited(_refreshForUser(userId));
      return cached;
    }
    try {
      final fresh = await remote.forUser(userId);
      await local.upsertAll(fresh);
      return fresh;
    } on NotificationRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'forUser remote failed with empty cache', e);
      return cached;
    }
  }

  Future<void> _refreshForUser(String userId) async {
    try {
      final fresh = await remote.forUser(userId);
      await local.upsertAll(fresh);
    } on NotificationRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh forUser($userId)', e);
    }
  }

  @override
  Future<void> markRead(String notificationId) async {
    await local.markRead(notificationId);
    unawaited(_pushMarkRead(notificationId));
  }

  Future<void> _pushMarkRead(String notificationId) async {
    try {
      await remote.markRead(notificationId);
    } on NotificationRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background push markRead($notificationId)', e);
    }
  }

  @override
  Future<int> unreadCount(String userId) async {
    try {
      return await remote.unreadCount(userId);
    } catch (e) {
      return local.unreadCount(userId);
    }
  }
}

final notificationRepositoryProvider =
    Provider.autoDispose<NotificationRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return NotificationMockRepository();
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(notificationsBoxProvider);
  final remote = NotificationRemoteRepository(
    client: client,
    queue: queue,
  );

  final sync = ref.read(offlineSyncServiceProvider);
  sync.registerExecutor(
    PendingActionKind.markNotificationRead,
    (payload) async {
      await client
          .from('notifications')
          .update(<String, dynamic>{'read': true})
          .eq('id', payload['id'] as String);
    },
  );

  return NotificationRepositorySwr(
    local: NotificationLocalRepository(box),
    remote: remote,
  );
});
