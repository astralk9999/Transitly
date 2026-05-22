import 'package:sentry_flutter/sentry_flutter.dart';

class SentrySetup {
  static bool _initialized = false;

  static final _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b',
  );
  static final _uuidRegex = RegExp(
    r'[0-9a-fA-F]{8,}(?:-[0-9a-fA-F]{4,})*',
  );
  static final _coordsRegex = RegExp(
    r'\b[-+]?\d{1,3}\.\d{4,}\b',
  );
  static const _piiDataKeys = {'lat', 'lng', 'latitude', 'longitude'};

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

  /// GDPR: revocación efectiva en caliente. Cierra el cliente Sentry y
  /// permite re-`init()` si el usuario vuelve a otorgar consentimiento.
  static Future<void> close() async {
    if (!_initialized) return;
    await Sentry.close();
    _initialized = false;
  }

  static SentryEvent? _scrubPII(SentryEvent event, Hint hint) {
    event = event.copyWith(
      user: event.user?.copyWith(ipAddress: null, email: null),
    );

    if (event.breadcrumbs != null) {
      event = event.copyWith(
        breadcrumbs: event.breadcrumbs!.map((bc) {
          var message = bc.message;
          if (message != null) {
            message = message.replaceAll(_emailRegex, '[EMAIL]');
            message = message.replaceAll(_coordsRegex, '[COORDS]');
            message = message.replaceAll(_uuidRegex, '[UUID]');
          }
          Map<String, dynamic>? data = bc.data;
          if (data != null) {
            data = Map<String, dynamic>.from(data);
            data.removeWhere((k, _) => _piiDataKeys.contains(k.toLowerCase()));
          }
          return Breadcrumb(
            message: message,
            category: bc.category,
            type: bc.type,
            data: data,
            level: bc.level,
            timestamp: bc.timestamp,
          );
        }).toList(),
      );
    }

    if (event.exceptions != null) {
      event = event.copyWith(
        exceptions: event.exceptions!.map((ex) {
          return SentryException(
            type: ex.type,
            value: ex.value?.replaceAll(_uuidRegex, '[UUID]'),
            module: ex.module,
            stackTrace: ex.stackTrace,
            mechanism: ex.mechanism,
          );
        }).cast<SentryException>().toList(),
      );
    }

    return event;
  }

  static Future<T> trace<T>(
    String name,
    String op,
    Future<T> Function() fn,
  ) async {
    if (!_initialized) return fn();
    final span = Sentry.startTransaction(name, op);
    try {
      final result = await fn();
      span.status = const SpanStatus.ok();
      return result;
    } catch (e) {
      span.status = const SpanStatus.internalError();
      rethrow;
    } finally {
      await span.finish();
    }
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
