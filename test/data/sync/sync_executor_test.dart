import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/sync/offline_sync_service.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';

void main() {
  late Box<Map<dynamic, dynamic>> box;
  late Box<Map<dynamic, dynamic>> deadBox;
  late PendingActionsQueue queue;
  late OfflineSyncService service;

  setUp(() async {
    Hive.init('./test/hive_temp_exec');
    box = await Hive.openBox<Map<dynamic, dynamic>>('test_exec_main');
    deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_exec_dead');
    queue = PendingActionsQueue(box: box, deadBox: deadBox);
    service = OfflineSyncService(queue: queue);
  });

  tearDown(() async {
    await box.close();
    await deadBox.close();
    await Hive.deleteBoxFromDisk('test_exec_main');
    await Hive.deleteBoxFromDisk('test_exec_dead');
  });

  test('drain empty queue completes', () async {
    await service.drainNow();
  });

  test('registers and uses executor', () async {
    var executed = false;
    service.registerExecutor(
      PendingActionKind.createIncident,
      (payload) async {
        executed = true;
      },
    );

    await queue.enqueue(
      PendingAction(
        id: 'exec-1',
        kind: PendingActionKind.createIncident,
        createdAt: DateTime.now(),
      ),
    );
    await service.drainNow();
    expect(executed, isTrue);
    expect(box.isEmpty, isTrue);
  });

  test('drainNow discards action with unknown kind', () async {
    await queue.enqueue(
      PendingAction(
        id: 'exec-3',
        kind: PendingActionKind.voteSuggestion,
        createdAt: DateTime.now(),
      ),
    );
    await service.drainNow();
    final actions = await queue.list();
    expect(actions.length, 0);
  });
}
