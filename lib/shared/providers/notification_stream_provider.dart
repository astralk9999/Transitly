import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../data/notification/notification_repository_provider.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../models/app_notification.dart';

const _logTag = 'Provider:NotificationStream';

/// Stream of [AppNotification] objects for the currently authenticated
/// user, delivered via Supabase Realtime.
///
/// When the user is not authenticated the stream emits an empty list and
/// does not open a Realtime channel.
// autoDispose: el canal Supabase Realtime se cierra cuando ninguna
// pantalla observa el provider (el ref.onDispose de abajo se dispara).
final notificationStreamProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;

  if (userId == null) {
    return const Stream.empty();
  }

  final repo = ref.watch(notificationRepositoryProvider);

  final controller = StreamController<List<AppNotification>>();

  repo.forUser(userId).then((notifications) {
    if (!controller.isClosed) controller.add(notifications);
  }).catchError((Object e) {
    AppLogger.warn(_logTag, 'initial fetch failed', e);
  });

  final channel = client
      .channel('notifications-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          AppLogger.debug(
              _logTag, 'realtime insert (id=${payload.newRecord['id']})');
          repo.forUser(userId).then((notifications) {
            if (!controller.isClosed) controller.add(notifications);
          }).catchError((Object e) {
            AppLogger.warn(_logTag, 'refresh after insert failed', e);
          });
        },
      )
      .subscribe();

  ref.onDispose(() {
    channel.unsubscribe();
    controller.close();
  });

  return controller.stream;
});

/// Derived count of unread notifications from the stream.
final unreadCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationStreamProvider).valueOrNull;
  if (notifications == null) return 0;
  return notifications.where((n) => !n.read).length;
});
