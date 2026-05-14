import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/operator/domain/operator_repository.dart';
import 'package:transitly/data/operator/local/operator_mock_repository.dart';
import 'package:transitly/shared/models/operator_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

OperatorModel _testOp(String id) => OperatorModel(
      id: id,
      name: 'Operator $id',
      shortName: 'OP$id',
      slug: 'op$id',
      region: 'Region $id',
    );

void main() {
  late MockMockDataService mockData;
  late OperatorMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    when(() => mockData.operator_).thenReturn(_testOp('seed'));
    repo = OperatorMockRepository(mockData);
  });

  group('OperatorMockRepository CRUD', () {
    test('create añade operador a la lista', () async {
      final newOp = _testOp('new');
      final created = await repo.create(newOp);

      expect(created.id, 'new');
      final all = await repo.list();
      expect(all.length, 2);
      expect(all.last.id, 'new');
    });

    test('update modifica operador existente', () async {
      final updated = _testOp('seed').copyWith(name: 'Updated Name');

      final result = await repo.update(updated);

      expect(result.name, 'Updated Name');
      final stored = await repo.byId('seed');
      expect(stored!.name, 'Updated Name');
    });

    test('update lanza OperatorRepositoryException si no existe', () async {
      final nonExistent = _testOp('ghost');

      expect(
        () => repo.update(nonExistent),
        throwsA(isA<OperatorRepositoryException>()),
      );
    });

    test('delete elimina operador', () async {
      await repo.delete('seed');

      final all = await repo.list();
      expect(all, isEmpty);
      final byId = await repo.byId('seed');
      expect(byId, isNull);
    });
  });
}
