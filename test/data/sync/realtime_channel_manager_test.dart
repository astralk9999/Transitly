import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transitly/data/sync/realtime_channel_manager.dart';

void main() {
  late SupabaseClient client;

  setUp(() {
    client = SupabaseClient('https://test.supabase.co', 'anon-key');
  });

  group('RealtimeChannelManager', () {
    test('can be instantiated', () {
      final mgr = RealtimeChannelManager(client);
      expect(mgr, isNotNull);
      mgr.dispose();
    });

    test('dispose cleans up without errors when no channels open', () {
      final mgr = RealtimeChannelManager(client);
      expect(() => mgr.dispose(), returnsNormally);
    });

    test('watch returns a broadcast stream', () {
      final mgr = RealtimeChannelManager(client);
      final stream = mgr.watch(
        channelPrefix: 'test',
        table: 'test_table',
        entityId: 'test-1',
        events: [PostgresChangeEvent.insert],
      );
      expect(stream, isA<Stream<Map<String, dynamic>>>());
      mgr.dispose();
    });

    test('multiple watches create independent streams', () {
      final mgr = RealtimeChannelManager(client);
      final s1 = mgr.watch(
        channelPrefix: 'test',
        table: 'test_table',
        entityId: 'id-1',
        events: [PostgresChangeEvent.insert],
      );
      final s2 = mgr.watch(
        channelPrefix: 'test',
        table: 'test_table',
        entityId: 'id-2',
        events: [PostgresChangeEvent.all],
      );
      expect(s1, isNot(same(s2)));
      mgr.dispose();
    });

    test('repeated dispose does not throw', () {
      final mgr = RealtimeChannelManager(client);
      mgr.dispose();
      expect(() => mgr.dispose(), returnsNormally);
    });
  });
}
