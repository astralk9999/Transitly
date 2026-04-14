import 'enums.dart';

class ActiveTripModel {
  const ActiveTripModel({
    required this.id,
    required this.routeId,
    this.driverId,
    this.startedAt,
    this.currentLat,
    this.currentLng,
    this.currentBearing,
    this.currentStopIndex,
    required this.status,
    this.delayMinutes = 0,
    required this.capacity,
    this.vehicleNumber,
    this.driverMessage,
  });

  final String id;
  final String routeId;
  final String? driverId;
  final DateTime? startedAt;
  final double? currentLat;
  final double? currentLng;
  final double? currentBearing;
  final int? currentStopIndex;
  final TripStatus status;
  final int delayMinutes;
  final BusCapacity capacity;
  final String? vehicleNumber;
  final String? driverMessage;

  factory ActiveTripModel.fromJson(Map<String, dynamic> j) {
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
      capacity: BusCapacity.fromString(j['capacity'] as String? ?? 'seatsAvailable'),
      vehicleNumber: j['vehicleId'] as String?,
      driverMessage: j['cancellationReason'] as String?,
    );
  }
}
