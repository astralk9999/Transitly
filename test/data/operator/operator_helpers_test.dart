import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/operator/operator_helpers.dart';

void main() {
  group('operatorFromRow', () {
    test('maps all fields correctly', () {
      final row = <String, dynamic>{
        'id': 'op-1',
        'name': 'Comujesa',
        'slug': 'comujesa',
        'region': 'ES-AN',
        'website': 'https://comujesa.es',
        'contact_email': 'info@comujesa.es',
      };

      final result = operatorFromRow(row);

      expect(result.id, 'op-1');
      expect(result.name, 'Comujesa');
      expect(result.shortName, 'COMUJESA');
      expect(result.slug, 'comujesa');
      expect(result.region, 'ES-AN');
      expect(result.website, 'https://comujesa.es');
      expect(result.contactEmail, 'info@comujesa.es');
      expect(result.phone, '');
    });

    test('defaults missing fields to empty strings', () {
      final row = <String, dynamic>{
        'id': 'op-2',
        'name': 'Test',
      };

      final result = operatorFromRow(row);

      expect(result.slug, '');
      expect(result.region, '');
      expect(result.website, '');
      expect(result.contactEmail, '');
    });

    test('shortName falls back to name when slug is empty', () {
      final row = <String, dynamic>{
        'id': 'op-3',
        'name': 'Test Operator',
        'slug': '',
      };

      final result = operatorFromRow(row);

      expect(result.shortName, 'Test Operator');
    });

    test('shortName uppercases slug', () {
      final row = <String, dynamic>{
        'id': 'op-4',
        'name': 'Test Operator',
        'slug': 'tussam',
      };

      final result = operatorFromRow(row);

      expect(result.shortName, 'TUSSAM');
    });
  });
}
