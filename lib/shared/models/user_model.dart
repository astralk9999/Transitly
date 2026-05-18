import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';
import 'user_role.dart';

part 'user_model.freezed.dart';

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    required String id,
    required String name,
    required String email,
    @Deprecated('Use role instead') @Default(<String>[]) List<String> roles,
    @Default(UserRole.passenger) UserRole role,
    @Default(<String>[]) List<String> driverOperatorIds,
    String? primaryZoneId,
    @Default(0) int reputationScore,
    @Default(ReputationLevel.new_) ReputationLevel reputationLevel,
  }) = _UserModel;

  bool get isDriver => role == UserRole.driver || role == UserRole.operatorAdmin;
  bool get isAdmin => role == UserRole.admin;

  static UserModel fromJson(Map<String, dynamic> j) {
    final roleStr = j['role'] as String? ?? 'passenger';
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.passenger,
    );

    return UserModel(
      id: j['id'] as String,
      name: j['displayName'] as String? ?? j['username'] as String? ?? '',
      email: j['email'] as String? ?? '',
      role: role,
      driverOperatorIds: roleStr == 'driver' ? (j['operator'] != null
          ? <String>[j['operator'] as String]
          : const <String>[])
          : const <String>[],
      reputationScore: j['reputation'] as int? ?? 0,
      reputationLevel: ReputationLevel.fromString(
          j['reputationLevel'] as String? ?? 'new'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'displayName': name,
        if (email.isNotEmpty) 'email': email,
        'role': role.name,
        if (driverOperatorIds.isNotEmpty) 'operator': driverOperatorIds.first,
        'reputation': reputationScore,
        'reputationLevel': reputationLevel.name,
      };
}
