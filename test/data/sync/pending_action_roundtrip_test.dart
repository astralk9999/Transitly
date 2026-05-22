import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';

void main() {
  group('PendingActionKind round-trip serialization', () {
    test('all 14 PendingActionKind values serialize to/from JSON', () {
      for (final kind in PendingActionKind.values) {
        final action = PendingAction(
          id: 'test-${kind.name}',
          kind: kind,
          payload: {'key': 'value'},
          createdAt: DateTime(2026, 5, 22, 12, 0, 0).toUtc(),
          attempts: 1,
          lastError: null,
        );

        final json = action.toJson();
        final restored = PendingAction.fromJson(json);

        expect(restored.id, action.id,
            reason: 'id mismatch for ${kind.name}');
        expect(restored.kind, action.kind,
            reason: 'kind mismatch for ${kind.name}');
        expect(restored.payload, action.payload,
            reason: 'payload mismatch for ${kind.name}');
        expect(restored.createdAt, action.createdAt,
            reason: 'createdAt mismatch for ${kind.name}');
        expect(restored.attempts, action.attempts,
            reason: 'attempts mismatch for ${kind.name}');
        expect(restored.lastError, action.lastError,
            reason: 'lastError mismatch for ${kind.name}');
      }
    });

    test('PendingAction with lastError serializes correctly', () {
      final action = PendingAction(
        id: 'err-1',
        kind: PendingActionKind.createIncident,
        payload: {'stopId': 'JER-001'},
        createdAt: DateTime(2026, 5, 22).toUtc(),
        attempts: 3,
        lastError: 'Network timeout',
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      expect(restored.lastError, 'Network timeout');
      expect(restored.attempts, 3);
    });

    test('PendingAction defaults are correct', () {
      final action = PendingAction(
        id: 'default-test',
        kind: PendingActionKind.createRouteFeedback,
        createdAt: DateTime.now().toUtc(),
      );

      expect(action.attempts, 0);
      expect(action.payload, isEmpty);
      expect(action.lastError, isNull);
    });

    test('PendingActionKind enum values count is 14', () {
      expect(PendingActionKind.values.length, 14,
          reason: 'Must have exactly 14 PendingActionKind values');
    });
  });

  group('PendingAction JSON format', () {
    test('JSON keys match expected format', () {
      final action = PendingAction(
        id: 'json-test',
        kind: PendingActionKind.createIncident,
        createdAt: DateTime(2026, 5, 22).toUtc(),
      );

      final json = action.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('kind'), isTrue);
      expect(json.containsKey('payload'), isTrue);
      expect(json.containsKey('createdAt'), isTrue);
      expect(json.containsKey('attempts'), isTrue);
      expect(json['attempts'], 0);
    });
  });

  group('All PendingActionKind values documented', () {
    test('expected 14 kinds are present', () {
      final names = PendingActionKind.values.map((k) => k.name).toSet();
      expect(names, contains('createIncident'));
      expect(names, contains('createRouteFeedback'));
      expect(names, contains('createRouteSuggestion'));
      expect(names, contains('createFeatureRequest'));
      expect(names, contains('createCommunityRoute'));
      expect(names, contains('updateUserPrefs'));
      expect(names, contains('submitOfficialRequest'));
      expect(names, contains('claimInvitationCode'));
      expect(names, contains('voteSuggestion'));
      expect(names, contains('voteFeatureRequest'));
      expect(names, contains('markFavorite'));
      expect(names, contains('markNotificationRead'));
      expect(names, contains('updateFeedbackStatus'));
      expect(names, contains('updateIncidentStatus'));
    });
  });
}
