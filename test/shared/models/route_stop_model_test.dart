import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/route_stop_model.dart';

void main() {
  group('RouteStopModel', () {
    test('fromJson with officialCode field', () {
      final json = {
        'officialCode': 'STOP-042',
        'order': 3,
      };

      final model = RouteStopModel.fromJson(json, routeId: 'L1');

      expect(model.routeId, 'L1');
      expect(model.stopId, 'STOP-042');
      expect(model.orderIndex, 3);
    });

    test('fromJson falls back to name when officialCode is missing', () {
      final json = {
        'name': 'Plaza Nueva',
        'order': 1,
      };

      final model = RouteStopModel.fromJson(json, routeId: 'C3');

      expect(model.routeId, 'C3');
      expect(model.stopId, 'Plaza Nueva');
      expect(model.orderIndex, 1);
    });

    test('orderIndex reflects the stop sequence', () {
      final first = const RouteStopModel(
        routeId: 'L1',
        stopId: 'S-A',
        orderIndex: 0,
      );
      final second = const RouteStopModel(
        routeId: 'L1',
        stopId: 'S-B',
        orderIndex: 5,
      );
      final third = const RouteStopModel(
        routeId: 'L1',
        stopId: 'S-C',
        orderIndex: 10,
      );

      expect(first.orderIndex, lessThan(second.orderIndex));
      expect(second.orderIndex, lessThan(third.orderIndex));
    });
  });
}
