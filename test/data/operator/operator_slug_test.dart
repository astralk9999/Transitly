import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/operator/operator_helpers.dart';

void main() {
  group('operatorShortNameFromSlug', () {
    test('returns uppercased slug when slug is non-empty', () {
      expect(operatorShortNameFromSlug('comujesa', 'Comujesa'), 'COMUJESA');
      expect(operatorShortNameFromSlug('tussam', 'Tussam'), 'TUSSAM');
    });

    test('falls back to name when slug is empty', () {
      expect(operatorShortNameFromSlug('', 'Comujesa'), 'Comujesa');
      expect(operatorShortNameFromSlug('', 'Some Operator'), 'Some Operator');
    });

    test('uppercases slug ignoring original name case', () {
      expect(operatorShortNameFromSlug('ctsa', 'CTSA Portillo'), 'CTSA');
      expect(
        operatorShortNameFromSlug('comes', 'Consorcio de Transportes'),
        'COMES',
      );
    });
  });
}
