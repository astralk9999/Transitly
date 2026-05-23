import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/utils/app_logger.dart';

void main() {
  group('AppLogger format', () {
    test('LogFormat enum has two values', () {
      expect(LogFormat.values.length, 2);
      expect(LogFormat.values, contains(LogFormat.plain));
      expect(LogFormat.values, contains(LogFormat.json));
    });

    test('plain format emits [LEVEL][TAG] message pattern', () {
      final messages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };

      AppLogger.logFormat = LogFormat.plain;
      AppLogger.debug('TestTag', 'hello world');

      expect(messages.isNotEmpty, isTrue);
      final last = messages.last;
      expect(last, contains('[DEBUG]'));
      expect(last, contains('[TestTag]'));
      expect(last, contains('hello world'));
    });

    test('json format emits valid JSON with keys', () {
      final messages = <String>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) messages.add(message);
      };

      AppLogger.logFormat = LogFormat.json;
      AppLogger.info('JsonTag', 'structured log');

      expect(messages.isNotEmpty, isTrue);
      final last = messages.last;
      final decoded = jsonDecode(last) as Map<String, dynamic>;
      expect(decoded['level'], 'INFO');
      expect(decoded['tag'], 'JsonTag');
      expect(decoded['message'], 'structured log');
      expect(decoded.containsKey('timestamp'), isTrue);
    });
  });
}
