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
        'name': 'Test Op',
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
      'municipality': 'Test City',
    };

Map<String, dynamic> _line(String code,
        {required List<Map<String, dynamic>> stops}) =>
    {
      'code': code,
      'name': 'Line $code',
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

  group('stopToRouteCodesProvider memo', () {
    test('orden de salida es determinista', () async {
      final svc = await _build(_buildJson([
        _line('L10', stops: [_stop('A', 36.685, -6.13)]),
        _line('L2', stops: [_stop('A', 36.685, -6.13)]),
        _line('L1', stops: [_stop('A', 36.685, -6.13)]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final map = container.read(stopToRouteCodesProvider);
      expect(map['A'], ['L10', 'L2', 'L1']);
    });

    test('stop sin líneas no aparece en el mapa', () async {
      final svc = await _build(_buildJson([
        _line('L1', stops: [_stop('A', 36.685, -6.13)]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final map = container.read(stopToRouteCodesProvider);
      expect(map.containsKey('Z'), isFalse);
    });

    test('líneas con datos reales replican estructura esperada', () async {
      final svc = await _build(_buildJson([
        _line('C1', stops: [
          _stop('STOP_A', 36.685, -6.13),
          _stop('STOP_B', 36.687, -6.12),
          _stop('STOP_C', 36.690, -6.10),
        ]),
      ]));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final map = container.read(stopToRouteCodesProvider);
      expect(map.length, 3);
      expect(map['STOP_A'], ['C1']);
      expect(map['STOP_B'], ['C1']);
      expect(map['STOP_C'], ['C1']);
    });
  });
}
