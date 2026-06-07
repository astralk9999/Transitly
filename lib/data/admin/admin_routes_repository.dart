import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/enums.dart';
import '../supabase/supabase_client_provider.dart';

const _tag = 'Repo:AdminRoutes';

/// Versión simplificada de fila de `routes` para el panel admin.
/// No usamos [RouteModel] para no inventar campos que la BD no tiene
/// (ServiceType es un concepto cliente, no existe en la columna).
class AdminRouteRow {
  AdminRouteRow({
    required this.id,
    required this.operatorId,
    required this.code,
    required this.name,
    required this.description,
    required this.color,
    required this.status,
    required this.source,
    required this.active,
    this.updatedAt,
  });

  final String id;
  final String operatorId;
  final String code;
  final String name;
  final String? description;
  final String? color;
  final RouteStatus status;
  final RouteSource source;
  final bool active;
  final DateTime? updatedAt;

  factory AdminRouteRow.fromRow(Map<String, dynamic> j) {
    final meta = (j['metadata'] as Map<String, dynamic>?) ?? const {};
    return AdminRouteRow(
      id: j['id'] as String,
      operatorId: j['operator_id'] as String? ?? '',
      code: (j['code'] as String?) ?? '',
      name: j['name'] as String,
      description: j['description'] as String?,
      color: j['color'] as String?,
      status: RouteStatus.fromString(j['status'] as String? ?? 'draft'),
      source: switch (j['source'] as String?) {
        'community' => RouteSource.community,
        _ => RouteSource.official,
      },
      active: (meta['active'] as bool?) ?? true,
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.tryParse(j['updated_at'] as String),
    );
  }
}

/// Parada cruda con coordenadas y código.
class AdminStopRow {
  AdminStopRow({
    required this.id,
    required this.operatorId,
    required this.code,
    required this.name,
    required this.lat,
    required this.lng,
    required this.accessible,
    required this.hasShelter,
    required this.hasBench,
  });

  final String id;
  final String operatorId;
  final String code;
  final String name;
  final double lat;
  final double lng;
  final bool accessible;
  final bool hasShelter;
  final bool hasBench;

  /// PostGIS devuelve geom como GeoJSON cuando se pide via to_json o
  /// como string WKT por defecto. Para simplificar usamos las columnas
  /// derivadas latitude/longitude vía vista o RPC; aquí parseamos JSON.
  factory AdminStopRow.fromRow(Map<String, dynamic> j) {
    final acc = (j['accessibility'] as Map<String, dynamic>?) ?? const {};
    return AdminStopRow(
      id: j['id'] as String,
      operatorId: j['operator_id'] as String? ?? '',
      code: (j['code'] as String?) ?? '',
      name: j['name'] as String,
      lat: (j['lat'] as num?)?.toDouble() ?? 0,
      lng: (j['lng'] as num?)?.toDouble() ?? 0,
      accessible: (acc['wheelchair'] as bool?) ?? false,
      hasShelter: (acc['shelter'] as bool?) ?? false,
      hasBench: (acc['bench'] as bool?) ?? false,
    );
  }
}

class AdminRouteStopRow {
  AdminRouteStopRow({
    required this.routeId,
    required this.stopId,
    required this.sequence,
    required this.direction,
    this.stop,
  });
  final String routeId;
  final String stopId;
  final int sequence;
  final int direction;
  final AdminStopRow? stop;
}

class AdminScheduleRow {
  AdminScheduleRow({
    required this.id,
    required this.routeId,
    required this.dayType,
    required this.direction,
    required this.departureTime,
    this.notes,
  });

  final String id;
  final String routeId;
  final DayType dayType;
  final int direction;
  final String departureTime;
  final String? notes;

  factory AdminScheduleRow.fromRow(Map<String, dynamic> j) => AdminScheduleRow(
        id: j['id'] as String,
        routeId: j['route_id'] as String,
        dayType: DayType.fromString(j['day_type'] as String? ?? 'weekday'),
        direction: (j['direction'] as num?)?.toInt() ?? 0,
        departureTime: (j['departure_time'] as String).substring(0, 5),
        notes: j['notes'] as String?,
      );
}

