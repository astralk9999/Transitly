import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/operator/local/operator_local_repository.dart';
import 'package:transitly/shared/models/operator_model.dart';

class MockBox extends Mock implements Box<OperatorModel> {}

OperatorModel _testOp(String id) => OperatorModel(
      id: id,
      name: 'Operator $id',
      shortName: id,
      slug: 'op-$id',
      region: 'Region',
      website: '',
      contactEmail: '',
      phone: '',
    );

void main() {
  late MockBox mockBox;
  late OperatorLocalRepository repo;

  setUp(() {
    mockBox = MockBox();
    repo = OperatorLocalRepository(mockBox);
  });

  group('OperatorLocalRepository', () {
    test('list returns all items from box', () async {
      final ops = [_testOp('1'), _testOp('2')];
      when(() => mockBox.values).thenReturn(ops);

      final result = await repo.list();
      expect(result.length, 2);
      expect(result.first.id, '1');
      expect(result.last.id, '2');
    });

    test('byId returns item when exists', () async {
      final op = _testOp('42');
      when(() => mockBox.get('op:42')).thenReturn(op);

      final result = await repo.byId('42');
      expect(result, isNotNull);
      expect(result!.id, '42');
    });

    test('upsert stores item in box', () async {
      final op = _testOp('99');
      when(() => mockBox.put('op:99', op))
          .thenAnswer((_) async {});

      await repo.upsert(op);
      verify(() => mockBox.put('op:99', op)).called(1);
    });
  });
}
