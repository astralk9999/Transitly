import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'sentry_setup.dart';

enum LogFormat { plain, json }

/// Thin logging wrapper around [debugPrint] + [assert].
///
/// Niveles: debug → info → perf → warn → error.
/// [perf] registra duraciones de operaciones clave para SLO.
///
/// Two output formats: [LogFormat.plain] (default, human-readable) and
/// [LogFormat.json] (machine-readable, structured logging for production).
///
/// Kept dependency-free on purpose: swapping to `logger` later is a drop-in
/// replacement of these static methods.
class AppLogger {
  const AppLogger._();

  static const _enabled = kDebugMode;
  static LogFormat logFormat = LogFormat.plain;

  static void debug(String tag, String message) {
    if (!_enabled) return;
    _emit('DEBUG', tag, message);
  }

  static void info(String tag, String message) {
    if (!_enabled) return;
    _emit('INFO', tag, message);
  }

  static void perf(String tag, String operation, Duration elapsed) {
    if (!_enabled) return;
    _emit('PERF', tag, '$operation ${elapsed.inMilliseconds}ms');
  }

  static void warn(String tag, String message, [Object? error]) {
    if (!_enabled) return;
    final suffix = error == null ? '' : ' — $error';
    _emit('WARN', tag, '$message$suffix');
    if (error != null) {
      SentrySetup.addBreadcrumb('[$tag] $message — $error', category: 'warn');
    }
  }

  static void error(String tag, String message, [Object? error, StackTrace? st]) {
    if (!_enabled) return;
    final suffix = error == null ? '' : ' — $error';
    _emit('ERROR', tag, '$message$suffix');
    if (st != null) debugPrint(st.toString());
    SentrySetup.captureException(error ?? message, st);
  }

  static void _emit(String level, String tag, String message) {
    switch (logFormat) {
      case LogFormat.json:
        final entry = <String, dynamic>{
          'timestamp': DateTime.now().toUtc().toIso8601String(),
          'level': level,
          'tag': tag,
          'message': message,
        };
        debugPrint(jsonEncode(entry));
      case LogFormat.plain:
        debugPrint('[$level][$tag] $message');
    }
  }
}
