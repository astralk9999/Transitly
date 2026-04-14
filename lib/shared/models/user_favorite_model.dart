class UserFavoriteModel {
  const UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.routeId,
    this.homeStopId,
    this.alarmMinutesBefore,
  });

  final String id;
  final String userId;
  final String routeId;
  final String? homeStopId;
  final int? alarmMinutesBefore;

  factory UserFavoriteModel.fromJson(Map<String, dynamic> j) =>
      UserFavoriteModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        routeId: j['lineCode'] as String,
        homeStopId: j['stopCode'] as String?,
        alarmMinutesBefore: j['notifyBefore'] as int?,
      );
}
