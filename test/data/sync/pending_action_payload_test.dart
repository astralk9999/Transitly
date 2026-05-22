import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/sync/pending_action.dart';

void main() {
  group('PendingAction payload roundtrip', () {
    test('complex nested payload survives JSON roundtrip', () {
      final payload = <String, dynamic>{
        'stopId': 'JER-001',
        'nested': {
          'lat': 36.68,
          'lng': -6.13,
          'tags': ['bus', 'L1'],
        },
        'count': 42,
        'active': true,
        'nullable': null,
      };

      final action = PendingAction(
        id: 'pa-1',
        kind: PendingActionKind.createIncident,
        payload: payload,
        createdAt: DateTime(2026, 5, 22).toUtc(),
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      expect(restored.payload['stopId'], 'JER-001');
      expect(restored.payload['nested'], isA<Map<String, dynamic>>());
      expect(
        (restored.payload['nested'] as Map<String, dynamic>)['lat'],
        36.68,
      );
      expect(
        (restored.payload['nested'] as Map<String, dynamic>)['lng'],
        -6.13,
      );
      expect(
        (restored.payload['nested'] as Map<String, dynamic>)['tags'],
        ['bus', 'L1'],
      );
      expect(restored.payload['count'], 42);
      expect(restored.payload['active'], true);
      expect(restored.payload['nullable'], isNull);
    });

    test('payload with list of maps rounds trips correctly', () {
      final payload = <String, dynamic>{
        'items': [
          {'id': 'a', 'value': 1},
          {'id': 'b', 'value': 2},
          {'id': 'c', 'value': 3},
        ],
        'meta': {'version': 2},
      };

      final action = PendingAction(
        id: 'pa-2',
        kind: PendingActionKind.createRouteFeedback,
        payload: payload,
        createdAt: DateTime(2026, 5, 22).toUtc(),
      );

      final json = action.toJson();
      final restored = PendingAction.fromJson(json);

      final items = restored.payload['items'] as List<dynamic>;
      expect(items.length, 3);
      expect((items[0] as Map<String, dynamic>)['id'], 'a');
      expect((items[1] as Map<String, dynamic>)['value'], 2);
      expect(
        (restored.payload['meta'] as Map<String, dynamic>)['version'],
        2,
      );
    });
  });
}
