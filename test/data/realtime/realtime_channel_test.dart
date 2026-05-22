import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/sync/realtime_channel_manager.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://test.supabase.co', 'anon-key');
  });

  group('RealtimeChannelManager additional', () {
    test('watch creates unique streams for different tables', () {
      final mgr = RealtimeChannelManager(client);

      final s1 = mgr.watch(
        channelPrefix: 'p',
        table: 'routes',
        entityId: 'r-1',
        events: [PostgresChangeEvent.update],
      );
      final s2 = mgr.watch(
        channelPrefix: 'p',
        table: 'stops',
        entityId: 'r-1',
        events: [PostgresChangeEvent.update],
      );

      expect(s1, isNot(same(s2)));
      mgr.dispose();
    });

    test('watch with multiple events returns a stream', () {
      final mgr = RealtimeChannelManager(client);

      final stream = mgr.watch(
        channelPrefix: 'multi',
        table: 'routes',
        entityId: 'multi-1',
        events: [
          PostgresChangeEvent.insert,
          PostgresChangeEvent.update,
          PostgresChangeEvent.delete,
        ],
      );

      expect(stream, isA<Stream<Map<String, dynamic>>>());
      mgr.dispose();
    });

    test('dispose clears all entries and can be called multiple times', () {
      final mgr = RealtimeChannelManager(client);

      mgr.watch(
        channelPrefix: 'd',
        table: 'routes',
        entityId: 'd-1',
        events: [PostgresChangeEvent.insert],
      );
      mgr.watch(
        channelPrefix: 'd',
        table: 'stops',
        entityId: 'd-2',
        events: [PostgresChangeEvent.insert],
      );

      mgr.dispose();
      expect(mgr.dispose, returnsNormally);
      expect(mgr.dispose, returnsNormally);
    });
  });
}