class AdminRoutesRepository {
  AdminRoutesRepository(this._client);
  final SupabaseClient _client;

  // ── Rutas ───────────────────────────────────────────────────
  Future<List<AdminRouteRow>> listRoutes({String? operatorId}) async {
    var q = _client.from('routes').select(
        'id, operator_id, code, name, description, color, status, source, metadata, updated_at');
    if (operatorId != null) q = q.eq('operator_id', operatorId);
    final rows = await q.order('code');
    return (rows as List).map((e) => AdminRouteRow.fromRow(e as Map<String, dynamic>)).toList();
  }

  Future<AdminRouteRow?> getRoute(String id) async {
    final row = await _client
        .from('routes')
        .select(
            'id, operator_id, code, name, description, color, status, source, metadata, updated_at')
        .eq('id', id)
        .maybeSingle();
    return row == null ? null : AdminRouteRow.fromRow(row);
  }

  Future<String> upsertRoute({
    String? id,
    required String operatorId,
    required String code,
    required String name,
    String? description,
    String? color,
    RouteStatus status = RouteStatus.draft,
    RouteSource source = RouteSource.official,
    bool active = true,
  }) async {
    final res = await _client.rpc('admin_route_upsert', params: {
      'p_id': id,
      'p_operator_id': operatorId,
      'p_code': code,
      'p_name': name,
      'p_description': description,
      'p_color': color,
      'p_status': status.name,
      'p_source': source.name,
      'p_active': active,
    });
    return res as String;
  }

  Future<void> deleteRoute(String id) =>
      _client.rpc('admin_route_delete', params: {'p_id': id});

  Future<void> setRouteOperator(String id, String newOperatorId) =>
      _client.rpc('admin_route_set_operator', params: {
        'p_id': id,
        'p_new_operator_id': newOperatorId,
      });

