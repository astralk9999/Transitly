import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/app_notification.dart';

void main() {
  group('AppNotification', () {
    test('fromJson parses all fields correctly', () {
      final json = {
        'id': 'notif-1',
        'userId': 'user-abc',
        'type': 'incidentResolved',
        'payload': {'routeId': 'L1', 'incidentId': 'inc-5'},
        'read': true,
        'createdAt': '2026-05-22T10:30:00.000Z',
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'notif-1');
      expect(notif.userId, 'user-abc');
      expect(notif.type, AppNotificationType.incidentResolved);
      expect(notif.payload['routeId'], 'L1');
      expect(notif.payload['incidentId'], 'inc-5');
      expect(notif.read, true);
      expect(notif.createdAt.year, 2026);
    });

    test('AppNotificationType enum has all expected values', () {
      const expected = [
        AppNotificationType.incidentResolved,
        AppNotificationType.routePromoted,
        AppNotificationType.shareReceived,
        AppNotificationType.featureRequestReplied,
        AppNotificationType.busApproachingFavorite,
        AppNotificationType.xpEarned,
        AppNotificationType.rankUp,
        AppNotificationType.custom,
      ];

      expect(AppNotificationType.values, orderedEquals(expected));
      expect(AppNotificationType.values.length, 8);
    });

    test('isRead defaults to false and can be set to true', () {
      final unread = AppNotification(
        id: 'n1',
        userId: 'u1',
        type: AppNotificationType.custom,
        createdAt: DateTime.now(),
      );
      expect(unread.read, false);

      final read = AppNotification(
        id: 'n2',
        userId: 'u1',
        type: AppNotificationType.custom,
        read: true,
        createdAt: DateTime.now(),
      );
      expect(read.read, true);
    });
  });
}
