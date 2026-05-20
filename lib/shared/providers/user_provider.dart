import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../models/user_model.dart';
import '../models/user_role.dart';

const _logTag = 'Provider:User';

final isDriverModeProvider = StateProvider<bool>((ref) => false);

/// Perfil del usuario desde Supabase `profiles`. Null en modo invitado.
final userProfileFromSupabaseProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState is! AuthAuthenticated) return null;

  final client = ref.watch(supabaseClientProvider);
  try {
    final row = await client
        .from('profiles')
        .select()
        .eq('id', authState.user.id)
        .maybeSingle();
    if (row == null) return null;
    return UserModel.fromJson(row);
  } on PostgrestException catch (e) {
    AppLogger.warn(_logTag, 'profiles fetch failed', e);
    return null;
  }
});

/// Usuario actual: perfil real de Supabase si está autenticado,
/// o usuario mock en modo invitado.
final currentUserProvider = Provider<UserModel>((ref) {
  final isDriver = ref.watch(isDriverModeProvider);
  final profile = ref.watch(userProfileFromSupabaseProvider).valueOrNull;
  final mockData = ref.watch(mockDataServiceProvider);
  final users = mockData.users;

  if (profile != null) return profile;

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
