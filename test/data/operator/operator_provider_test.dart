import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/operator/domain/operator_repository.dart';
import 'package:transitly/data/operator/local/operator_local_repository.dart';
import 'package:transitly/data/operator/local/operator_mock_repository.dart';
import 'package:transitly/data/operator/operator_repository_provider.dart';
import 'package:transitly/data/operator/remote/operator_remote_repository.dart';
import 'package:transitly/shared/models/operator_model.dart';

class MockMockDataService extends Mock implements MockDataService {}
class MockOperatorLocalRepository extends Mock implements OperatorLocalRepository {}
class MockOperatorRemoteRepository extends Mock implements OperatorRemoteRepository {}

OperatorModel _testOp(String id) => OperatorModel(
      id: id,
      name: 'Operator $id',
      shortName: 'OP$id',
      slug: 'op$id',
      region: 'Region $id',
    );

void main() {
  group('OperatorRepositoryProvider', () {
    test('OperatorRepositoryError has all 6 error types', () {
      expect(OperatorRepositoryError.values.length, 6);
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.notFound));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.network));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.parse));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.denied));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.conflict));
      expect(OperatorRepositoryError.values, contains(OperatorRepositoryError.unknown));
    });

    test('OperatorMockRepository can be constructed with MockDataService', () {
      final mockData = MockMockDataService();
      when(() => mockData.operator_).thenReturn(_testOp('seed'));
      final repo = OperatorMockRepository(mockData);
      expect(repo, isA<OperatorRepository>());
    });

    test('OperatorRepositorySwr can be constructed with local and remote', () {
      final local = MockOperatorLocalRepository();
      final remote = MockOperatorRemoteRepository();
      final swr = OperatorRepositorySwr(local: local, remote: remote);
      expect(swr, isA<OperatorRepository>());
    });
  });
}
