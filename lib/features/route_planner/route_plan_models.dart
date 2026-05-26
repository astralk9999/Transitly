import '../../shared/models/models.dart';

class RoutePlanLeg {
  const RoutePlanLeg({
    required this.route,
    required this.boardStop,
    required this.alightStop,
    required this.stopsBetween,
    required this.estimatedMinutes,
  });

  final RouteModel route;
  final StopModel boardStop;
  final StopModel alightStop;
  final int stopsBetween;
  final int estimatedMinutes;
}

class RoutePlanResult {
  const RoutePlanResult({
    required this.legs,
  });

  final List<RoutePlanLeg> legs;

  int get totalMinutes => legs.fold(0, (sum, leg) => sum + leg.estimatedMinutes);

  int get totalStops => legs.fold(0, (sum, leg) => sum + leg.stopsBetween);

  int get transfers => legs.length - 1;
}
