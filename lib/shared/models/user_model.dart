import 'enums.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
    this.driverOperatorIds = const [],
    this.primaryZoneId,
    this.reputationScore = 0,
    this.reputationLevel = ReputationLevel.new_,
  });

  final String id;
  final String name;
  final String email;
  final List<String> roles;
  final List<String> driverOperatorIds;
  final String? primaryZoneId;
  final int reputationScore;
  final ReputationLevel reputationLevel;

  bool get isDriver => roles.contains('driver');
  bool get isAdmin => roles.contains('admin');

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: j['id'] as String,
        name: j['displayName'] as String? ?? j['username'] as String? ?? '',
        email: j['email'] as String? ?? '',
        roles: [j['role'] as String? ?? 'passenger'],
        driverOperatorIds: j['operator'] != null
            ? [j['operator'] as String]
            : const [],
        reputationScore: j['reputation'] as int? ?? 0,
        reputationLevel:
            ReputationLevel.fromString(j['reputationLevel'] as String? ?? 'new'),
      );
}
