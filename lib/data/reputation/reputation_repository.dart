import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

class UserReputation {
  const UserReputation({
    required this.score,
    required this.level,
    required this.routesCreated,
  });

  final int score;
  final int level;
  final int routesCreated;

  int get quota => switch (level) {
    0 => 1,
    1 => 3,
    2 => 10,
    3 => 30,
    4 => 100,
    5 => 200,
    6 => 500,
    _ => 1,
  };

  int xpToNextLevel() {
    final thresholds = [10, 50, 200, 500, 1500, 5000];
    for (int i = level; i < thresholds.length; i++) {
      if (score < thresholds[i]) return thresholds[i] - score;
    }
    return 0;
  }
}

class ReputationRepository {
  ReputationRepository(this._client);
  final SupabaseClient _client;
  static const _logTag = 'Repo:Reputation';

  Future<UserReputation> getMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const UserReputation(score: 0, level: 0, routesCreated: 0);
    try {
      final res = await _client
          .from('profiles')
          .select('reputation_score, reputation_level, routes_created_count')
          .eq('id', uid)
          .maybeSingle();
      if (res == null) return const UserReputation(score: 0, level: 0, routesCreated: 0);
      return UserReputation(
        score: (res['reputation_score'] as int?) ?? 0,
        level: (res['reputation_level'] as int?) ?? 0,
        routesCreated: (res['routes_created_count'] as int?) ?? 0,
      );
    } catch (e) {
      AppLogger.error(_logTag, 'getMine failed', e);
      return const UserReputation(score: 0, level: 0, routesCreated: 0);
    }
  }
}

final reputationRepositoryProvider = Provider.autoDispose<ReputationRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;
  return ReputationRepository(client);
});

/// Provider derivado — reputación del usuario actual
final userReputationProvider = FutureProvider<UserReputation>((ref) async {
  final repo = ref.watch(reputationRepositoryProvider);
  if (repo == null) return const UserReputation(score: 0, level: 0, routesCreated: 0);
  return repo.getMine();
});
