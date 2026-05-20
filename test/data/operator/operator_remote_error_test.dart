import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:transitly/data/operator/domain/operator_repository.dart';
import 'package:transitly/data/operator/operator_helpers.dart';

void main() {
  group('mapOperatorError', () {
    test('maps PGRST116 to notFound', () {
      final ex = mapOperatorError(
        // ignore: prefer_const_constructors
        PostgrestException(message: 'Not found', code: 'PGRST116'),
        StackTrace.current,
        'test',
      );
      expect(ex.error, OperatorRepositoryError.notFound);
      expect(ex.message, 'Operator not found');
    });

    test('maps 42501 to denied', () {
      final ex = mapOperatorError(
        // ignore: prefer_const_constructors
        PostgrestException(message: 'RLS denied', code: '42501'),
        StackTrace.current,
        'test',
      );
      expect(ex.error, OperatorRepositoryError.denied);
      expect(ex.message, 'Access denied by RLS');
    });

    test('maps 23505 to conflict', () {
      final ex = mapOperatorError(
        // ignore: prefer_const_constructors
        PostgrestException(message: 'Duplicate slug', code: '23505'),
        StackTrace.current,
        'create',
      );
      expect(ex.error, OperatorRepositoryError.conflict);
      expect(ex.message, contains('already exists'));
    });

    test('maps unknown PostgrestException to unknown', () {
      final ex = mapOperatorError(
        // ignore: prefer_const_constructors
        PostgrestException(message: 'Some error', code: '99999'),
        StackTrace.current,
        'test',
      );
      expect(ex.error, OperatorRepositoryError.unknown);
      expect(ex.message, contains('Postgrest error'));
    });

    test('maps non-PostgrestException to network', () {
      final ex = mapOperatorError(
        Exception('Network down'),
        StackTrace.current,
        'test',
      );
      expect(ex.error, OperatorRepositoryError.network);
      expect(ex.message, contains('Network'));
    });
  });
}
