import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_data_service.dart';
import '../../shared/models/models.dart';
import 'route_plan_models.dart';

/// Heurística A→B con transbordos sobre datos mock.
///
/// No es un Dijkstra completo: recorre solo rutas directas y con 1 transbordo.
/// El coste se estima como 2 minutos por parada (convención usada en
/// [MockDataService.getNextDepartures]).
class RoutePlannerService {
  RoutePlannerService(this._mock);

  final MockDataService _mock;

  List<RoutePlanResult> plan({
    required StopModel from,
    required StopModel to,
    int maxTransfers = 1,
  }) {
    if (from.id == to.id) return [];

    final results = <RoutePlanResult>[];

    _addDirectRoutes(results, from, to);

    if (maxTransfers >= 1) {
      _addOneTransferRoutes(results, from, to);
    }

    results.sort((a, b) => a.totalMinutes.compareTo(b.totalMinutes));

    if (results.length > 5) {
      return results.sublist(0, 5);
    }
    return results;
  }

  void _addDirectRoutes(
    List<RoutePlanResult> results,
    StopModel from,
    StopModel to,
  ) {
    for (final routeId in _mock.getRoutesServingStop(from.id)) {
      if (!_mock.getRoutesServingStop(to.id).contains(routeId)) continue;

      final ordered = _mock.getOrderedRouteStops(routeId);
      final fromIdx = _findStopIndex(ordered, from.id);
      final toIdx = _findStopIndex(ordered, to.id);
      if (fromIdx < 0 || toIdx < 0 || fromIdx >= toIdx) continue;

      final route = _mock.getRouteById(routeId);
      if (route == null) continue;

      final stopsBetween = toIdx - fromIdx;

      results.add(
        RoutePlanResult(
          legs: [
            RoutePlanLeg(
              route: route,
              boardStop: from,
              alightStop: to,
              stopsBetween: stopsBetween,
              estimatedMinutes: stopsBetween * 2,
            ),
          ],
        ),
      );
    }
  }

  void _addOneTransferRoutes(
    List<RoutePlanResult> results,
    StopModel from,
    StopModel to,
  ) {
    for (final r1Id in _mock.getRoutesServingStop(from.id)) {
      final r1Ordered = _mock.getOrderedRouteStops(r1Id);
      final fromIdx = _findStopIndex(r1Ordered, from.id);
      if (fromIdx < 0) continue;

      final r1 = _mock.getRouteById(r1Id);
      if (r1 == null) continue;

      for (var i = fromIdx + 1; i < r1Ordered.length; i++) {
        final xStopId = r1Ordered[i].stopId;
        if (xStopId == to.id) continue;

        for (final r2Id in _mock.getRoutesServingStop(xStopId)) {
          if (r2Id == r1Id) continue;
          if (!_mock.getRoutesServingStop(to.id).contains(r2Id)) continue;

          final r2Ordered = _mock.getOrderedRouteStops(r2Id);
          final xIdx = _findStopIndex(r2Ordered, xStopId);
          final toIdx = _findStopIndex(r2Ordered, to.id);
          if (xIdx < 0 || toIdx < 0 || xIdx >= toIdx) continue;

          final xStop = _mock.getStopById(xStopId);
          final r2 = _mock.getRouteById(r2Id);
          if (xStop == null || r2 == null) continue;

          final leg1Stops = i - fromIdx;
          final leg2Stops = toIdx - xIdx;

          results.add(
            RoutePlanResult(
              legs: [
                RoutePlanLeg(
                  route: r1,
                  boardStop: from,
                  alightStop: xStop,
                  stopsBetween: leg1Stops,
                  estimatedMinutes: leg1Stops * 2,
                ),
                RoutePlanLeg(
                  route: r2,
                  boardStop: xStop,
                  alightStop: to,
                  stopsBetween: leg2Stops,
                  estimatedMinutes: leg2Stops * 2,
                ),
              ],
            ),
          );
        }
      }
    }
  }

  int _findStopIndex(List<RouteStopModel> ordered, String stopId) {
    for (var i = 0; i < ordered.length; i++) {
      if (ordered[i].stopId == stopId) return i;
    }
    return -1;
  }
}

final routePlannerServiceProvider = Provider<RoutePlannerService>((ref) {
  return RoutePlannerService(ref.watch(mockDataServiceProvider));
});
