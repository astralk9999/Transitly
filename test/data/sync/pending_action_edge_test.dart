import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';

void main() {
  group('PendingAction edge cases', () {
    test('lastError with special characters survives round-trip', () {
      final action = PendingAction(
        id: 'edge-1',
        kind: PendingActionKind.createIncident,
        payload: {'msg': 'Error: "timeout" — retry #3'},
        createdAt: DateTime(2026, 5, 22).toUtc(),
        attempts: 2,
        lastError: 'Connection refused (code: 500) — retry #3',
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      expect(restored.lastError, 'Connection refused (code: 500) — retry #3');
      expect(restored.payload['msg'], 'Error: "timeout" — retry #3');
    });

    test('payload with nested maps round-trips correctly', () {
      final action = PendingAction(
        id: 'edge-2',
        kind: PendingActionKind.updateUserPrefs,
        payload: {
          'theme': 'dark',
          'locale': 'es',
          'prefs': {'notifications': true, 'sound': false},
        },
        createdAt: DateTime(2026, 5, 22).toUtc(),
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      expect(restored.payload['theme'], 'dark');
      expect(restored.payload['locale'], 'es');
      expect(restored.payload['prefs'], isA<Map<dynamic, dynamic>>());
      expect(
        (restored.payload['prefs'] as Map)['notifications'],
        true,
      );
    });

    test('zero-attempt action isCopyOf itself after serialization', () {
      final action = PendingAction(
        id: 'edge-3',
        kind: PendingActionKind.voteSuggestion,
        payload: {'suggestionId': 'SUG-42', 'vote': 1},
        createdAt: DateTime(2026, 5, 22, 10, 30).toUtc(),
        attempts: 0,
        lastError: null,
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      expect(restored.id, action.id);
      expect(restored.kind, action.kind);
      expect(restored.payload, action.payload);
      expect(restored.createdAt, action.createdAt);
      expect(restored.attempts, 0);
      expect(restored.lastError, isNull);
    });
  });
}
