import 'dart:io' show exit;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'app_logger.dart';
import 'sentry_setup.dart';

class ErrorBoundary {
  ErrorBoundary._();

  static void setup() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AppLogger.error('FlutterError', details.exceptionAsString(),
          details.exception, details.stack);
      SentrySetup.captureException(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.error(
          'PlatformDispatcher', error.toString(), error, stack);
      SentrySetup.captureException(error, stack);
      return true;
    };

    ErrorWidget.builder = (details) => _ErrorScreen(details: details);
  }
}

class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen({required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7C6FF7),
          brightness: Brightness.dark,
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The app encountered an unexpected error and cannot continue.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    try {
                      SentrySetup.captureException(
                        details.exception,
                        details.stack,
                      );
                    } catch (_) {}
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Report error'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF7C6FF7),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => exit(0),
                  child: const Text('Close app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
