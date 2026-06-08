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
    // La tabla `profiles` (Postgres) usa el enum user_role en snake_case
    // (operator_admin). El enum Dart usa camelCase (operatorAdmin). Aceptamos
    // ambas formas para no romper permisos de operator_admin ni datos legacy.
    final rawRole = j['role'] as String? ?? 'passenger';
    final roleStr = rawRole == 'operator_admin' ? 'operatorAdmin' : rawRole;
    final role = UserRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => UserRole.passenger,
    );

    final score =
        (j['reputation_score'] ?? j['reputation'] ?? 0) as int;
    // reputation_level en BD es INT (0..6). El enum dart solo tiene 4
    // valores (new_/contributor/trusted/expert), así que derivamos
    // desde el score para mantener el badge coherente.
    final level = _levelFromScore(score);

    return UserModel(
      id: j['id'] as String,
      name: (j['display_name'] ?? j['displayName'] ?? j['username'] ?? '')
          as String,
      email: j['email'] as String? ?? '',
      role: role,
      driverOperatorIds: roleStr == 'driver'
          ? (j['operator'] != null
              ? <String>[j['operator'] as String]
              : const <String>[])
          : const <String>[],
      reputationScore: score,
      reputationLevel: level,
    );
  }

  static ReputationLevel _levelFromScore(int score) {
    if (score >= 500) return ReputationLevel.expert;
    if (score >= 50) return ReputationLevel.trusted;
    if (score >= 10) return ReputationLevel.contributor;
    return ReputationLevel.new_;
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
