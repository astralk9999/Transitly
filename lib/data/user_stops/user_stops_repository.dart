import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

class UserStopModel {
  const UserStopModel({
    required this.id,
    required this.authorId,
    required this.name,
    required this.lat,
    required this.lng,
    this.officialStopId,
    this.stopType = 'custom',
    this.description,
    this.promotionStatus = 'none',
    this.createdAt,
  });

  final String id;
  final String authorId;
  final String name;
  final double lat;
  final double lng;
  final String? officialStopId;
  final String stopType;
  final String? description;
  final String promotionStatus;
  final DateTime? createdAt;

  factory UserStopModel.fromJson(Map<String, dynamic> json) {
    return UserStopModel(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      officialStopId: json['official_stop_id'] as String?,
      stopType: (json['stop_type'] as String?) ?? 'custom',
      description: json['description'] as String?,
      promotionStatus: (json['promotion_status'] as String?) ?? 'none',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != '') 'id': id,
    'author_id': authorId,
    'name': name,
    'lat': lat,
    'lng': lng,
    if (officialStopId != null) 'official_stop_id': officialStopId,
    'stop_type': stopType,
    if (description != null) 'description': description,
  };
}

class UserRouteStopModel {
  const UserRouteStopModel({
    required this.userStopId,
    required this.orderIndex,
    this.durationToNextMin,
    this.distanceToNextKm,
    this.stop, // join con user_stops
  });

  final String userStopId;
  final int orderIndex;
  final int? durationToNextMin;
  final double? distanceToNextKm;
  final UserStopModel? stop;

  factory UserRouteStopModel.fromJson(Map<String, dynamic> json) {
    return UserRouteStopModel(
      userStopId: json['user_stop_id'] as String,
      orderIndex: json['order_index'] as int,
      durationToNextMin: json['duration_to_next_min'] as int?,
      distanceToNextKm: (json['distance_to_next_km'] as num?)?.toDouble(),
      stop: json['user_stops'] != null
          ? UserStopModel.fromJson(json['user_stops'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_stop_id': userStopId,
    'order_index': orderIndex,
    if (durationToNextMin != null) 'duration_to_next_min': durationToNextMin,
    if (distanceToNextKm != null) 'distance_to_next_km': distanceToNextKm,
  };
}

class UserStopsRepository {
  UserStopsRepository(this._client);
  final SupabaseClient _client;
  static const _logTag = 'Repo:UserStops';

  Future<List<UserStopModel>> getMyStops() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final res = await _client
          .from('user_stops')
          .select()
          .eq('author_id', uid)
          .order('created_at', ascending: false);
      return (res as List<dynamic>)
          .map((j) => UserStopModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(_logTag, 'getMyStops failed', e);
      return [];
    }
  }

  Future<List<UserRouteStopModel>> getStopsForRoute(String routeId) async {
    try {
      final res = await _client
          .from('user_route_stops')
          .select('*, user_stops(*)')
          .eq('route_id', routeId)
          .order('order_index', ascending: true);
      final list = (res as List<dynamic>)
          .map((j) => UserRouteStopModel.fromJson(j as Map<String, dynamic>))
          .toList();
      // Orden ASCENDENTE garantizado en Dart: el embed de PostgREST a veces
      // no respeta el .order() del nivel raíz y las paradas salían al revés.
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return list;
    } catch (e) {
      AppLogger.error(_logTag, 'getStopsForRoute failed', e);
      return [];
    }
  }

  Future<UserStopModel?> create(UserStopModel stop) async {
    try {
      final res = await _client
          .from('user_stops')
          .insert(stop.toJson())
          .select()
          .single();
      return UserStopModel.fromJson(res as Map<String, dynamic>);
    } catch (e) {
      AppLogger.error(_logTag, 'create stop failed', e);
      rethrow;
    }
  }

  /// Inserta o actualiza una parada por id. Necesario al EDITAR una ruta:
  /// las paradas ya existen, así que un insert plano daría error de clave
  /// duplicada y reventaría toda la publicación.
  Future<void> upsert(UserStopModel stop) async {
    try {
      await _client.from('user_stops').upsert(stop.toJson());
    } catch (e) {
      AppLogger.error(_logTag, 'upsert stop failed', e);
      rethrow;
    }
  }

  Future<void> saveRouteStops(String routeId, List<UserRouteStopModel> stops) async {
    try {
      // Borrar existentes y reinsertar
      await _client.from('user_route_stops').delete().eq('route_id', routeId);
      if (stops.isEmpty) return;
      final rows = stops.map((s) => {
        'route_id': routeId,
        ...s.toJson(),
      }).toList();
      await _client.from('user_route_stops').insert(rows);
    } catch (e) {
      AppLogger.error(_logTag, 'saveRouteStops failed', e);
      rethrow;
    }
  }
}

final userStopsRepositoryProvider = Provider.autoDispose<UserStopsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;
  return UserStopsRepository(client);
});
