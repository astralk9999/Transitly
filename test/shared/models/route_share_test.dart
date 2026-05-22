import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/route_share.dart';

void main() {
  group('RouteShare', () {
    test('fromJson parses all fields correctly', () {
      final json = <String, dynamic>{
        'routeId': 'r-1',
        'sharedWithId': 'user-2',
        'sharedById': 'user-1',
        'permission': 'edit',
        'createdAt': '2026-05-20T10:30:00.000Z',
        'expiresAt': '2026-06-20T10:30:00.000Z',
      };

      final share = RouteShare.fromJson(json);

      expect(share.routeId, 'r-1');
      expect(share.sharedWithId, 'user-2');
      expect(share.sharedById, 'user-1');
      expect(share.permission, RouteSharePermission.edit);
      expect(share.createdAt, DateTime.parse('2026-05-20T10:30:00.000Z'));
      expect(share.expiresAt, DateTime.parse('2026-06-20T10:30:00.000Z'));
    });

    test('fromJson defaults missing optional fields', () {
      final json = <String, dynamic>{
        'routeId': 'r-2',
        'sharedWithId': 'user-3',
        'sharedById': 'user-4',
        'createdAt': '2026-05-22T08:00:00.000Z',
      };

      final share = RouteShare.fromJson(json);

      expect(share.permission, RouteSharePermission.view);
      expect(share.expiresAt, isNull);
    });

    test('toJson roundtrips correctly', () {
      final createdAt = DateTime.parse('2026-05-23T14:00:00.000Z');
      final expiresAt = DateTime.parse('2026-08-23T14:00:00.000Z');
      final original = RouteShare(
        routeId: 'r-3',
        sharedWithId: 'user-5',
        sharedById: 'user-6',
        permission: RouteSharePermission.edit,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );

      final json = original.toJson();
      final restored = RouteShare.fromJson(json);

      expect(restored.routeId, original.routeId);
      expect(restored.sharedWithId, original.sharedWithId);
      expect(restored.sharedById, original.sharedById);
      expect(restored.permission, original.permission);
      expect(restored.createdAt, original.createdAt);
      expect(restored.expiresAt, original.expiresAt);
    });
  });
}
