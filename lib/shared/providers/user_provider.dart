import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/mock/mock_data_service.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

final isDriverModeProvider = StateProvider<bool>((ref) => false);

final currentUserProvider = Provider<UserModel>((ref) {
  final isDriver = ref.watch(isDriverModeProvider);
  final mockData = ref.watch(mockDataServiceProvider);
  final users = mockData.users;
  if (isDriver) {
    return users.firstWhere(
      (u) => u.isDriver,
      orElse: () => users.first,
    );
  }
  return users.firstWhere(
    (u) => !u.isDriver,
    orElse: () => users.first,
  );
});

final currentUserRoleProvider = Provider<UserRole>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.role;
});
