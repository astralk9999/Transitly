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
    this.zoneId,
    this.updatedAt,
    this.stopCount = 0,
    this.scheduleCount = 0,
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
  final String? zoneId;
  final DateTime? updatedAt;

  /// Nº de paradas y de horarios vinculados (para el resumen de la lista).
  final int stopCount;
  final int scheduleCount;

  /// Lee un `count` de una relación embebida de Supabase. El cliente lo
  /// devuelve como `[{count: N}]` con `select('rel(count)')`.
  static int _embeddedCount(dynamic rel) {
    if (rel is List && rel.isNotEmpty) {
      final first = rel.first;
      if (first is Map && first['count'] is num) {
        return (first['count'] as num).toInt();
      }
    }
    return 0;
  }

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
      zoneId: j['zone_id'] as String?,
      updatedAt: j['updated_at'] == null
          ? null
          : DateTime.tryParse(j['updated_at'] as String),
      stopCount: _embeddedCount(j['route_stops']),
      scheduleCount: _embeddedCount(j['schedules']),
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
    this.zoneId,
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
  final String? zoneId;

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
      zoneId: j['zone_id'] as String?,
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

/// Zona (municipio/distrito). status: active | pending.
class ZoneRow {
  ZoneRow({
    required this.id,
    required this.name,
    required this.zoneType,
    required this.status,
    this.operatorId,
    this.centerLat,
    this.centerLng,
    this.radiusM,
  });
  final String id;
  final String name;
  final String zoneType;
  final String status;
  final String? operatorId;
  final double? centerLat;
  final double? centerLng;
  final int? radiusM;
  bool get isPending => status == 'pending';

  /// `true` si tiene perímetro (centro + radio) definido.
  bool get hasGeometry =>
      centerLat != null && centerLng != null && radiusM != null;

  factory ZoneRow.fromRow(Map<String, dynamic> j) => ZoneRow(
        id: j['id'] as String,
        name: j['name'] as String,
        zoneType: j['zone_type'] as String? ?? 'municipality',
        status: j['status'] as String? ?? 'active',
        operatorId: j['operator_id'] as String?,
        centerLat: (j['center_lat'] as num?)?.toDouble(),
        centerLng: (j['center_lng'] as num?)?.toDouble(),
        radiusM: (j['radius_m'] as num?)?.toInt(),
      );
}

/// Expedición de horario con hora de paso por cada parada.
/// stopTimes: [{stop_id, time:'HH:MM'}, ...].
class AdminTripRow {
  AdminTripRow({
    required this.id,
    required this.dayType,
    required this.direction,
    required this.departureTime,
    required this.stopTimes,
  });
  final String id;
  final DayType dayType;
  final int direction;
  final String departureTime;
  final List<({String stopId, String time})> stopTimes;

  String? timeForStop(String stopId) {
    for (final st in stopTimes) {
      if (st.stopId == stopId) return st.time;
    }
    return null;
  }

  factory AdminTripRow.fromRow(Map<String, dynamic> j) {
    final raw = (j['arrival_offsets'] as List?) ?? const [];
    final times = raw
        .whereType<Map>()
        .map((m) => (
              stopId: m['stop_id'] as String? ?? '',
              time: (m['time'] as String? ?? '').padLeft(5, '0'),
            ))
        .where((e) => e.stopId.isNotEmpty)
        .toList();
    return AdminTripRow(
      id: j['id'] as String,
      dayType: DayType.fromString(j['day_type'] as String? ?? 'weekday'),
      direction: (j['direction'] as num?)?.toInt() ?? 0,
      departureTime: (j['departure_time'] as String? ?? '').padLeft(5, '0'),
      stopTimes: times,
    );
  }
}

class RouteChangeRow {
  RouteChangeRow({
    required this.changeType,
    required this.description,
    required this.createdAt,
  });
  final String changeType;
  final String description;
  final DateTime createdAt;

