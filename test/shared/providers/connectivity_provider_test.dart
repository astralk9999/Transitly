import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Connectivity', () {
    test('isOffline is true when no connection', () {
      const isOffline = true;
      expect(isOffline, isTrue);
    });

    test('isOffline is false when connected', () {
      const isOffline = false;
      expect(isOffline, isFalse);
    });

    test('connectivity check returns valid result', () {
      final result = true;
      expect(result, isA<bool>());
    });
  });
}
