import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/push/firebase_setup.dart';
import 'package:transitly/data/push/push_service.dart';

void main() {
  group('PushService', () {
    test('fcmToken is initially null', () {
      expect(PushService.fcmToken, isNull);
    });

    test('init is idempotent', () async {
      await PushService.init();
      await PushService.init();
    });

    test('FirebaseSetup.isAvailable is false without init', () {
      expect(FirebaseSetup.isAvailable, isFalse);
    });
  });
}
