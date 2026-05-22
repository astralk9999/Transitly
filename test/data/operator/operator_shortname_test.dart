import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/operator/operator_helpers.dart';

void main() {
  group('operatorShortNameFromSlug edge cases', () {
    test('preserves case of name when slug is whitespace-only', () {
      expect(operatorShortNameFromSlug('   ', 'Comujesa'), '   ');
      expect(operatorShortNameFromSlug('\t', 'Tussam'), '\t');
    });

    test('handles empty slug with empty name', () {
      expect(operatorShortNameFromSlug('', ''), '');
    });

    test('uppercases single-char slug', () {
      expect(operatorShortNameFromSlug('a', 'Alpha Transit'), 'A');
      expect(operatorShortNameFromSlug('z', 'Zeta'), 'Z');
    });
  });
}
