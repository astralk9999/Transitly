import 'package:freezed_annotation/freezed_annotation.dart';

part 'habitual_trip_model.freezed.dart';

@freezed
abstract class HabitualTripModel with _$HabitualTripModel {
  const HabitualTripModel._();

  const factory HabitualTripModel({
    required String id,
    required String userId,
    required String routeId,
    required String stopId,
    String? destinationStopId,
    String? timeWindowStart,
    String? timeWindowEnd,
    @Default([]) List<int> daysOfWeek,
    @Default(false) bool notify,
    @Default(5) int notifyMinutesBefore,
  }) = _HabitualTripModel;

  static HabitualTripModel fromJson(Map<String, dynamic> j) =>
      HabitualTripModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        routeId: j['routeId'] as String,
        stopId: j['stopId'] as String,
        destinationStopId: j['destinationStopId'] as String?,
        timeWindowStart: j['timeWindowStart'] as String?,
        timeWindowEnd: j['timeWindowEnd'] as String?,
        daysOfWeek: (j['daysOfWeek'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [],
        notify: j['notify'] as bool? ?? false,
        notifyMinutesBefore: j['notifyMinutesBefore'] as int? ?? 5,
      );
}
