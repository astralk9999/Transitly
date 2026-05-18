import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'route_stop_model.freezed.dart';

@freezed
abstract class RouteStopModel with _$RouteStopModel {
  const RouteStopModel._();

  const factory RouteStopModel({
    required String routeId,
    required String stopId,
    required int orderIndex,
    @Default(RouteDirection.outbound) RouteDirection direction,
    int? timeFromStartMinutes,
    double? distanceFromStartKm,
  }) = _RouteStopModel;

  static RouteStopModel fromJson(Map<String, dynamic> j,
          {required String routeId}) =>
      RouteStopModel(
        routeId: routeId,
        stopId: j['officialCode'] as String? ?? j['name'] as String,
        orderIndex: j['order'] as int,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'routeId': routeId,
        'stopId': stopId,
        'order': orderIndex,
        'direction': direction.name,
        if (timeFromStartMinutes != null)
          'timeFromStartMinutes': timeFromStartMinutes,
        if (distanceFromStartKm != null)
          'distanceFromStartKm': distanceFromStartKm,
      };
}
