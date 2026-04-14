class HabitualTripModel {
  const HabitualTripModel({
    required this.id,
    required this.userId,
    required this.routeId,
    required this.stopId,
    this.destinationStopId,
    this.timeWindowStart,
    this.timeWindowEnd,
    this.daysOfWeek = const [],
    this.notify = false,
    this.notifyMinutesBefore = 5,
  });

  final String id;
  final String userId;
  final String routeId;
  final String stopId;
  final String? destinationStopId;
  final String? timeWindowStart;
  final String? timeWindowEnd;
  final List<int> daysOfWeek;
  final bool notify;
  final int notifyMinutesBefore;

  factory HabitualTripModel.fromJson(Map<String, dynamic> j) =>
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
