import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/providers/route_lookup_providers.dart';

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

String _buildJson(List<Map<String, dynamic>> lines) => jsonEncode({
      'operator': {
        'id': 'op-test',
        'name': 'Test',
        'shortName': 'T',
        'region': 'Test',
        'website': '',
        'phone': '',
      },
      'lines': lines,
    });

Map<String, dynamic> _stop(String code, double lat, double lng) => {
      'name': code,
      'officialCode': code,
      'order': 1,
      'lat': lat,
      'lng': lng,
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

Future<MockDataService> _build(String json) =>
    MockDataService.init(bundle: _StubAssetBundle(json));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('stopToRouteCodesProvider', () {
    test('sin paradas → mapa vacío', () async {
      final svc = await _build(_buildJson(const []));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(stopToRouteCodesProvider), isEmpty);
    });

    test('parada en una sola línea → un único code', () async {
      final svc = await _build(_buildJson([
        _line('L1', stops: [
          _stop('A', 36.685, -6.13),
          _stop('B', 36.687, -6.12),
        ]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final map = container.read(stopToRouteCodesProvider);
      expect(map['A'], ['L1']);
      expect(map['B'], ['L1']);
    });

    test('parada compartida → todos los codes', () async {
      final svc = await _build(_buildJson([
        _line('L1', stops: [
          _stop('SHARED', 36.685, -6.13),
          _stop('A1', 36.687, -6.12),
        ]),
        _line('L2', stops: [
          _stop('SHARED', 36.685, -6.13),
          _stop('A2', 36.690, -6.10),
        ]),
        _line('L3', stops: [
          _stop('SHARED', 36.685, -6.13),
        ]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final map = container.read(stopToRouteCodesProvider);
      expect(map['SHARED'], containsAll(['L1', 'L2', 'L3']));
      expect(map['SHARED']!.length, 3);
      expect(map['A1'], ['L1']);
      expect(map['A2'], ['L2']);
    });

    test('memoiza: dos lecturas devuelven la misma instancia', () async {
      final svc = await _build(_buildJson([
        _line('L1', stops: [_stop('A', 36.685, -6.13)]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final first = container.read(stopToRouteCodesProvider);
      final second = container.read(stopToRouteCodesProvider);
      expect(identical(first, second), isTrue);
    });
  });
}
