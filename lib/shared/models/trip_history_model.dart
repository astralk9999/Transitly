import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_history_model.freezed.dart';

@freezed
abstract class TripHistoryModel with _$TripHistoryModel {
  const TripHistoryModel._();

  const factory TripHistoryModel({
    required String id,
    required String userId,
    required String routeId,
    String? fromStopId,
    String? toStopId,
    required DateTime startedAt,
    double? cost,
    double? distanceKm,
    double? co2SavedKg,
  }) = _TripHistoryModel;

  static TripHistoryModel fromJson(Map<String, dynamic> j) =>
      TripHistoryModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        routeId: j['lineCode'] as String,
        fromStopId: j['boardingStop'] as String?,
        toStopId: j['alightingStop'] as String?,
        startedAt:
            DateTime.parse('${j['date']}T${j['boardingTime']}:00'),
        cost: (j['fare'] as num?)?.toDouble(),
      );
}
