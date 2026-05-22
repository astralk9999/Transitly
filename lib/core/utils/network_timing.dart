import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_logger.dart';
import 'sentry_setup.dart';

class NetworkTimingInterceptor {
  NetworkTimingInterceptor._();

  static const _tag = 'Network';

  static Future<T> measure<T>(
    String operation,
    Future<T> Function() call,
  ) async {
    final start = DateTime.now();
    return SentrySetup.trace('network.$operation', 'http.client', () async {
      try {
        final result = await call();
        final elapsed = DateTime.now().difference(start);
        AppLogger.perf(_tag, operation, elapsed);
        return result;
      } catch (e) {
        final elapsed = DateTime.now().difference(start);
        AppLogger.warn(_tag, '$operation failed after ${elapsed.inMilliseconds}ms', e);
        rethrow;
      }
    });
  }

  static PostgrestFilterBuilder<T> timedFilter<T>(
    PostgrestFilterBuilder<T> query,
    String label,
  ) {
    // Note: PostgrestFilterBuilder is eagerly evaluated.
    // Timing is captured on the call site via measure().
    return query;
  }
}

extension TimedSupabaseQuery on PostgrestQueryBuilder<dynamic> {
  Future<List<Map<String, dynamic>>> timedSelect(String label) {
    return NetworkTimingInterceptor.measure(
      '$label.select',
      select,
    );
  }
}
