import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/operator/domain/operator_repository.dart';
import 'package:transitly/data/operator/operator_helpers.dart';

void main() {
  group('mapOperatorError edge cases', () {
    test('PostgrestException with empty code maps to unknown', () {
      final ex = mapOperatorError(
        const PostgrestException(message: 'Empty code', code: ''),
        StackTrace.current,
        'delete',
      );
      expect(ex.error, OperatorRepositoryError.unknown);
      expect(ex.message, contains('Postgrest error'));
    });

    test('operation name appears in network error message', () {
      final ex = mapOperatorError(
        Exception('Socket closed'),
        StackTrace.current,
        'create',
      );
      expect(ex.error, OperatorRepositoryError.network);
      expect(ex.message, contains('create'));
    });

    test('operatorFromRow with sparse row defaults optional fields', () {
      final row = operatorFromRow({
        'id': 'OP-1',
      });
      expect(row.id, 'OP-1');
      expect(row.name, '');
      expect(row.slug, '');
      expect(row.shortName, '');
      expect(row.region, '');
      expect(row.website, '');
      expect(row.contactEmail, '');
      expect(row.phone, '');
    });
  });
}
