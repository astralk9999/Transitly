import 'dart:io' show Directory, File;

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architecture layer rules', () {
    late final String root;

    setUpAll(() {
      root = Directory.current.path;
    });

    /// Collects all imports from all .dart files in [dirPath].
    /// Returns a map of source file path → list of import lines.
    Map<String, List<String>> importsByFile(String dirPath) {
      final dir = Directory('$root/$dirPath');
      if (!dir.existsSync()) return {};
      final result = <String, List<String>>{};
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File && entity.path.endsWith('.dart')) {
          try {
            final lines = File(entity.path).readAsLinesSync();
            result[entity.path] = lines
                .where((l) => l.trimLeft().startsWith('import '))
                .toList();
          } catch (_) {}
        }
      }
      return result;
    }

    test('data/ must not import from features/', () {
      final byFile = importsByFile('lib/data/');
      final violations = <String>[];
      for (final entry in byFile.entries) {
        for (final imp in entry.value) {
          if (imp.contains('features/')) {
            violations.add('${entry.key}: $imp');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'data/ imports features/. Violations: $violations');
    });

    test('shared/widgets/ must not import from features/', () {
      final byFile = importsByFile('lib/shared/widgets/');
      final violations = <String>[];
      for (final entry in byFile.entries) {
        for (final imp in entry.value) {
          if (imp.contains('features/')) {
            violations.add('${entry.key}: $imp');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'shared/widgets/ imports features/. Violations: $violations');
    });

    test('core/ outside router/ must not import from features/', () {
      final byFile = importsByFile('lib/core/');
      final violations = <String>[];
      for (final entry in byFile.entries) {
        for (final imp in entry.value) {
          if (imp.contains('features/') &&
              !entry.key.replaceAll('\\', '/').contains('core/router/')) {
            violations.add('${entry.key}: $imp');
          }
        }
      }
      expect(violations, isEmpty,
          reason: 'core/ outside router/ imports features/. Violations: $violations');
    });
  });
}
