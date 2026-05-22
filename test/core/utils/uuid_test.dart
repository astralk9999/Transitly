import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/uuid.dart';

void main() {
  group('generateUuidV4', () {
    test('produces a valid UUID v4 format', () {
      final uuid = generateUuidV4();

      final regex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      );
      expect(regex.hasMatch(uuid), true, reason: 'got: $uuid');
    });

    test('each generated UUID is unique', () {
      const count = 200;
      final uuids = <String>{};
      for (int i = 0; i < count; i++) {
        uuids.add(generateUuidV4());
      }

      expect(uuids.length, count, reason: 'Expected $count unique UUIDs');
    });

    test('always produces 36 characters', () {
      for (int i = 0; i < 50; i++) {
        final uuid = generateUuidV4();
        expect(uuid.length, 36, reason: 'got length ${uuid.length} for: $uuid');
      }
    });
  });
}