  // ── Paradas ─────────────────────────────────────────────────
  Future<List<AdminStopRow>> listStopsOfOperator(String operatorId) async {
    final rows = await _client.rpc('admin_list_stops', params: {
      'p_operator_id': operatorId,
    });
    return (rows as List)
        .map((e) => AdminStopRow.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminRouteStopRow>> listRouteStops(String routeId) async {
    final rows = await _client.rpc('admin_list_route_stops', params: {
      'p_route_id': routeId,
    });
    return (rows as List).map((e) {
      final m = e as Map<String, dynamic>;
      return AdminRouteStopRow(
        routeId: m['route_id'] as String,
        stopId: m['stop_id'] as String,
        sequence: (m['sequence'] as num).toInt(),
        direction: (m['direction'] as num).toInt(),
        stop: m['stop_id'] == null
            ? null
            : AdminStopRow(
                id: m['stop_id'] as String,
                operatorId: m['operator_id'] as String? ?? '',
                code: (m['code'] as String?) ?? '',
                name: m['name'] as String? ?? '',
                lat: (m['lat'] as num?)?.toDouble() ?? 0,
                lng: (m['lng'] as num?)?.toDouble() ?? 0,
                accessible: false,
                hasShelter: false,
                hasBench: false,
              ),
      );
    }).toList();
  }

  Future<String> upsertStop({
    String? id,
    required String operatorId,
    required String code,
    required String name,
    required double lat,
    required double lng,
    bool accessible = false,
    bool hasShelter = false,
    bool hasBench = false,
  }) async {
    final res = await _client.rpc('admin_stop_upsert', params: {
      'p_id': id,
      'p_operator_id': operatorId,
      'p_code': code,
      'p_name': name,
      'p_lat': lat,
      'p_lng': lng,
      'p_accessible': accessible,
      'p_has_shelter': hasShelter,
      'p_has_bench': hasBench,
    });
    return res as String;
  }

  Future<void> moveStop(String id, double lat, double lng) =>
      _client.rpc('admin_stop_move', params: {
        'p_id': id,
        'p_lat': lat,
        'p_lng': lng,
      });

  Future<void> deleteStop(String id) =>
      _client.rpc('admin_stop_delete', params: {'p_id': id});

  Future<void> addStopToRoute({
    required String routeId,
    required String stopId,
    required int sequence,
    int direction = 0,
  }) =>
      _client.rpc('admin_route_stop_add', params: {
        'p_route_id': routeId,
        'p_stop_id': stopId,
        'p_sequence': sequence,
        'p_direction': direction,
      });

  Future<void> removeStopFromRoute({
    required String routeId,
    required String stopId,
    int direction = 0,
  }) =>
      _client.rpc('admin_route_stop_remove', params: {
        'p_route_id': routeId,
        'p_stop_id': stopId,
        'p_direction': direction,
      });

  Future<void> reorderStops({
    required String routeId,
    required int direction,
    required List<({String stopId, int sequence})> pairs,
  }) {
    final p = pairs
        .map((e) => {'stop_id': e.stopId, 'sequence': e.sequence})
        .toList();
    return _client.rpc('admin_route_stops_reorder', params: {
      'p_route_id': routeId,
      'p_direction': direction,
      'p_pairs': p,
    });
  }

  // ── Horarios ────────────────────────────────────────────────
  Future<List<AdminScheduleRow>> listSchedules(String routeId) async {
    final rows = await _client
        .from('schedules')
        .select()
        .eq('route_id', routeId)
        .order('day_type')
        .order('direction')
        .order('departure_time');
    return (rows as List)
        .map((e) => AdminScheduleRow.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> upsertSchedule({
    String? id,
    required String routeId,
    required DayType dayType,
    required int direction,
    required String departureTime,
    String? notes,
  }) async {
    final res = await _client.rpc('admin_schedule_upsert', params: {
      'p_id': id,
      'p_route_id': routeId,
      'p_day_type': dayType.name,
      'p_direction': direction,
      'p_departure_time': departureTime,
      'p_notes': notes,
    });
    return res as String;
  }

  Future<void> deleteSchedule(String id) =>
      _client.rpc('admin_schedule_delete', params: {'p_id': id});

  Future<int> generateFrequency({
    required String routeId,
    required DayType dayType,
    required int direction,
    required String startTime,
    required String endTime,
    required int intervalMinutes,
  }) async {
    final res = await _client.rpc('admin_schedules_generate_frequency', params: {
      'p_route_id': routeId,
      'p_day_type': dayType.name,
      'p_direction': direction,
      'p_start_time': startTime,
      'p_end_time': endTime,
      'p_interval_min': intervalMinutes,
    });
    return (res as num).toInt();
  }

  Future<int> clearSchedules({
    required String routeId,
    required DayType dayType,
    required int direction,
  }) async {
    final res = await _client.rpc('admin_schedules_clear', params: {
      'p_route_id': routeId,
      'p_day_type': dayType.name,
      'p_direction': direction,
    });
    return (res as num).toInt();
  }
}

final adminRoutesRepositoryProvider = Provider<AdminRoutesRepository>((ref) {
  return AdminRoutesRepository(ref.watch(supabaseClientProvider));
});

/// Alcance editable: admin → null (todas), operator_admin → su operatorId.
class ManageScope {
  ManageScope({required this.isAdmin, required this.operatorId});
  final bool isAdmin;
  final String? operatorId;
  bool get canEdit => isAdmin || operatorId != null;
}

/// Resuelve el alcance leyendo profiles.role + profiles.operator_id del
/// usuario auth actual.
final manageScopeProvider = FutureProvider<ManageScope>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final user = client.auth.currentUser;
  if (user == null) {
    return ManageScope(isAdmin: false, operatorId: null);
  }
  try {
    final row = await client
        .from('profiles')
        .select('role, operator_id')
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return ManageScope(isAdmin: false, operatorId: null);
    final role = row['role'] as String?;
    final opId = row['operator_id'] as String?;
    if (role == 'admin') return ManageScope(isAdmin: true, operatorId: null);
    return ManageScope(isAdmin: false, operatorId: opId);
  } catch (e) {
    AppLogger.warn(_tag, 'manageScopeProvider failed', e);
    return ManageScope(isAdmin: false, operatorId: null);
  }
});
