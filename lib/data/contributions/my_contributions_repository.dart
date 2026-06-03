import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

/// Conteo de contribuciones reales del usuario actual desde Supabase.
class MyContributionsStats {
  const MyContributionsStats({
    required this.incidents,
    required this.suggestions,
    required this.feedback,
    required this.featureRequests,
    required this.routeShares,
  });

  final int incidents;
  final int suggestions;
  final int feedback;
  final int featureRequests;
  final int routeShares;

  int get total =>
      incidents + suggestions + feedback + featureRequests + routeShares;

  // Una "verificada" es una contribución que el equipo resolvió como válida.
  int get verifiedApprox => 0; // calculada en el método repo

  factory MyContributionsStats.empty() => const MyContributionsStats(
        incidents: 0,
        suggestions: 0,
        feedback: 0,
        featureRequests: 0,
        routeShares: 0,
      );
}

class MyContributionsRepository {
  MyContributionsRepository(this._client);
  final SupabaseClient _client;
  static const _logTag = 'Contributions';

  /// Lee los conteos para el usuario autenticado. Si no hay sesión,
  /// devuelve stats vacías.
  Future<MyContributionsStats> getMyStats() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return MyContributionsStats.empty();

    try {
      final results = await Future.wait<int>([
        _count('incidents', 'author_id', uid),
        _count('route_suggestions', 'author_id', uid),
        _count('route_feedback', 'author_id', uid),
        _count('feature_requests', 'author_id', uid),
        _count('route_shares', 'shared_by_id', uid),
      ]);
      return MyContributionsStats(
        incidents: results[0],
        suggestions: results[1],
        feedback: results[2],
        featureRequests: results[3],
        routeShares: results[4],
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'getMyStats failed', e);
      return MyContributionsStats.empty();
    }
  }

  Future<int> _count(String table, String authorCol, String uid) async {
    final selectCol = authorCol == 'shared_by_id' ? 'route_id' : 'id';
    final res = await _client
        .from(table)
        .select(selectCol)
        .eq(authorCol, uid)
        .count(CountOption.exact);
    return res.count;
  }

  /// Cuenta solo las marcadas como "resolved" / "verified" (status = resolved
  /// en incidents y route_feedback). Aproximación.
  Future<int> getVerifiedCount() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return 0;
    try {
      final res = await _client
          .from('incidents')
          .select('id')
          .eq('author_id', uid)
          .eq('status', 'resolved')
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      AppLogger.warn(_logTag, 'getVerifiedCount failed', e);
      return 0;
    }
  }
}
