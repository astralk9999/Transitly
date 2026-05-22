import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/privacy_consent/privacy_consent_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/auth/auth_repository.dart';

final privacyConsentRepositoryProvider =
    Provider<PrivacyConsentRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PrivacyConsentRepository(client);
});

// autoDispose: se re-fetchea cuando vuelve a observarse (consentimientos
// frescos al reabrir Privacidad).
final privacyConsentsProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) {
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState is! AuthAuthenticated) {
    return const {};
  }
  final repo = ref.watch(privacyConsentRepositoryProvider);
  return repo.getConsents(authState.user.id);
});
