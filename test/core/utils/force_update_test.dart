import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/force_update_checker.dart';

void main() {
  group('ForceUpdateChecker edge cases', () {
    test('updateRequired with version 0 is false when minVersion is null', () {
      final result = ForceUpdateChecker.updateRequired(0);
      expect(result, isFalse,
          reason: 'Version 0 with no explicit minVersion should not block');
    });

    test('minVersion getter returns null when TRANSITLY_MIN_VERSION is unset',
        () {
      expect(ForceUpdateChecker.minVersion, isNull,
          reason: 'In test environment, dart-define is not set');
    });
  });
}
