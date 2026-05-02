import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_error.dart';
import 'package:transitly/data/mock/mock_data_exception.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/shared/models/enums.dart';

const _validMinimalJson = '''
{
  "operator": {
    "id": "op-test",
    "name": "Test Operator",
    "shortName": "TEST",
    "region": "Test Region",
    "website": "",
    "phone": ""
  },
  "lines": []
}
''';

class _StubAssetBundle extends AssetBundle {
  _StubAssetBundle({this.content, this.notFound = false});

  final String? content;
  final bool notFound;

  @override
  Future<ByteData> load(String key) async {
    if (notFound || content == null) {
      throw FlutterError('Unable to load asset: "$key"');
    }
    final bytes = utf8.encode(content!);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (notFound || content == null) {
      throw FlutterError('Unable to load asset: "$key"');
    }
    return content!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataService svc;

  setUpAll(() async {
    svc = await MockDataService.init();
  });

  group('MockDataService loading', () {
    test('loads operator, routes and stops', () {
      expect(svc.operator_.id, isNotEmpty);
      expect(svc.routes, isNotEmpty);
      expect(svc.stops, isNotEmpty);
    });

    test('loads the expected COMUJESA footprint', () {
      // Defensive threshold, not exact counts — the JSON may evolve.
      expect(svc.routes.length, greaterThanOrEqualTo(10));
      expect(svc.stops.length, greaterThanOrEqualTo(100));
    });

    test('every route has at least 2 ordered stops', () {
      for (final r in svc.routes) {
        final stops = svc.getStopsForRoute(r.id);
        expect(stops.length, greaterThanOrEqualTo(2),
            reason: 'route ${r.id} has ${stops.length} stops');
      }
    });

    test('every stop has plausible Jerez-area coordinates', () {
      // Jerez bounding box (generous).
      for (final s in svc.stops) {
        expect(s.lat, inInclusiveRange(36.3, 36.9),
            reason: '${s.id} lat out of range: ${s.lat}');
        expect(s.lng, inInclusiveRange(-6.5, -5.9),
            reason: '${s.id} lng out of range: ${s.lng}');
      }
    });
  });

  group('MockDataService lookups', () {
    test('getRouteById resolves known routes, null on miss', () {
      final first = svc.routes.first;
      expect(svc.getRouteById(first.id)?.id, first.id);
      expect(svc.getRouteById('__nope__'), isNull);
    });

    test('getStopById resolves known stops, null on miss', () {
      final first = svc.stops.first;
      expect(svc.getStopById(first.id)?.id, first.id);
      expect(svc.getStopById('__nope__'), isNull);
    });

    test('getSchedulesForRoute filters by day type when given', () {
      final route = svc.routes.firstWhere(
        (r) => (svc.schedules[r.id] ?? []).isNotEmpty,
        orElse: () => svc.routes.first,
      );
      final all = svc.getSchedulesForRoute(route.id);
      final weekday =
          svc.getSchedulesForRoute(route.id, dayType: DayType.weekday);
      expect(all.length, greaterThanOrEqualTo(weekday.length));
      for (final s in weekday) {
        expect(s.dayType, DayType.weekday);
      }
    });

    test('getNearbyStops returns requested count sorted by distance', () {
      // Jerez city centre; keeps the test independent of asset ordering
      // and of stops that share exact coordinates.
      const centerLat = 36.6866;
      const centerLng = -6.1378;
      final nearby = svc.getNearbyStops(centerLat, centerLng, 5);
      expect(nearby.length, 5);

      double distSq(double la, double lo) {
        final dLat = la - centerLat;
        final dLng = lo - centerLng;
        return dLat * dLat + dLng * dLng;
      }

      for (int i = 1; i < nearby.length; i++) {
        final prev = distSq(nearby[i - 1].lat, nearby[i - 1].lng);
        final cur = distSq(nearby[i].lat, nearby[i].lng);
        expect(cur, greaterThanOrEqualTo(prev),
            reason: 'order broken at index $i');
      }
    });
  });

  group('MockDataService polyline bounds', () {
    test('every polyline has a valid bounding box', () {
      for (final routeId in svc.polylinesLod.keys) {
        final b = svc.routeBounds[routeId];
        expect(b, isNotNull, reason: 'no bounds for $routeId');
        expect(b!.length, 4);
        final [minLat, minLng, maxLat, maxLng] = b;
        expect(minLat, lessThanOrEqualTo(maxLat));
        expect(minLng, lessThanOrEqualTo(maxLng));
      }
    });
  });

  group('MockDataService error handling', () {
    test('valid bundle parses without throwing', () async {
      final svc = await MockDataService.init(
        bundle: _StubAssetBundle(content: _validMinimalJson),
      );
      expect(svc.operator_.id, 'op-test');
      expect(svc.routes, isEmpty);
      expect(svc.stops, isEmpty);
    });

    test('missing asset throws MockDataException(assetNotFound)', () async {
      await expectLater(
        () => MockDataService.init(
          bundle: _StubAssetBundle(notFound: true),
        ),
        throwsA(
          isA<MockDataException>().having(
            (e) => e.error,
            'error',
            MockDataError.assetNotFound,
          ),
        ),
      );
    });

    test('malformed JSON throws MockDataException(parseError)', () async {
      await expectLater(
        () => MockDataService.init(
          bundle: _StubAssetBundle(content: 'not valid json {'),
        ),
        throwsA(
          isA<MockDataException>().having(
            (e) => e.error,
            'error',
            MockDataError.parseError,
          ),
        ),
      );
    });

    test('non-object root throws MockDataException(parseError)', () async {
      await expectLater(
        () => MockDataService.init(
          bundle: _StubAssetBundle(content: '[1, 2, 3]'),
        ),
        throwsA(
          isA<MockDataException>().having(
            (e) => e.error,
            'error',
            MockDataError.parseError,
          ),
        ),
      );
    });

    test('missing top-level key throws MockDataException(unexpectedSchema)',
        () async {
      await expectLater(
        () => MockDataService.init(
          bundle: _StubAssetBundle(content: '{"foo": "bar"}'),
        ),
        throwsA(
          isA<MockDataException>().having(
            (e) => e.error,
            'error',
            MockDataError.unexpectedSchema,
          ),
        ),
      );
    });

    test('schema mismatch in nested fields throws unexpectedSchema', () async {
      // operator missing required "id" field → TypeError that _parse wraps.
      await expectLater(
        () => MockDataService.init(
          bundle: _StubAssetBundle(
            content: '{"operator": {}, "lines": []}',
          ),
        ),
        throwsA(
          isA<MockDataException>().having(
            (e) => e.error,
            'error',
            MockDataError.unexpectedSchema,
          ),
        ),
      );
    });
  });
}
