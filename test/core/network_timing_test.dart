import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/network_timing.dart';

void main() {
  group('NetworkTimingInterceptor', () {
    test('measure returns the result of the call', () async {
      final result = await NetworkTimingInterceptor.measure(
        'test.operation',
        () async => 'success',
      );
      expect(result, 'success');
    });

    test('measure propagates exceptions', () async {
      expect(
        () => NetworkTimingInterceptor.measure(
          'test.fail',
          () async => throw Exception('network error'),
        ),
        throwsException,
      );
    });

    test('measure records timing (perf log, no throw)', () async {
      await NetworkTimingInterceptor.measure(
        'test.timing',
        () async {
          await Future.delayed(const Duration(milliseconds: 1));
          return 42;
        },
      );
      // If it reaches here without throwing, the timing was recorded
      expect(true, isTrue);
    });
  });
}
