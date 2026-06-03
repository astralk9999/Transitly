import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    test('setup does not throw', () {
      expect(ErrorBoundary.setup, returnsNormally);
    });

    test('sets FlutterError.onError', () {
      final previous = FlutterError.onError;
      ErrorBoundary.setup();
      expect(FlutterError.onError, isNot(previous));
      FlutterError.onError = previous;
    });

    test('sets PlatformDispatcher onError', () {
      final previous = PlatformDispatcher.instance.onError;
      ErrorBoundary.setup();
      expect(PlatformDispatcher.instance.onError, isNot(previous));
      PlatformDispatcher.instance.onError = previous;
    });
  });
}
