import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

class UserRouteScheduleModel {
  const UserRouteScheduleModel({
    this.id,
    required this.routeId,
    required this.dayType,
    required this.departureTime,
    this.originStopId,
    this.notes,
  });

  final String? id;
  final String routeId;
  final String dayType; // weekday, saturday, sunday, holiday, summer, winter, every_day
  final String departureTime; // HH:mm
  final String? originStopId;
  final String? notes;

  factory UserRouteScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawTime = json['departure_time'] as String;
    return UserRouteScheduleModel(
      id: json['id'] as String?,
      routeId: json['route_id'] as String,
      dayType: json['day_type'] as String,
      // La BD guarda TIME como "HH:MM:SS"; la UI usa siempre "HH:MM".
      departureTime: rawTime.length >= 5 ? rawTime.substring(0, 5) : rawTime,
      originStopId: json['origin_stop_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) 'id': id,
    'route_id': routeId,
    'day_type': dayType,
    'departure_time': departureTime,
    if (originStopId != null) 'origin_stop_id': originStopId,
    if (notes != null) 'notes': notes,
  };
}

class UserRouteSchedulesRepository {
  UserRouteSchedulesRepository(this._client);
  final SupabaseClient _client;
  static const _logTag = 'Repo:Schedules';

  Future<List<UserRouteScheduleModel>> getForRoute(String routeId) async {
    try {
      final res = await _client
          .from('user_route_schedules')
          .select()
          .eq('route_id', routeId)
          .order('departure_time');
      return (res as List<dynamic>)
          .map((j) => UserRouteScheduleModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(_logTag, 'getForRoute failed', e);
      return [];
    }
  }

  Future<List<UserRouteScheduleModel>> saveAll(
    String routeId,
    List<UserRouteScheduleModel> schedules,
  ) async {
    try {
      // Eliminar existentes
      await _client.from('user_route_schedules').delete().eq('route_id', routeId);
      if (schedules.isEmpty) return [];
      // Insertar nuevos
      final rows = schedules
          .map((s) => s.toJson()..['route_id'] = routeId)
          .toList();
      final res = await _client.from('user_route_schedules').insert(rows).select();
      return (res as List<dynamic>)
          .map((j) => UserRouteScheduleModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      AppLogger.error(_logTag, 'saveAll failed', e);
      rethrow;
    }
  }
}

final userRouteSchedulesRepositoryProvider =
    Provider.autoDispose<UserRouteSchedulesRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;
  return UserRouteSchedulesRepository(client);
});