  factory RouteChangeRow.fromRow(Map<String, dynamic> j) => RouteChangeRow(
        changeType: j['change_type'] as String? ?? 'infoUpdated',
        description: j['description'] as String? ?? '',
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class AdminRoutesRepository {
  AdminRoutesRepository(this._client);
  final SupabaseClient _client;

  // ── Zonas ───────────────────────────────────────────────────
  Future<List<ZoneRow>> listZones({bool includePending = false}) async {
    final rows = await _client
        .rpc('list_zones', params: {'p_include_pending': includePending});
    return (rows as List)
        .map((e) => ZoneRow.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> zoneUpsert({
    String? id,
    required String name,
    String type = 'municipality',
    String? parentId,
    String? operatorId,
    double? centerLat,
    double? centerLng,
    int? radiusM,
  }) async {
    final res = await _client.rpc('zone_upsert', params: {
      'p_id': id,
      'p_name': name,
      'p_type': type,
      'p_parent': parentId,
      'p_operator_id': operatorId,
      'p_center_lat': centerLat,
      'p_center_lng': centerLng,
      'p_radius_m': radiusM,
    });
    return res as String;
  }

  /// Borra una zona (admin global o admin de su operadora). Usa RPC con
  /// SECURITY DEFINER si existe; si no, intenta delete directo (RLS).
  Future<void> zoneDelete(String id) async {
    try {
      await _client.rpc('zone_delete', params: {'p_id': id});
    } catch (_) {
      await _client.from('zones').delete().eq('id', id);
    }
  }

  Future<String> zoneRecommend(String name, {String type = 'municipality'}) async {
    final res = await _client
        .rpc('zone_recommend', params: {'p_name': name, 'p_type': type});
    return res as String;
  }

  // ── Trips (horarios por parada) ─────────────────────────────
  Future<List<AdminTripRow>> listTrips(String routeId) async {
    final rows =
        await _client.rpc('admin_list_trips', params: {'p_route_id': routeId});
    return (rows as List)
        .map((e) => AdminTripRow.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> tripUpsert({
    String? id,
    required String routeId,
    required DayType dayType,
    required int direction,
    required List<({String stopId, String time})> stopTimes,
  }) async {
    final payload = stopTimes
        .where((e) => e.time.isNotEmpty)
        .map((e) => {'stop_id': e.stopId, 'time': e.time})
        .toList();
    final res = await _client.rpc('admin_trip_upsert', params: {
      'p_id': id,
      'p_route_id': routeId,
      'p_day_type': dayType.name,
      'p_direction': direction,
      'p_stop_times': payload,
    });
    return res as String;
  }

  Future<void> tripDelete(String id) =>
      _client.rpc('admin_trip_delete', params: {'p_id': id});

  // ── Changelog ───────────────────────────────────────────────
  Future<List<RouteChangeRow>> listChangelog(String routeId) async {
    final rows = await _client
        .rpc('list_route_changelog', params: {'p_route_id': routeId});
    return (rows as List)
        .map((e) => RouteChangeRow.fromRow(e as Map<String, dynamic>))
        .toList();
  }

  // ── Códigos de invitación ───────────────────────────────────
  Future<String> createInvitationCode({
    required String operatorId,
    String kind = 'driver',
    int maxUses = 1,
    int expiresDays = 30,
  }) async {
    final res = await _client.rpc('create_invitation_code', params: {
      'p_operator_id': operatorId,
      'p_max_uses': maxUses,
      'p_expires_days': expiresDays,
      'p_kind': kind,
    });
    return res as String;
  }

  // ── Rutas ───────────────────────────────────────────────────
  Future<List<AdminRouteRow>> listRoutes({String? operatorId}) async {
    // `route_stops(count)` y `schedules(count)` traen los contadores en la
    // misma consulta sin N+1.
    var q = _client.from('routes').select(
        'id, operator_id, code, name, description, color, status, source, metadata, zone_id, updated_at, route_stops(count), schedules(count)');
    if (operatorId != null) q = q.eq('operator_id', operatorId);
    final rows = await q.order('code');
    return (rows as List).map((e) => AdminRouteRow.fromRow(e as Map<String, dynamic>)).toList();
  }

  Future<AdminRouteRow?> getRoute(String id) async {
    final row = await _client
        .from('routes')
        .select(
            'id, operator_id, code, name, description, color, status, source, metadata, zone_id, updated_at')
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
    String? zoneId,
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
      'p_zone_id': zoneId,
    });
    return res as String;
  }

  Future<void> deleteRoute(String id) =>
      _client.rpc('admin_route_delete', params: {'p_id': id});

  /// Guarda el TRAZADO (polilínea multinivel) de una ruta oficial en
  /// `metadata.polyline_lod`, de donde lo lee `snapshot_lines` para el mapa.
  /// [polylineLod] = { 'lod0': [[lng,lat],...], ..., 'lod4': [...] }.
  Future<void> setRoutePolyline({
    required String routeId,
    required Map<String, List<List<double>>> polylineLod,
  }) =>
      _client.rpc('admin_route_set_polyline', params: {
        'p_id': routeId,
        'p_polyline_lod': polylineLod,
      });

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
    String? zoneId,
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
      'p_zone_id': zoneId,
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

/// Changelog de una ruta, CACHEADO por routeId. Antes la UI creaba el Future
/// dentro de `build()` (FutureBuilder), así que cada rebuild del detalle
/// generaba una petición nueva → volvía a "cargando" → parpadeo constante.
/// Con este provider el resultado se memoiza y solo se vuelve a pedir si se
/// invalida explícitamente.
final routeChangelogProvider =
    FutureProvider.family<List<RouteChangeRow>, String>((ref, routeId) {
  return ref.watch(adminRoutesRepositoryProvider).listChangelog(routeId);
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
