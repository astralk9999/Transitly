import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/providers/derived/schedule_providers.dart';

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

String _buildJson({
  required String routeCode,
  required List<String> weekday,
  List<String> saturday = const [],
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
      'lines': [
        {
          'code': routeCode,
          'name': 'Línea $routeCode',
          'color': '#FF0000',
          'serviceType': 'urban',
          'stops': [
            {
              'name': 'A',
              'officialCode': 'A',
              'order': 1,
              'lat': 36.685,
              'lng': -6.13,
              'municipality': 'Jerez',
            },
          ],
          'schedules': {
            'weekday': weekday,
            'saturday': saturday,
            'sunday_holiday': <String>[],
          },
        },
      ],
    });

Future<MockDataService> _build(String json) =>
    MockDataService.init(bundle: _StubAssetBundle(json));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('upcomingDeparturesForRouteProvider', () {
    test('ruta sin schedules → lista vacía', () async {
      final svc = await _build(_buildJson(
        routeCode: 'L1',
        weekday: const [],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: 3, dayType: DayType.weekday)));
      expect(result, isEmpty);
    });

    test('count=null → todas las salidas del día ordenadas', () async {
      final svc = await _build(_buildJson(
        routeCode: 'L1',
        weekday: const ['09:00', '07:30', '12:15', '08:00'],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: null, dayType: DayType.weekday)));
      expect(result.map((s) => s.departureTime).toList(),
          ['07:30', '08:00', '09:00', '12:15']);
    });

    test('count=N → primeros N ordenados', () async {
      final svc = await _build(_buildJson(
        routeCode: 'L1',
        weekday: const ['09:00', '07:30', '12:15', '08:00', '13:00'],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: 3, dayType: DayType.weekday)));
      expect(result.map((s) => s.departureTime).toList(),
          ['07:30', '08:00', '09:00']);
    });

    test('count > total → todas (sin overflow)', () async {
      final svc = await _build(_buildJson(
        routeCode: 'L1',
        weekday: const ['09:00', '07:30'],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: 10, dayType: DayType.weekday)));
      expect(result.length, 2);
    });

    test('filtra por dayType', () async {
      final svc = await _build(_buildJson(
        routeCode: 'L1',
        weekday: const ['07:30', '08:00'],
        saturday: const ['10:00'],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final wk = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: null, dayType: DayType.weekday)));
      final sat = container.read(upcomingDeparturesForRouteProvider(
          (routeId: 'L1', count: null, dayType: DayType.saturday)));
      expect(wk.length, 2);
      expect(sat.map((s) => s.departureTime).toList(), ['10:00']);
    });

    test('defaultUpcomingCount expuesto = 3', () {
      expect(defaultUpcomingCount, 3);
    });
  });
}
