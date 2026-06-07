import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';

/// Modelo para una ruta creada por usuario.
class UserRouteModel {
  const UserRouteModel({
    required this.id,
    required this.authorId,
    required this.name,
    this.code,
    this.description,
    this.routeColor = '#977DDF',
    this.serviceType = 'urban',
    this.visibility = 'private',
    this.status = 'draft',
    this.shareCode,
    this.publicSlug,
    this.totalDistanceKm,
    this.totalDurationMin,
    this.viewCount = 0,
    this.voteCount = 0,
    this.reportCount = 0,
    this.countryCode = 'ES',
    this.region,
    this.createdAt,
    this.updatedAt,
    this.publishedAt,
  });

  final String id;
  final String authorId;
  final String name;
  final String? code;
  final String? description;
  final String routeColor;
  final String serviceType;
  final String visibility;
  final String status;
  final String? shareCode;
  final String? publicSlug;
  final double? totalDistanceKm;
  final int? totalDurationMin;
  final int viewCount;
  final int voteCount;
  final int reportCount;
  final String countryCode;
  final String? region;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? publishedAt;

  factory UserRouteModel.fromJson(Map<String, dynamic> json) {
    return UserRouteModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      description: json['description'] as String?,
      routeColor: (json['route_color'] as String?) ?? '#977DDF',
      serviceType: (json['service_type'] as String?) ?? 'urban',
      visibility: (json['visibility'] as String?) ?? 'private',
      status: (json['status'] as String?) ?? 'draft',
      shareCode: json['share_code'] as String?,
      publicSlug: json['public_slug'] as String?,
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble(),
      totalDurationMin: json['total_duration_min'] as int?,
      viewCount: (json['view_count'] as int?) ?? 0,
      voteCount: (json['vote_count'] as int?) ?? 0,
      reportCount: (json['report_count'] as int?) ?? 0,
      countryCode: (json['country_code'] as String?) ?? 'ES',
      region: json['region'] as String?,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'] as String) : null,
      publishedAt: json['published_at'] != null ? DateTime.tryParse(json['published_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != '') 'id': id,
    'author_id': authorId,
    'name': name,
    if (code != null && code!.isNotEmpty) 'code': code,
    if (region != null && region!.isNotEmpty) 'region': region,
    if (description != null) 'description': description,
    'route_color': routeColor,
    'service_type': serviceType,
    'visibility': visibility,
    'status': status,
    if (shareCode != null) 'share_code': shareCode,
    if (publicSlug != null) 'public_slug': publicSlug,
    if (totalDistanceKm != null) 'total_distance_km': totalDistanceKm,
    if (totalDurationMin != null) 'total_duration_min': totalDurationMin,
  };

  UserRouteModel copyWith({
    String? id,
    String? authorId,
    String? name,
    String? description,
    String? routeColor,
    String? serviceType,
    String? visibility,
    String? status,
    String? shareCode,
    String? publicSlug,
    double? totalDistanceKm,
    int? totalDurationMin,
    int? viewCount,
    int? voteCount,
    int? reportCount,
  }) {
    return UserRouteModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      name: name ?? this.name,
      description: description ?? this.description,
      routeColor: routeColor ?? this.routeColor,
      serviceType: serviceType ?? this.serviceType,
      visibility: visibility ?? this.visibility,
      status: status ?? this.status,
      shareCode: shareCode ?? this.shareCode,
      publicSlug: publicSlug ?? this.publicSlug,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      totalDurationMin: totalDurationMin ?? this.totalDurationMin,
      viewCount: viewCount ?? this.viewCount,
      voteCount: voteCount ?? this.voteCount,
      reportCount: reportCount ?? this.reportCount,
      countryCode: countryCode,
      region: region,
      createdAt: createdAt,
      updatedAt: updatedAt,
      publishedAt: publishedAt,
    );
  }
}

/// Repositorio de user_routes — acceso a Supabase.
class UserRoutesRepository {
  UserRoutesRepository(this._client);
  final SupabaseClient _client;
  static const _logTag = 'Repo:UserRoutes';

