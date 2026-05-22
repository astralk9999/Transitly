import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/route/local/route_mock_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/operator_model.dart';
import 'package:transitly/shared/models/route_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

class MockOperatorModel extends Mock implements OperatorModel {}

RouteModel _route(String id) => RouteModel(
      id: id,
      operatorId: 'comujesa',
      code: id,
      name: 'Ruta $id',
      serviceType: ServiceType.urban,
      routeColor: const Color(0xFF3388FF),
    );

void main() {
  late MockMockDataService mockData;
  late RouteMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    repo = RouteMockRepository(mockData);
  });

  group('RouteMockRepository provider', () {
    test('byOperator returns empty list for mismatched operator', () async {
      final fakeOp = MockOperatorModel();
      when(() => fakeOp.id).thenReturn('other-op');
      when(() => mockData.operator_).thenReturn(fakeOp);
      when(() => mockData.routes).thenReturn([_route('L1')]);
      final results = await repo.byOperator('comujesa');
      expect(results, isEmpty);
    });

    test('byId returns null for unknown id', () async {
      when(() => mockData.getRouteById('nonexistent')).thenReturn(null);
      final result = await repo.byId('nonexistent');
      expect(result, isNull);
    });

    test('byId returns route when found', () async {
      final route = _route('L1');
      when(() => mockData.getRouteById('L1')).thenReturn(route);
      final result = await repo.byId('L1');
      expect(result, isNotNull);
      expect(result!.id, 'L1');
      expect(result.code, 'L1');
    });
  });
}
