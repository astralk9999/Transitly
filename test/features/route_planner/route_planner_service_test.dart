import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/features/route_planner/route_planner_service.dart';

class _StubAssetBundle extends AssetBundle {
  _StubAssetBundle(this.content);
  final String content;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => content;
}

Map<String, dynamic> _stop(String code, double lat, double lng, int order) => {
      'name': code,
      'officialCode': code,
      'order': order,
      'lat': lat,
      'lng': lng,
      'municipality': 'Test City',
    };

Map<String, dynamic> _line(String code,
        {required List<Map<String, dynamic>> stops}) =>
    {
      'code': code,
      'name': 'Line $code',
      'color': '#3388FF',
      'serviceType': 'urban',
      'stops': stops,
      'schedules': {
        'weekday': <String>[],
        'saturday': <String>[],
        'sunday_holiday': <String>[],
      },
    };

String _buildJson(Map<String, dynamic> operator, List<Map<String, dynamic>> lines) =>
    jsonEncode({'operator': operator, 'lines': lines});

Map<String, dynamic> _defaultOperator() => {
      'id': 'op-test',
      'name': 'Test Operator',
      'shortName': 'T',
      'slug': 'test-operator',
      'region': 'Test Region',
      'website': '',
      'contactEmail': '',
      'phone': '',
    };

Future<MockDataService> _build(String json) =>
    MockDataService.init(bundle: _StubAssetBundle(json));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RoutePlannerService', () {
    test(
      'Caso A: ruta directa (origen y destino en la misma línea)',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('B', 36.686, -6.129, 1),
            _stop('C', 36.687, -6.128, 2),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('C')!,
        );

        expect(results.length, 1);
        expect(results.first.legs.length, 1);
        expect(results.first.transfers, 0);
        expect(results.first.legs.first.route.code, 'L1');
        expect(results.first.legs.first.boardStop.id, 'A');
        expect(results.first.legs.first.alightStop.id, 'C');
        expect(results.first.legs.first.stopsBetween, 2);
        expect(results.first.legs.first.estimatedMinutes, 4);
        expect(results.first.totalMinutes, 4);
      },
    );

    test(
      'Caso B: 1 transbordo (parada intermedia compartida)',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('B', 36.686, -6.129, 1),
          ]),
          _line('L2', stops: [
            _stop('B', 36.686, -6.129, 0),
            _stop('D', 36.688, -6.127, 1),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('D')!,
        );

        expect(results.length, 1);
        final top = results.first;
        expect(top.legs.length, 2);
        expect(top.transfers, 1);

        expect(top.legs[0].route.code, 'L1');
        expect(top.legs[0].boardStop.id, 'A');
        expect(top.legs[0].alightStop.id, 'B');
        expect(top.legs[0].stopsBetween, 1);
        expect(top.legs[0].estimatedMinutes, 2);

        expect(top.legs[1].route.code, 'L2');
        expect(top.legs[1].boardStop.id, 'B');
        expect(top.legs[1].alightStop.id, 'D');
        expect(top.legs[1].stopsBetween, 1);
        expect(top.legs[1].estimatedMinutes, 2);

        expect(top.totalMinutes, 4);
        expect(top.totalStops, 2);
      },
    );

    test(
      'Caso C: sin rutas que conecten (lista vacía)',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('B', 36.686, -6.129, 1),
          ]),
          _line('L2', stops: [
            _stop('Z', 36.700, -6.100, 0),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('Z')!,
        );

        expect(results, isEmpty);
      },
    );

    test(
      'Caso D: mismo origen y destino (lista vacía)',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('B', 36.686, -6.129, 1),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('A')!,
        );

        expect(results, isEmpty);
      },
    );

    test(
      'Caso E: orden de paradas invertido no devuelve resultado',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('C', 36.687, -6.128, 0),
            _stop('B', 36.686, -6.129, 1),
            _stop('A', 36.685, -6.130, 2),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('C')!,
        );

        expect(results, isEmpty);
      },
    );

    test(
      'Caso F: cruce de 3 líneas, la directa debe ordenarse primero',
      () async {
        final svc = await _build(_buildJson(_defaultOperator(), [
          _line('L1', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('X', 36.686, -6.129, 1),
            _stop('B', 36.687, -6.128, 2),
          ]),
          _line('L2', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('Y', 36.686, -6.129, 1),
            _stop('B', 36.687, -6.128, 2),
          ]),
          _line('L3', stops: [
            _stop('A', 36.685, -6.130, 0),
            _stop('Y', 36.686, -6.129, 1),
            _stop('Z', 36.688, -6.127, 2),
            _stop('B', 36.689, -6.126, 3),
          ]),
        ]));
        final container = ProviderContainer(overrides: [
          mockDataServiceProvider.overrideWithValue(svc),
        ]);
        addTearDown(container.dispose);

        final service = container.read(routePlannerServiceProvider);
        final results = service.plan(
          from: svc.getStopById('A')!,
          to: svc.getStopById('B')!,
        );

        expect(results.isNotEmpty, isTrue);
        final first = results.first;
        expect(first.transfers, 0);
        expect(first.legs.first.stopsBetween, 2);
        expect(first.totalMinutes, 4);

        final minutes = results.map((r) => r.totalMinutes).toList();
        for (var i = 0; i < minutes.length - 1; i++) {
          expect(minutes[i] <= minutes[i + 1], isTrue,
              reason: 'results should be sorted by totalMinutes');
        }
      },
    );
  });
}