  Future<List<UserRouteModel>> getMyRoutes() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await _client
          .from('user_routes')
          .select()
          .eq('author_id', uid)
          .order('created_at', ascending: false);
      return (res as List<dynamic>)
          .map((j) => UserRouteModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(_logTag, 'getMyRoutes failed', e);
      return [];
    }
  }

  Future<List<UserRouteModel>> searchPublic({
    String? query,
    String? serviceType,
    String? region,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var q = _client
          .from('user_routes')
          .select()
          .eq('visibility', 'public')
          .or('status.eq.published,status.eq.community_approved');

      if (query != null && query.isNotEmpty) {
        q = q.ilike('name', '%$query%');
      }
      if (serviceType != null) q = q.eq('service_type', serviceType);
      if (region != null) q = q.eq('region', region);

      final res = await q
          .order('vote_count', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);
      return (res as List<dynamic>)
          .map((j) => UserRouteModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(_logTag, 'searchPublic failed', e);
      return [];
    }
  }

  Future<UserRouteModel?> getById(String id) async {
    try {
      final res = await _client.from('user_routes').select().eq('id', id).maybeSingle();
      if (res == null) return null;
      final route = UserRouteModel.fromJson(res as Map<String, dynamic>);

      // Registrar vista
      unawaited(_recordView(id));

      return route;
    } catch (e) {
      AppLogger.error(_logTag, 'getById failed', e);
      return null;
    }
  }

  Future<UserRouteModel?> getByShareCode(String code) async {
    try {
      final res = await _client
          .from('user_routes')
          .select()
          .eq('share_code', code.toUpperCase())
          .eq('status', 'published')
          .maybeSingle();
      if (res == null) return null;
      return UserRouteModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(_logTag, 'getByShareCode failed', e);
      return null;
    }
  }

  Future<UserRouteModel?> getBySlug(String slug) async {
    try {
      final res = await _client
          .from('user_routes')
          .select()
          .eq('public_slug', slug)
          .maybeSingle();
      if (res == null) return null;
      return UserRouteModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(_logTag, 'getBySlug failed', e);
      return null;
    }
  }

  Future<UserRouteModel?> create(UserRouteModel route) async {
    try {
      final res = await _client
          .from('user_routes')
          .insert(route.toJson())
          .select()
          .single();
      return UserRouteModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(_logTag, 'create failed', e);
      rethrow;
    }
  }

  Future<UserRouteModel?> update(UserRouteModel route) async {
    try {
      final res = await _client
          .from('user_routes')
          .update(route.toJson())
          .eq('id', route.id)
          .select()
          .single();
      return UserRouteModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(_logTag, 'update failed', e);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('user_routes').delete().eq('id', id);
    } catch (e) {
      AppLogger.error(_logTag, 'delete failed', e);
      rethrow;
    }
  }

  Future<void> vote(String routeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('user_route_votes').insert({
        'route_id': routeId,
        'voter_id': uid,
      });
    } catch (_) {
      // Ya votó — ignorar
    }
  }

  Future<void> unvote(String routeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('user_route_votes').delete().eq('route_id', routeId).eq('voter_id', uid);
    } catch (e) {
      AppLogger.warn(_logTag, 'unvote failed', e);
    }
  }

  Future<bool> hasVoted(String routeId) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return false;
    try {
      final res = await _client
          .from('user_route_votes')
          .select('voter_id')
          .eq('route_id', routeId)
          .eq('voter_id', uid)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> report(String routeId, String reason, {String? description}) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('user_route_reports').insert({
        'route_id': routeId,
        'reporter_id': uid,
        'reason': reason,
        'description': description,
      });
    } catch (e) {
      AppLogger.error(_logTag, 'report failed', e);
      rethrow;
    }
  }

  Future<void> _recordView(String routeId) async {
    try {
      final uid = _client.auth.currentUser?.id;
      await _client.from('user_route_views').insert({
        'route_id': routeId,
        'viewer_id': uid,
        'via_public_link': true,
      });
    } catch (_) {}
  }

  static Future<void> unawaited(Future<void> f) async {
    try { await f; } catch (_) {}
  }
}

final userRoutesRepositoryProvider = Provider.autoDispose<UserRoutesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;
  return UserRoutesRepository(client);
});
