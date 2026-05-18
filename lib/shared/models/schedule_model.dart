import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'schedule_model.freezed.dart';

@freezed
abstract class ScheduleModel with _$ScheduleModel {
  const ScheduleModel._();

  const factory ScheduleModel({
    required String id,
    required String routeId,
    required String departureTime,
    required DayType dayType,
    @Default(<int>[]) List<int> daysOfWeek,
    @Default(RouteDirection.outbound) RouteDirection direction,
  }) = _ScheduleModel;

  static ScheduleModel fromJson(Map<String, dynamic> j) => ScheduleModel(
        id: j['id'] as String,
        routeId: j['routeId'] as String,
        departureTime: j['departureTime'] as String,
        dayType: DayType.fromString(j['dayType'] as String? ?? 'weekday'),
        daysOfWeek: (j['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const <int>[],
        direction: RouteDirection.fromString(
            j['direction'] as String? ?? 'outbound'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'routeId': routeId,
        'departureTime': departureTime,
        'dayType': dayType.name,
        if (daysOfWeek.isNotEmpty) 'daysOfWeek': daysOfWeek,
        'direction': direction.name,
      };
}
