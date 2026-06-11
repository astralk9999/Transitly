import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/providers/derived/active_trip_providers.dart';

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

/// Cada parada necesita coordenada propia: MockDataService deduplica paradas
/// físicas por coordenada exacta, así que coordenadas repetidas se fusionan.
Map<String, dynamic> _stop(String code, [int order = 1]) => {
      'name': code,
      'officialCode': code,
      'order': order,
      'lat': 36.685 + order * 0.001,
      'lng': -6.13,
      'municipality': 'Jerez',
    };

Map<String, dynamic> _line(String code,
        {required List<Map<String, dynamic>> stops}) =>
    {
      'code': code,
      'name': 'Línea $code',
      'color': '#FF0000',
      'serviceType': 'urban',
      'stops': stops,
      'schedules': {
        'weekday': <String>[],
        'saturday': <String>[],
        'sunday_holiday': <String>[],
      },
    };

Map<String, dynamic> _trip({
  required String id,
  required String routeId,
  int? currentStopIndex,
  String status = 'onTime',
}) =>
    {
      'id': id,
      'lineCode': routeId,
      'status': status,
      'capacity': 'seatsAvailable',
      'currentStopIndex': currentStopIndex,
    };

String _buildJson({
  List<Map<String, dynamic>> lines = const [],
  List<Map<String, dynamic>> activeTrips = const [],
}) =>
    jsonEncode({
      'operator': {
        'id': 'op-test',
        'name': 'Test',
        'shortName': 'T',
        'region': 'Test',
        'website': '',
        'phone': '',
      },
      'lines': lines,
      'activeTrips': activeTrips,
    });

Future<MockDataService> _build(String json) =>
    MockDataService.init(bundle: _StubAssetBundle(json));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('activeTripDetailProvider', () {
    test('tripId desconocido → null', () async {
      final svc = await _build(_buildJson());
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(activeTripDetailProvider('nope')), isNull);
    });

    test('trip existe pero ruta sin stops → null', () async {
      final svc = await _build(_buildJson(
        lines: [_line('L1', stops: const [])],
        activeTrips: [_trip(id: 't1', routeId: 'L1')],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(activeTripDetailProvider('t1')), isNull);
    });

    test('caso normal: currentIdx, firstStop, lastStop, nextStop', () async {
      final svc = await _build(_buildJson(
        lines: [
          _line('L1', stops: [
            _stop('A', 1),
            _stop('B', 2),
            _stop('C', 3),
            _stop('D', 4),
          ]),
        ],
        activeTrips: [
          _trip(id: 't1', routeId: 'L1', currentStopIndex: 1),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final detail = container.read(activeTripDetailProvider('t1'));
      expect(detail, isNotNull);
      expect(detail!.currentIdx, 1);
      expect(detail.firstStop.id, 'A');
      expect(detail.lastStop.id, 'D');
      expect(detail.nextStop?.id, 'C');
      expect(detail.trip.id, 't1');
    });

    test('última parada → nextStop null', () async {
      final svc = await _build(_buildJson(
        lines: [
          _line('L1', stops: [_stop('A', 1), _stop('B', 2)]),
        ],
        activeTrips: [
          _trip(id: 't1', routeId: 'L1', currentStopIndex: 1),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final detail = container.read(activeTripDetailProvider('t1'));
      expect(detail!.nextStop, isNull);
      expect(detail.firstStop.id, 'A');
      expect(detail.lastStop.id, 'B');
    });

    test('ruta con 1 stop: firstStop == lastStop, nextStop null', () async {
      final svc = await _build(_buildJson(
        lines: [
          _line('L1', stops: [_stop('SOLO')]),
        ],
        activeTrips: [
          _trip(id: 't1', routeId: 'L1', currentStopIndex: 0),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final detail = container.read(activeTripDetailProvider('t1'));
      expect(detail!.firstStop.id, 'SOLO');
      expect(detail.lastStop.id, 'SOLO');
      expect(detail.nextStop, isNull);
    });

    test('currentStopIndex null → currentIdx=0', () async {
      final svc = await _build(_buildJson(
        lines: [
          _line('L1', stops: [_stop('A', 1), _stop('B', 2), _stop('C', 3)]),
        ],
        activeTrips: [
          _trip(id: 't1', routeId: 'L1'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final detail = container.read(activeTripDetailProvider('t1'));
      expect(detail!.currentIdx, 0);
      expect(detail.nextStop?.id, 'B');
    });
  });
}
