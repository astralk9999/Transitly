import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/sync/offline_sync_service.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';

void main() {
  late Box<Map<dynamic, dynamic>> box;
  late Box<Map<dynamic, dynamic>> deadBox;
  late PendingActionsQueue queue;
  late OfflineSyncService syncService;

  setUp(() async {
    try {
      Hive.init('./test/hive_temp');
    } catch (_) {}
    box = await Hive.openBox<Map<dynamic, dynamic>>('test_pending');
    deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_dead');
    queue = PendingActionsQueue(box: box, deadBox: deadBox);
    syncService = OfflineSyncService(queue: queue);
  });

  tearDown(() async {
    await box.close();
    await deadBox.close();
    await Hive.deleteBoxFromDisk('test_pending');
    await Hive.deleteBoxFromDisk('test_dead');
  });

  test('smoke: enqueue 3 actions and drain offline queue', () async {
    final executed = <String>[];

    syncService.registerExecutor(PendingActionKind.createIncident, (_) async {
      executed.add('createIncident');
    });
    syncService.registerExecutor(
        PendingActionKind.createRouteFeedback, (_) async {
      executed.add('createRouteFeedback');
    });
    syncService.registerExecutor(
        PendingActionKind.createRouteSuggestion, (_) async {
      executed.add('createRouteSuggestion');
    });

    final now = DateTime.now();
    await queue.enqueue(PendingAction(
      id: 'action-1',
      kind: PendingActionKind.createIncident,
      createdAt: now,
    ));
    await queue.enqueue(PendingAction(
      id: 'action-2',
      kind: PendingActionKind.createRouteFeedback,
      createdAt: now.add(const Duration(seconds: 1)),
    ));
    await queue.enqueue(PendingAction(
      id: 'action-3',
      kind: PendingActionKind.createRouteSuggestion,
      createdAt: now.add(const Duration(seconds: 2)),
    ));

    expect(await queue.list(), hasLength(3));

    await syncService.drainNow();

    expect(executed.length, 3);
    expect(executed, contains('createIncident'));
    expect(executed, contains('createRouteFeedback'));
    expect(executed, contains('createRouteSuggestion'));
    expect(await queue.list(), isEmpty);
  });

  test('smoke: actions stay in queue when executors not registered', () async {
    final now = DateTime.now();
    await queue.enqueue(PendingAction(
      id: 'action-4',
      kind: PendingActionKind.createIncident,
      createdAt: now,
    ));

    expect(await queue.list(), hasLength(1));

    await syncService.drainNow();

    expect(await queue.list(), hasLength(1));
  });

  test('smoke: failed action increases attempts counter', () async {
    syncService.registerExecutor(PendingActionKind.createIncident, (_) async {
      throw Exception('network down');
    });

    final now = DateTime.now();
    await queue.enqueue(PendingAction(
      id: 'action-5',
      kind: PendingActionKind.createIncident,
      createdAt: now,
    ));

    await syncService.drainNow();

    final actions = await queue.list();
    expect(actions, hasLength(1));
    expect(actions.first.attempts, 1);
    expect(actions.first.lastError, contains('network down'));
  });
}
