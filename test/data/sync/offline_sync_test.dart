import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';

void main() {
  group('PendingAction', () {
    test('creates with required fields', () {
      final action = PendingAction(
        id: 'test-1',
        kind: PendingActionKind.createIncident,
        createdAt: DateTime.now().toUtc(),
      );
      expect(action.id, 'test-1');
      expect(action.kind, PendingActionKind.createIncident);
      expect(action.attempts, 0);
    });

    test('copyWith updates fields', () {
      final action = PendingAction(
        id: 'test-2',
        kind: PendingActionKind.createIncident,
        createdAt: DateTime.now().toUtc(),
      );
      final updated = action.copyWith(attempts: 5);
      expect(updated.attempts, 5);
      expect(updated.id, action.id);
    });

    test('toJson and fromJson roundtrip', () {
      final action = PendingAction(
        id: 'test-3',
        kind: PendingActionKind.markFavorite,
        payload: {'routeId': 'L1'},
        createdAt: DateTime(2026, 5, 22).toUtc(),
        attempts: 2,
        lastError: 'timeout',
      );
      final json = action.toJson();
      final restored = PendingAction.fromJson(json);
      expect(restored.id, 'test-3');
      expect(restored.payload['routeId'], 'L1');
      expect(restored.attempts, 2);
    });
  });
}
