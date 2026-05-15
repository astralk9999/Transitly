import 'package:sentry_flutter/sentry_flutter.dart';

class SentrySetup {
  static bool _initialized = false;

  static Future<void> init({required String dsn, required bool enabled}) async {
    if (_initialized || !enabled) return;
    await SentryFlutter.init((options) {
      options.dsn = dsn;
      options.tracesSampleRate = 0.2;
      options.environment = const bool.hasEnvironment('dart.vm.product') ? 'prod' : 'dev';
      options.beforeSend = _scrubPII;
    });
    _initialized = true;
  }

  static SentryEvent? _scrubPII(SentryEvent event, Hint hint) {
    event = event.copyWith(user: event.user?.copyWith(ipAddress: null));
    return event;
  }

  static void captureException(Object exception, StackTrace? stackTrace) {
    if (!_initialized) return;
    Sentry.captureException(exception, stackTrace: stackTrace);
  }

  static void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    if (!_initialized) return;
    Sentry.addBreadcrumb(Breadcrumb(message: message, category: category, data: data));
  }
}
