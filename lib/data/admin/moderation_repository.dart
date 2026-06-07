import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_client_provider.dart';

/// Un ítem normalizado de la bandeja de moderación (vista `moderation_list`).
class ModerationItem {
  ModerationItem({
    required this.source,
    required this.id,
    required this.typeLabel,
    required this.title,
    required this.description,
    required this.status,
    required this.isOpen,
    required this.createdAt,
    this.authorId,
    this.operatorId,
    this.routeId,
    this.stopId,
  });

  final String source; // feedback|incident|suggestion|feature|zone|operator_app|rgpd
  final String id;
  final String typeLabel;
  final String title;
  final String? description;
  final String status;
  final bool isOpen;
  final DateTime createdAt;
  final String? authorId;
  final String? operatorId;
  final String? routeId;
  final String? stopId;

  factory ModerationItem.fromRow(Map<String, dynamic> j) => ModerationItem(
        source: j['source'] as String? ?? '',
        id: j['id'] as String,
        typeLabel: j['type_label'] as String? ?? 'Aportación',
        title: j['title'] as String? ?? '',
        description: j['description'] as String?,
        status: j['status'] as String? ?? '',
        isOpen: j['is_open'] as bool? ?? false,
        createdAt:
            DateTime.tryParse(j['created_at'] as String? ?? '') ?? DateTime.now(),
        authorId: j['author_id'] as String?,
        operatorId: j['operator_id'] as String?,
        routeId: j['route_id'] as String?,
        stopId: j['stop_id'] as String?,
      );

  /// Fuentes que NO se pueden premiar con puntos.
  bool get rewardable =>
      source == 'feedback' || source == 'incident' || source == 'suggestion';
}

class AdminModerationRepository {
  AdminModerationRepository(this._client);
  final SupabaseClient _client;

  Future<List<ModerationItem>> list({bool onlyOpen = true}) async {
    final rows =
        await _client.rpc('moderation_list', params: {'p_only_open': onlyOpen});
    return (rows as List)
        .map((e) => ModerationItem.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  /// action ∈ review | accept | apply | reject
  Future<void> resolve({
    required String source,
    required String id,
    required String action,
    int awardPoints = 0,
    String? note,
  }) {
    return _client.rpc('moderation_resolve', params: {
      'p_source': source,
      'p_id': id,
      'p_action': action,
      'p_award_points': awardPoints,
      'p_note': note,
    });
  }

  Future<Map<String, int>> counts() async {
    final rows = await _client.rpc('moderation_counts');
    final out = <String, int>{};
    for (final r in (rows as List)) {
      final m = r as Map<String, dynamic>;
      out[m['source'] as String] = (m['n'] as num).toInt();
    }
    return out;
  }
}

final adminModerationRepositoryProvider =
    Provider<AdminModerationRepository>((ref) {
  return AdminModerationRepository(ref.watch(supabaseClientProvider));
});
