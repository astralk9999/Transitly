import 'package:flutter/foundation.dart';

/// Thin logging wrapper around [debugPrint] + [assert].
///
/// Kept dependency-free on purpose: swapping to `logger` later is a drop-in
/// replacement of these four static methods.
class AppLogger {
  const AppLogger._();

  static const _enabled = kDebugMode;

  static void debug(String tag, String message) {
    if (!_enabled) return;
    debugPrint('[DEBUG][$tag] $message');
  }

  static void info(String tag, String message) {
    if (!_enabled) return;
    debugPrint('[INFO ][$tag] $message');
  }

  static void warn(String tag, String message, [Object? error]) {
    if (!_enabled) return;
    final suffix = error == null ? '' : ' — $error';
    debugPrint('[WARN ][$tag] $message$suffix');
  }

  static void error(String tag, String message, [Object? error, StackTrace? st]) {
    if (!_enabled) return;
    final suffix = error == null ? '' : ' — $error';
    debugPrint('[ERROR][$tag] $message$suffix');
    if (st != null) debugPrint(st.toString());
  }
}
