import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/privacy_consent/privacy_consent_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../features/auth/auth_provider.dart';
import '../../features/auth/auth_repository.dart';

final privacyConsentRepositoryProvider =
    Provider<PrivacyConsentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PrivacyConsentRepository(client);
});

final privacyConsentsProvider = FutureProvider<Map<String, bool>>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState is! AuthAuthenticated) {
    return const {};
  }
  final repo = ref.watch(privacyConsentRepositoryProvider);
  return repo.getConsents(authState.user.id);
});
