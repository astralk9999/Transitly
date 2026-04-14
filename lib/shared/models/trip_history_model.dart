class TripHistoryModel {
  const TripHistoryModel({
    required this.id,
    required this.userId,
    required this.routeId,
    this.fromStopId,
    this.toStopId,
    required this.startedAt,
    this.cost,
    this.distanceKm,
    this.co2SavedKg,
  });

  final String id;
  final String userId;
  final String routeId;
  final String? fromStopId;
  final String? toStopId;
  final DateTime startedAt;
  final double? cost;
  final double? distanceKm;
  final double? co2SavedKg;

  factory TripHistoryModel.fromJson(Map<String, dynamic> j) =>
      TripHistoryModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        routeId: j['lineCode'] as String,
        fromStopId: j['boardingStop'] as String?,
        toStopId: j['alightingStop'] as String?,
        startedAt: DateTime.parse('${j['date']}T${j['boardingTime']}:00'),
        cost: (j['fare'] as num?)?.toDouble(),
      );
}
