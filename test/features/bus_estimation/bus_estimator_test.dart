import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/features/bus_estimation/bus_estimator.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_model.dart';
import 'package:transitly/shared/models/route_stop_model.dart';
import 'package:transitly/shared/models/schedule_model.dart';
import 'package:transitly/shared/models/stop_model.dart';

/// Tres paradas alineadas sobre el ecuador yendo al este. 0.01° de
/// longitud en el ecuador ≈ 1113 m, así que A→B y B→C ≈ 1113 m cada uno.
const _routeId = 'r1';

const _route = RouteModel(
  id: _routeId,
  operatorId: 'op1',
  code: 'L1',
  name: 'Línea 1',
  serviceType: ServiceType.urban,
  routeColor: Color(0xFF1565C0),
);

StopModel _stop(String id, double lng) => StopModel(
      id: id,
      name: 'Stop $id',
      officialCode: id,
      lat: 0.0,
      lng: lng,
      municipality: 'Jerez',
    );

final _stops = [
  _stop('A', 0.00),
  _stop('B', 0.01),
  _stop('C', 0.02),
];

List<RouteStopModel> _orderedStops({int? lastTimeFromStart}) => [
      const RouteStopModel(routeId: _routeId, stopId: 'A', orderIndex: 0),
      const RouteStopModel(routeId: _routeId, stopId: 'B', orderIndex: 1),
      RouteStopModel(
        routeId: _routeId,
        stopId: 'C',
        orderIndex: 2,
        timeFromStartMinutes: lastTimeFromStart,
      ),
    ];

const _schedule = ScheduleModel(
  id: 's1',
  routeId: _routeId,
  departureTime: '10:00',
  dayType: DayType.weekday,
);

void main() {
  group('estimateBusPosition', () {
    test('antes de la salida → bus en la primera parada, ETA 0', () {
      final result = estimateBusPosition(
        route: _route,
        schedule: _schedule,
        orderedStops: _orderedStops(),
        stops: _stops,
        now: DateTime(2026, 5, 15, 9, 50),
      );

      expect(result, isNotNull);
      expect(result!.nextStopId, 'A');
      expect(result.nextStopEtaMinutes, 0);
      expect(result.position.latitude, closeTo(0.0, 1e-9));
      expect(result.position.longitude, closeTo(0.0, 1e-9));
      expect(result.routeId, _routeId);
    });

    test('a mitad del primer tramo → interpola posición y apunta a B', () {
      // 60 s tras la salida, 10 m/s, sin dwell → 600 m recorridos.
      // Tramo A→B ≈ 1113 m, fracción ≈ 0.539.
      final result = estimateBusPosition(
        route: _route,
        schedule: _schedule,
        orderedStops: _orderedStops(),
        stops: _stops,
        now: DateTime(2026, 5, 15, 10, 1, 0),
        avgSpeedMps: 10,
        dwellTimeSeconds: 0,
      );

      expect(result, isNotNull);
      expect(result!.nextStopId, 'B');
      expect(result.position.latitude, closeTo(0.0, 1e-6));
      // 600/1113 * 0.01° ≈ 0.00539°
      expect(result.position.longitude, closeTo(0.00539, 5e-4));
      // Rumbo hacia el este ≈ 90°.
      expect(result.bearing, closeTo(90.0, 1.0));
      expect(result.nextStopEtaMinutes, greaterThanOrEqualTo(0));
    });

    test('mucho después → bus en la última parada, sin siguiente parada', () {
      final result = estimateBusPosition(
        route: _route,
        schedule: _schedule,
        orderedStops: _orderedStops(),
        stops: _stops,
        now: DateTime(2026, 5, 15, 12, 0, 0),
        avgSpeedMps: 10,
        dwellTimeSeconds: 0,
      );

      expect(result, isNotNull);
      expect(result!.nextStopId, isNull);
      expect(result.nextStopEtaMinutes, 0);
      expect(result.position.longitude, closeTo(0.02, 1e-9));
    });

    test('avgSpeedMps explícito se respeta (más rápido ⇒ más lejos)', () {
      EstimatedBus run(double speed) => estimateBusPosition(
            route: _route,
            schedule: _schedule,
            orderedStops: _orderedStops(),
            stops: _stops,
            now: DateTime(2026, 5, 15, 10, 1, 0),
            avgSpeedMps: speed,
            dwellTimeSeconds: 0,
          )!;

      final slow = run(5);
      final fast = run(15);
      expect(fast.position.longitude, greaterThan(slow.position.longitude));
    });

    test('sin paradas y antes de la salida → null (sin excepción)', () {
      final result = estimateBusPosition(
        route: _route,
        schedule: _schedule,
        orderedStops: const [],
        stops: const [],
        now: DateTime(2026, 5, 15, 9, 0, 0),
      );
      expect(result, isNull);
    });

    test('velocidad estimada por defecto usa timeFromStartMinutes', () {
      // Sin avgSpeedMps: la velocidad se deriva de la distancia total
      // (~2226 m) y del tiempo de la última parada (4 min) ≈ 9.3 m/s.
      final result = estimateBusPosition(
        route: _route,
        schedule: _schedule,
        orderedStops: _orderedStops(lastTimeFromStart: 4),
        stops: _stops,
        now: DateTime(2026, 5, 15, 10, 2, 0),
        dwellTimeSeconds: 0,
      );

      expect(result, isNotNull);
      // 9.27 m/s * 120 s ≈ 1113 m ≈ final del tramo A→B / inicio B→C.
      expect(result!.position.longitude, closeTo(0.01, 2e-3));
    });
  });
}
