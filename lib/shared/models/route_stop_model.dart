import 'enums.dart';

class RouteStopModel {
  const RouteStopModel({
    required this.routeId,
    required this.stopId,
    required this.orderIndex,
    this.direction = RouteDirection.outbound,
    this.timeFromStartMinutes,
    this.distanceFromStartKm,
  });

  final String routeId;
  final String stopId;
  final int orderIndex;
  final RouteDirection direction;
  final int? timeFromStartMinutes;
  final double? distanceFromStartKm;

  factory RouteStopModel.fromJson(Map<String, dynamic> j,
          {required String routeId}) =>
      RouteStopModel(
        routeId: routeId,
        stopId: j['officialCode'] as String? ?? j['name'] as String,
        orderIndex: j['order'] as int,
      );
}
