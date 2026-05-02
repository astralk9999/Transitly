import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/providers/derived/home_providers.dart';

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

/// Construye un JSON sintético compatible con el parser de
/// [MockDataService]. Todos los argumentos son opcionales para permitir
/// componer escenarios mínimos.
String _buildJson({
  List<Map<String, dynamic>> lines = const [],
  List<Map<String, dynamic>> favorites = const [],
  List<Map<String, dynamic>> alerts = const [],
  Map<String, dynamic>? passenger,
}) {
  return jsonEncode({
    'operator': {
      'id': 'op-test',
      'name': 'Test',
      'shortName': 'T',
      'region': 'Test',
      'website': '',
      'phone': '',
    },
    'lines': lines,
    'favorites': favorites,
    'alerts': alerts,
    if (passenger != null)
      'userProfiles': {'passenger': passenger},
  });
}

Map<String, dynamic> _stop(String code, double lat, double lng,
        {String? name}) =>
    {
      'name': name ?? code,
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

Map<String, dynamic> _passenger({String id = 'user-1'}) => {
      'id': id,
      'username': id,
      'displayName': 'Carlos',
      'email': '$id@test.com',
      'role': 'passenger',
      'reputation': 10,
      'reputationLevel': 'contributor',
    };

Map<String, dynamic> _favorite({
  required String id,
  required String userId,
  required String routeId,
  String? stopCode,
}) =>
    {
      'id': id,
      'userId': userId,
      'lineCode': routeId,
      if (stopCode != null) 'stopCode': stopCode,
    };

Map<String, dynamic> _alert({
  required String id,
  required String routeId,
  String type = 'info',
}) =>
    {
      'id': id,
      'type': type,
      'lineCode': routeId,
      'title': 'Aviso $id',
      'description': '',
    };

Future<MockDataService> _build(String jsonStr) =>
    MockDataService.init(bundle: _StubAssetBundle(jsonStr));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('homeFavRouteIdsProvider', () {
    test('sin favoritas → vacío', () async {
      final svc = await _build(_buildJson(passenger: _passenger()));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeFavRouteIdsProvider), isEmpty);
    });

    test('múltiples favoritas → set deduplicado', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        favorites: [
          _favorite(id: 'f1', userId: 'user-1', routeId: 'L1'),
          _favorite(id: 'f2', userId: 'user-1', routeId: 'L3'),
          _favorite(id: 'f3', userId: 'user-1', routeId: 'L1'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeFavRouteIdsProvider), {'L1', 'L3'});
    });

    test('ignora favoritas de otros usuarios', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(id: 'user-1'),
        favorites: [
          _favorite(id: 'f1', userId: 'user-1', routeId: 'L1'),
          _favorite(id: 'f2', userId: 'user-other', routeId: 'L99'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeFavRouteIdsProvider), {'L1'});
    });
  });

  group('homeHabitualStopProvider', () {
    test('sin favoritas → null', () async {
      final svc = await _build(_buildJson(passenger: _passenger()));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeHabitualStopProvider), isNull);
    });

    test('favorita con stopCode válido → resuelve StopModel', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        lines: [
          _line('L1', stops: [
            _stop('S-001', 36.685, -6.13),
            _stop('S-002', 36.687, -6.12),
          ]),
        ],
        favorites: [
          _favorite(
              id: 'f1', userId: 'user-1', routeId: 'L1', stopCode: 'S-001'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final stop = container.read(homeHabitualStopProvider);
      expect(stop, isNotNull);
      expect(stop!.id, 'S-001');
    });

    test('favorita con stopCode inexistente → null', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        favorites: [
          _favorite(
              id: 'f1', userId: 'user-1', routeId: 'L1', stopCode: 'GHOST'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeHabitualStopProvider), isNull);
    });
  });

  group('homeNearbyStopsProvider', () {
    test('paradas vacías → lista vacía', () async {
      final svc = await _build(_buildJson(passenger: _passenger()));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(homeNearbyStopsProvider(
          (center: const LatLng(36.685, -6.126), count: 3)));
      expect(result, isEmpty);
    });

    test('orden por distancia al centro', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        lines: [
          _line('L1', stops: [
            _stop('FAR', 36.800, -6.000),
            _stop('NEAR', 36.685, -6.126),
            _stop('MID', 36.720, -6.100),
          ]),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(homeNearbyStopsProvider(
          (center: const LatLng(36.685, -6.126), count: 3)));
      expect(result.map((s) => s.id).toList(), ['NEAR', 'MID', 'FAR']);
    });

    test('count > paradas disponibles → devuelve todas', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        lines: [
          _line('L1', stops: [
            _stop('A', 36.685, -6.126),
            _stop('B', 36.690, -6.130),
          ]),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final result = container.read(homeNearbyStopsProvider(
          (center: const LatLng(36.685, -6.126), count: 10)));
      expect(result.length, 2);
    });
  });

  group('homeFavAlertsProvider', () {
    test('sin favoritas → vacío aunque haya alertas', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        alerts: [_alert(id: 'a1', routeId: 'L1')],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      expect(container.read(homeFavAlertsProvider), isEmpty);
    });

    test('combina alertas de las rutas favoritas', () async {
      final svc = await _build(_buildJson(
        passenger: _passenger(),
        favorites: [
          _favorite(id: 'f1', userId: 'user-1', routeId: 'L1'),
          _favorite(id: 'f2', userId: 'user-1', routeId: 'L3'),
        ],
        alerts: [
          _alert(id: 'a1', routeId: 'L1'),
          _alert(id: 'a2', routeId: 'L3', type: 'warning'),
          _alert(id: 'a3', routeId: 'L99'),
        ],
      ));
      final container = ProviderContainer(overrides: [
        mockDataServiceProvider.overrideWithValue(svc),
      ]);
      addTearDown(container.dispose);

      final ids =
          container.read(homeFavAlertsProvider).map((a) => a.id).toSet();
      expect(ids, {'a1', 'a2'});
    });
  });
}
