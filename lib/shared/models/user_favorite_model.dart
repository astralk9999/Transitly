import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_favorite_model.freezed.dart';

@freezed
abstract class UserFavoriteModel with _$UserFavoriteModel {
  const UserFavoriteModel._();

  const factory UserFavoriteModel({
    required String id,
    required String userId,
    required String routeId,
    String? homeStopId,
    int? alarmMinutesBefore,
  }) = _UserFavoriteModel;

  static UserFavoriteModel fromJson(Map<String, dynamic> j) =>
      UserFavoriteModel(
        id: j['id'] as String,
        userId: j['userId'] as String,
        routeId: j['lineCode'] as String,
        homeStopId: j['stopCode'] as String?,
        alarmMinutesBefore: j['notifyBefore'] as int?,
      );
}
