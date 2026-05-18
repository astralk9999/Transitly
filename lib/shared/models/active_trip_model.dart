import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'active_trip_model.freezed.dart';

@freezed
abstract class ActiveTripModel with _$ActiveTripModel {
  const ActiveTripModel._();

  const factory ActiveTripModel({
    required String id,
    required String routeId,
    String? driverId,
    DateTime? startedAt,
    double? currentLat,
    double? currentLng,
    double? currentBearing,
    int? currentStopIndex,
    required TripStatus status,
    @Default(0) int delayMinutes,
    required BusCapacity capacity,
    String? vehicleNumber,
    String? driverMessage,
  }) = _ActiveTripModel;

  static ActiveTripModel fromJson(Map<String, dynamic> j) {
    final pos = j['currentPosition'] as Map<String, dynamic>?;
    final delay = j['delay'] as int? ?? 0;
    final rawStatus = j['status'] as String? ?? 'onTime';
    final status = rawStatus == 'cancelled'
        ? TripStatus.cancelled
        : delay > 0
            ? TripStatus.delay
            : TripStatus.onTime;

    return ActiveTripModel(
      id: j['id'] as String,
      routeId: j['lineCode'] as String,
      driverId: j['driverName'] as String?,
      startedAt: j['lastUpdated'] != null
          ? DateTime.tryParse(j['lastUpdated'] as String)
          : null,
      currentLat: pos?['lat'] as double?,
      currentLng: pos?['lng'] as double?,
      currentBearing: (j['heading'] as num?)?.toDouble(),
      currentStopIndex: j['currentStopIndex'] as int?,
      status: status,
      delayMinutes: delay,
      capacity:
          BusCapacity.fromString(j['capacity'] as String? ?? 'seatsAvailable'),
      vehicleNumber: j['vehicleId'] as String?,
      driverMessage: j['cancellationReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'lineCode': routeId,
        if (driverId != null) 'driverName': driverId,
        if (startedAt != null) 'lastUpdated': startedAt!.toIso8601String(),
        if (currentLat != null && currentLng != null)
          'currentPosition': <String, dynamic>{
            'lat': currentLat,
            'lng': currentLng,
          },
        if (currentBearing != null) 'heading': currentBearing,
        if (currentStopIndex != null) 'currentStopIndex': currentStopIndex,
        'status': status.name,
        'delay': delayMinutes,
        'capacity': capacity.name,
        if (vehicleNumber != null) 'vehicleId': vehicleNumber,
        if (driverMessage != null) 'cancellationReason': driverMessage,
      };
}
