import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/operator/local/operator_mock_repository.dart';
import 'package:transitly/shared/models/operator_model.dart';

class MockMockDataServiceEdge extends Mock implements MockDataService {}

OperatorModel _op(String id) => OperatorModel(
      id: id,
      name: 'Op $id',
      shortName: 'O$id',
      slug: 'o$id',
      region: 'Region $id',
    );

void main() {
  late MockMockDataServiceEdge mockData;
  late OperatorMockRepository repo;

  setUp(() {
    mockData = MockMockDataServiceEdge();
    when(() => mockData.operator_).thenReturn(_op('seed'));
    repo = OperatorMockRepository(mockData);
  });

  group('OperatorMockRepository edge', () {
    test('list with offset beyond cache length returns empty', () async {
      final result = await repo.list(offset: 10);
      expect(result, isEmpty);
    });

    test('nearby returns all cached operators regardless of radius', () async {
      final farCenter = LatLng(-34.0, 150.0);
      final result = await repo.nearby(farCenter, radiusM: 100);
      expect(result.length, 1);
      expect(result.first.id, 'seed');
    });

    test('byId returns null for non-existent id', () async {
      final result = await repo.byId('nonexistent');
      expect(result, isNull);
    });
  });
}
