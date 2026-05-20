import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';

const _logTag = 'ChannelMgr';

/// Channel manager genérico con multiplexación, reconexión con backoff
/// exponencial + jitter. Usado por stop, route y futuros repos.
class RealtimeChannelManager {
  RealtimeChannelManager(this._client);

  final SupabaseClient _client;
  final Map<String, _ChannelEntry> _entries = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  Stream<Map<String, dynamic>> watch({
    required String channelPrefix,
    required String table,
    required String entityId,
    required List<PostgresChangeEvent> events,
  }) {
    final controller = StreamController<Map<String, dynamic>>();
    final key = '$channelPrefix-$entityId';

    _entries[key] = _ChannelEntry(controller: controller);

    _openChannel(
      channelPrefix: channelPrefix,
      table: table,
      entityId: entityId,
      events: events,
      controller: controller,
    );

    controller.onCancel = () {
      _entries.remove(key)?.channel.unsubscribe();
    };

    return controller.stream;
  }

  void _openChannel({
    required String channelPrefix,
    required String table,
    required String entityId,
    required List<PostgresChangeEvent> events,
    required StreamController<Map<String, dynamic>> controller,
  }) {
    final key = '$channelPrefix-$entityId';
    final channelName = '$channelPrefix-$entityId';

    var builder = _client.channel(channelName);
    for (final event in events) {
      builder = builder.onPostgresChanges(
        event: event,
        schema: 'public',
        table: table,
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: entityId,
        ),
        callback: (payload) {
          if (!controller.isClosed) {
            controller.add(payload.newRecord);
          }
        },
      );
    }

    final channel = builder.subscribe((status, _) {
      if (status == RealtimeSubscribeStatus.closed && !controller.isClosed) {
        _scheduleReconnect(
          channelPrefix: channelPrefix,
          table: table,
          entityId: entityId,
          events: events,
          controller: controller,
        );
      }
    });

    _entries[key]?.channel = channel;
    AppLogger.debug(_logTag, '$channelName opened');
  }

  void _scheduleReconnect({
    required String channelPrefix,
    required String table,
    required String entityId,
    required List<PostgresChangeEvent> events,
    required StreamController<Map<String, dynamic>> controller,
  }) {
    final key = '$channelPrefix-$entityId';
    if (controller.isClosed || !_entries.containsKey(key)) return;

    final jitter = math.Random().nextInt(1000);
    final delay = math.min(
      (_reconnectAttempts + 1) * 2 * 1000 + jitter,
      30000,
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!controller.isClosed && _entries.containsKey(key)) {
        _openChannel(
          channelPrefix: channelPrefix,
          table: table,
          entityId: entityId,
          events: events,
          controller: controller,
        );
        _reconnectAttempts = 0;
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    for (final e in _entries.values) {
      e.channel.unsubscribe();
      e.controller.close();
    }
    _entries.clear();
    _reconnectAttempts = 0;
  }
}

class _ChannelEntry {
  _ChannelEntry({required this.controller});
  final StreamController<Map<String, dynamic>> controller;
  late RealtimeChannel channel;
}
