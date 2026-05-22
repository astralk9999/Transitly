import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';
import 'package:transitly/data/sync/pending_actions_queue.dart';

Duration _backoff(int attempts) {
  final raw = math.pow(2, math.max(0, attempts - 1)).toInt();
  final seconds = math.min(60, raw);
  return Duration(seconds: seconds);
}

void main() {
  group('Dead letter queue', () {
    test('PendingActionsQueue.maxAttempts is 10', () {
      expect(PendingActionsQueue.maxAttempts, 10);
    });

    test('backoff computes exponential delay capped at 60s', () {
      expect(_backoff(1).inSeconds, 1);
      expect(_backoff(3).inSeconds, 4);
      expect(_backoff(5).inSeconds, 16);
      expect(_backoff(10).inSeconds, 60);
    });

    test('copyWith beyond maxAttempts creates dead letter candidate', () {
      final action = PendingAction(
        id: 'dead-1',
        kind: PendingActionKind.createIncident,
        payload: {'test': true},
        createdAt: DateTime.utc(2026, 5, 1),
        attempts: 9,
        lastError: 'timeout',
      );
      final afterFail = action.copyWith(
        attempts: action.attempts + 1,
        lastError: 'network',
      );
      expect(afterFail.attempts, 10);
      final dead = afterFail.copyWith(
        attempts: afterFail.attempts + 1,
        lastError: 'dead',
      );
      expect(dead.attempts, 11);
      expect(dead.attempts > PendingActionsQueue.maxAttempts, isTrue);
    });
  });
}
