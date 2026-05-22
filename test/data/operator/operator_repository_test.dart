import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/operator/domain/operator_repository.dart';

void main() {
  group('OperatorRepositoryError', () {
    test('all error types are defined', () {
      expect(OperatorRepositoryError.values.length, 6);
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.notFound));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.conflict));
    });
  });

  group('OperatorRepositoryException', () {
    test('stores error and message', () {
      const ex = OperatorRepositoryException(
        error: OperatorRepositoryError.conflict,
        message: 'Slug already exists',
      );
      expect(ex.error, OperatorRepositoryError.conflict);
      expect(ex.message, 'Slug already exists');
    });
  });
}
