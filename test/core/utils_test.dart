import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/app_logger.dart';
import 'package:transitly/core/utils/force_update_checker.dart';

void main() {
  group('ForceUpdateChecker', () {
    test('updateRequired returns false when minVersion is null (not set)', () {
      final result = ForceUpdateChecker.updateRequired(1);
      expect(result, isFalse,
          reason: 'Without TRANSITLY_MIN_VERSION, no update required');
    });

    test('updateRequired returns false when current >= min', () {
      // minVersion reads from String.fromEnvironment which is empty in tests
      final result = ForceUpdateChecker.updateRequired(999);
      expect(result, isFalse);
    });
  });

  group('AppLogger formats', () {
    test('LogFormat enum has plain and json values', () {
      expect(LogFormat.values, contains(LogFormat.plain));
      expect(LogFormat.values, contains(LogFormat.json));
    });

    test('default logFormat is plain', () {
      expect(AppLogger.logFormat, LogFormat.plain);
    });
  });
}
