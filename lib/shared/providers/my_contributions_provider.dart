import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/contributions/my_contributions_repository.dart';

final myContributionsRepositoryProvider =
    Provider<MyContributionsRepository>((ref) {
  return MyContributionsRepository(Supabase.instance.client);
});

/// FutureProvider que expone las stats de contribuciones del usuario actual.
final myContributionsProvider =
    FutureProvider.autoDispose<MyContributionsStats>((ref) async {
  final repo = ref.watch(myContributionsRepositoryProvider);
  return repo.getMyStats();
});

/// Verified count (incidents con status=resolved).
final myContributionsVerifiedProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(myContributionsRepositoryProvider);
  return repo.getVerifiedCount();
});
