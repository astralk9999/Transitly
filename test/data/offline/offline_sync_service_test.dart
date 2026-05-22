import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/sync/offline_sync_service.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';

void main() {
  late PendingActionsQueue queue;
  late OfflineSyncService service;

  setUp(() async {
    Hive.init('./test/hive_temp_sync');
    final box =
        await Hive.openBox<Map<dynamic, dynamic>>('test_sync_main');
    final deadBox =
        await Hive.openBox<Map<dynamic, dynamic>>('test_sync_dead');
    queue = PendingActionsQueue(box: box, deadBox: deadBox);
    service = OfflineSyncService(queue: queue);
  });

  tearDown(() async {
    await queue.box.clear();
    await queue.deadBox.clear();
    await queue.box.close();
    await queue.deadBox.close();
    await Hive.deleteBoxFromDisk('test_sync_main');
    await Hive.deleteBoxFromDisk('test_sync_dead');
  });

  group('OfflineSyncService', () {
    test('registerExecutor accepts an executor for a kind', () {
      var called = false;
      service.registerExecutor(
        PendingActionKind.createIncident,
        (payload) async {
          called = true;
        },
      );
      expect(called, isFalse);
    });

    test('drainNow completes without error when queue is empty', () async {
      await expectLater(service.drainNow(), completes);
    });

    test('drainNow processes enqueued action when executor registered',
        () async {
      final completer = Completer<void>();
      service.registerExecutor(
        PendingActionKind.markFavorite,
        (payload) async {
          expect(payload['routeId'], 'L1');
          completer.complete();
        },
      );

      final action = PendingAction(
        id: 'sync-1',
        kind: PendingActionKind.markFavorite,
        payload: {'routeId': 'L1'},
        createdAt: DateTime.now().toUtc(),
      );
      await queue.enqueue(action);

      await service.drainNow();
      await completer.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () => fail('Executor was not called'),
      );
    });
  });
}
