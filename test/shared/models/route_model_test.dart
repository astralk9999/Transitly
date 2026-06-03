import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_model.dart';

void main() {
  group('RouteModel', () {
    test('fromJson creates valid route', () {
      final json = {
        'code': 'L1',
        'name': 'Línea 1',
        'serviceType': 'urban',
        'color': '#FF0000',
      };
      final route = RouteModel.fromJson(json);
      expect(route.id, 'L1');
      expect(route.code, 'L1');
      expect(route.name, 'Línea 1');
      expect(route.serviceType, ServiceType.urban);
      expect(route.routeColor, const Color(0xFFFF0000));
      expect(route.hasReturn, true);
      expect(route.isCircular, false);
      expect(route.status, RouteStatus.official);
      expect(route.active, true);
      expect(route.operatorId, 'comujesa');
    });

    test('toJson roundtrips correctly', () {
      final route = const RouteModel(
        id: 'L2',
        operatorId: 'comujesa',
        code: 'L2',
        name: 'Línea 2',
        serviceType: ServiceType.metropolitan,
        routeColor: Color(0xFF00FF00),
      );
      final json = route.toJson();
      expect(json['code'], 'L2');
      expect(json['name'], 'Línea 2');
      expect(json['serviceType'], 'metropolitan');
      expect(json['color'], contains('00FF00'));
      expect(json['hasReturn'], true);
      expect(json['isCircular'], false);
      expect(json['active'], true);
    });

    test('copyWith preserves unchanged fields', () {
      final route = const RouteModel(
        id: 'L3',
        operatorId: 'comujesa',
        code: 'L3',
        name: 'Original',
        serviceType: ServiceType.interurban,
        routeColor: Color(0xFF0000FF),
      );
      final copy = route.copyWith(name: 'Renamed');
      expect(copy.name, 'Renamed');
      expect(copy.code, 'L3');
      expect(copy.id, 'L3');
      expect(copy.serviceType, ServiceType.interurban);
      expect(copy.routeColor, const Color(0xFF0000FF));
    });
  });
}
