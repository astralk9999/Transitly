import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'user_model.freezed.dart';

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String name,
    required String email,
    required List<String> roles,
    @Default(<String>[]) List<String> driverOperatorIds,
    String? primaryZoneId,
    @Default(0) int reputationScore,
    @Default(ReputationLevel.new_) ReputationLevel reputationLevel,
  }) = _UserModel;

  bool get isDriver => roles.contains('driver');
  bool get isAdmin => roles.contains('admin');

  static UserModel fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        name: j['displayName'] as String? ?? j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        roles: <String>[j['role'] as String? ?? 'passenger'],
        driverOperatorIds: j['operator'] != null
            ? <String>[j['operator'] as String]
            : const <String>[],
        reputationScore: j['reputation'] as int? ?? 0,
        reputationLevel: ReputationLevel.fromString(
            j['reputationLevel'] as String? ?? 'new'),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'displayName': name,
        if (email.isNotEmpty) 'email': email,
        'role': roles.isNotEmpty ? roles.first : 'passenger',
        if (driverOperatorIds.isNotEmpty) 'operator': driverOperatorIds.first,
        'reputation': reputationScore,
        'reputationLevel': reputationLevel.name,
      };
}
