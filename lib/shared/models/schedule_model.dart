import 'enums.dart';

class ScheduleModel {
  const ScheduleModel({
    required this.id,
    required this.routeId,
    required this.departureTime,
    required this.dayType,
    this.daysOfWeek = const [],
    this.direction = RouteDirection.outbound,
  });

  final String id;
  final String routeId;
  final String departureTime;
  final DayType dayType;
  final List<int> daysOfWeek;
  final RouteDirection direction;
}
