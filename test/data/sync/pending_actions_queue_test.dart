import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';

void main() {
  late Box<Map<dynamic, dynamic>> box;
  late Box<Map<dynamic, dynamic>> deadBox;
  late PendingActionsQueue queue;
  late DateTime now;

  setUp(() async {
    Hive.init('./test/hive_temp_queue');
    box = await Hive.openBox<Map<dynamic, dynamic>>('test_q_main');
    deadBox = await Hive.openBox<Map<dynamic, dynamic>>('test_q_dead');
    queue = PendingActionsQueue(box: box, deadBox: deadBox);
    now = DateTime.now();
  });

  tearDown(() async {
    await box.close();
    await deadBox.close();
    await Hive.deleteBoxFromDisk('test_q_main');
    await Hive.deleteBoxFromDisk('test_q_dead');
  });

  test('enqueue adds an action and list returns it', () async {
    final action = PendingAction(
      id: 'q-1',
      kind: PendingActionKind.createIncident,
      createdAt: now,
    );

    await queue.enqueue(action);

    final actions = await queue.list();
    expect(actions.length, 1);
    expect(actions.first.id, 'q-1');
    expect(actions.first.kind, PendingActionKind.createIncident);
  });

  test('list returns actions in FIFO order by createdAt', () async {
    await queue.enqueue(PendingAction(
      id: 'q-2',
      kind: PendingActionKind.voteSuggestion,
      createdAt: now.add(const Duration(seconds: 2)),
    ));
    await queue.enqueue(PendingAction(
      id: 'q-3',
      kind: PendingActionKind.createRouteFeedback,
      createdAt: now,
    ));
    await queue.enqueue(PendingAction(
      id: 'q-4',
      kind: PendingActionKind.markFavorite,
      createdAt: now.add(const Duration(seconds: 1)),
    ));

    final actions = await queue.list();
    expect(actions.length, 3);
    expect(actions[0].id, 'q-3');
    expect(actions[1].id, 'q-4');
    expect(actions[2].id, 'q-2');
  });

  test('remove deletes an action from the queue', () async {
    final action = PendingAction(
      id: 'q-5',
      kind: PendingActionKind.submitOfficialRequest,
      createdAt: now,
    );

    await queue.enqueue(action);
    expect(await queue.list(), hasLength(1));

    await queue.remove('q-5');
    expect(await queue.list(), isEmpty);
  });
}
