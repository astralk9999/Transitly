import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

import '../../data/supabase/supabase_client_provider.dart';
import 'auth_repository.dart';
import 'auth_repository_supabase.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final repo = AuthRepositorySupabase(client);
  repo.init();
  ref.onDispose(() => repo.dispose());
  return repo;
});

final authStateProvider = StreamProvider<AuthSessionState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authState;
});

final currentAuthUserProvider = Provider<User?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  return authState is AuthAuthenticated;
});
