import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/stop/local/stop_mock_repository.dart';
import 'package:transitly/shared/models/operator_model.dart';
import 'package:transitly/shared/models/stop_model.dart';

class MockMockDataService extends Mock implements MockDataService {}

class MockOperatorModel extends Mock implements OperatorModel {}

StopModel _stop(String id) => StopModel(
      id: id,
      name: 'Stop $id',
      officialCode: 'STOP-$id',
      lat: 36.68 + Random().nextDouble() * 0.02,
      lng: -6.12 - Random().nextDouble() * 0.02,
      municipality: 'Jerez',
    );

void main() {
  late MockMockDataService mockData;
  late StopMockRepository repo;

  setUp(() {
    mockData = MockMockDataService();
    registerFallbackValue(LatLng(36.7, -6.14));
  });

  group('StopMockRepository provider', () {
    test('byId returns null for unknown id', () async {
      when(() => mockData.getStopById('nonexistent')).thenReturn(null);
      repo = StopMockRepository(mockData);
      final result = await repo.byId('nonexistent');
      expect(result, isNull);
    });

    test('byId returns stop when found', () async {
      final stop = _stop('stop-1');
      when(() => mockData.getStopById('stop-1')).thenReturn(stop);
      repo = StopMockRepository(mockData);
      final result = await repo.byId('stop-1');
      expect(result, isNotNull);
      expect(result!.id, 'stop-1');
    });

    test('byOperator returns empty list for unknown operator', () async {
      final fakeOp = MockOperatorModel();
      when(() => fakeOp.id).thenReturn('other-op');
      when(() => mockData.operator_).thenReturn(fakeOp);
      when(() => mockData.stops).thenReturn([_stop('stop-1')]);
      repo = StopMockRepository(mockData);
      final results = await repo.byOperator('comujesa');
      expect(results, isEmpty);
    });
  });
}
