import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/notification/local/notification_mock_repository.dart';
import 'package:transitly/shared/models/app_notification.dart';

void main() {
  group('NotificationMockRepository', () {
    test('forUser returns empty list by default', () async {
      final repo = NotificationMockRepository();
      final notifications = await repo.forUser('user-1');
      expect(notifications, isEmpty);
    });

    test('unreadCount is zero by default', () async {
      final repo = NotificationMockRepository();
      final count = await repo.unreadCount('user-1');
      expect(count, 0);
    });

    test('markRead on nonexistent id does not crash', () async {
      final repo = NotificationMockRepository();
      await repo.markRead('nonexistent');
    });
  });
}
