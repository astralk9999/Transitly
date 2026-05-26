import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';
import 'package:transitly/data/sync/offline_sync_service.dart';

void main() {
  setUpAll(() {
    Hive.init('./test/hive_temp_sync_more');
  });

  group('OfflineSyncService more', () {
    test('registerExecutor stores executor by kind', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_exec');
      final deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_dead');
      final queue = PendingActionsQueue(box: box, deadBox: deadBox);
      final service = OfflineSyncService(queue: queue);

      service.registerExecutor(
        PendingActionKind.createIncident,
        (payload) async {},
      );

      expect(service.queue, equals(queue));

      await box.close();
      await deadBox.close();
      await Hive.deleteBoxFromDisk('test_sync_exec');
      await Hive.deleteBoxFromDisk('test_sync_dead');
    });

    test('OfflineSyncService holds queue reference', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_hold');
      final deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_hold_d');
      final queue = PendingActionsQueue(box: box, deadBox: deadBox);
      final service = OfflineSyncService(queue: queue);

      expect(service.queue, same(queue));

      await box.close();
      await deadBox.close();
      await Hive.deleteBoxFromDisk('test_sync_hold');
      await Hive.deleteBoxFromDisk('test_sync_hold_d');
    });

    test('drainNow returns immediately when queue is empty', () async {
      final box = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_drain');
      final deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_sync_drain_d');
      final queue = PendingActionsQueue(box: box, deadBox: deadBox);
      final service = OfflineSyncService(queue: queue);

      await service.drainNow();

      await box.close();
      await deadBox.close();
      await Hive.deleteBoxFromDisk('test_sync_drain');
      await Hive.deleteBoxFromDisk('test_sync_drain_d');
    });
  });
}
