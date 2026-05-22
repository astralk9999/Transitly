import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';

void main() {
  group('PendingActionKind', () {
    test('all kinds have unique names', () {
      final names = PendingActionKind.values.map((k) => k.name).toSet();
      expect(names.length, PendingActionKind.values.length);
    });

    test('create actions exist', () {
      expect(
        PendingActionKind.values,
        contains(PendingActionKind.createIncident),
      );
      expect(
        PendingActionKind.values,
        contains(PendingActionKind.createRouteFeedback),
      );
      expect(
        PendingActionKind.values,
        contains(PendingActionKind.createRouteSuggestion),
      );
    });

    test('vote actions exist', () {
      expect(
        PendingActionKind.values,
        contains(PendingActionKind.voteSuggestion),
      );
      expect(
        PendingActionKind.values,
        contains(PendingActionKind.voteFeatureRequest),
      );
    });
  });
}
