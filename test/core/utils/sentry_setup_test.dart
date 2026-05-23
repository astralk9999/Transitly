import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/sentry_setup.dart';

void main() {
  group('SentrySetup', () {
    test('trace returns fn result when Sentry is not initialized', () async {
      final result = await SentrySetup.trace('test', 'test.op', () async {
        return 42;
      });
      expect(result, 42);
    });

    test('captureException does not throw when not initialized', () {
      expect(
        () => SentrySetup.captureException(Exception('test'), StackTrace.current),
        returnsNormally,
      );
    });
  });
}
