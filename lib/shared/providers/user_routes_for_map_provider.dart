import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_route_schedules_repository.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/user_stops/user_stops_repository.dart';
import '../models/enums.dart';
import '../models/route_model.dart';
import 'auth_provider.dart';
import 'user_favorites_provider.dart';

const _logTag = 'UserRoutesForMap';

/// Lee SOLO las rutas del usuario actual (creadas + importadas) y las
/// convierte a [RouteModel] para que `MapTab` pueda mezclarlas con las
/// oficiales de COMUJESA.
///
/// IMPORTANTE: el mapa NO descarga todas las rutas públicas de la
/// comunidad — eso saturaría la vista y descargaría rutas que el usuario
/// no ha elegido. El descubrimiento se hace en la pantalla `/community`
/// (vía `searchPublic`); al importar una ruta, se crea una copia con
/// `author_id = usuario`, por lo que entra en `getMyRoutes()` y aparece
/// en el mapa.
///
/// No incluye polilíneas ni paradas — solo metadatos suficientes para
/// que aparezcan en la lista del bottom-sheet y los filtros. El detalle
/// completo se sigue cargando con `userRoutesRepository.getById` cuando
/// el usuario abre la ruta.
final userRoutesForMapProvider =
    FutureProvider<List<RouteModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId =
      authState is AuthAuthenticated ? authState.user.id : null;

  if (userId == null) return const <RouteModel>[];

  final repo = UserRoutesRepository(client);
  final byId = <String, UserRouteModel>{};
  try {
    // SOLO mis rutas (creadas, importadas, borradores, privadas…). El
    // usuario decide qué rutas de comunidad descargar importándolas.
    for (final r in await repo.getMyRoutes()) {
      byId[r.id] = r;
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'load failed', e);
  }

  return byId.values
      .map((u) => _toRouteModel(u))
      .toList(growable: false);
});

class MapStopPoint {
  MapStopPoint(this.id, this.name, this.lat, this.lng);
  final String id;
  final String name;
  final double lat;
  final double lng;
}

/// Línea de comunidad del usuario, lista para el árbol de filtros del mapa
/// (id, código, nombre, color y la zona/region elegida al crearla).
class CommunityFilterRoute {
  CommunityFilterRoute({
    required this.id,
    required this.code,
    required this.name,
    required this.color,
    this.region,
  });
  final String id;
  final String code;
  final String name;
  final Color color;
  final String? region;
}

/// Mis líneas de comunidad (creadas/importadas) con su zona, para poder
/// activarlas/desactivarlas en los filtros del mapa igual que las oficiales.
final communityFilterRoutesProvider =
    FutureProvider<List<CommunityFilterRoute>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId = authState is AuthAuthenticated ? authState.user.id : null;
  if (userId == null) return const <CommunityFilterRoute>[];
  try {
    final routes = await UserRoutesRepository(client).getMyRoutes();
    return routes
        .map((u) => CommunityFilterRoute(
              id: u.id,
              code: _shortCode(u),
              name: u.name,
              color: _parseColor(u.routeColor),
              region: (u.region != null && u.region!.trim().isNotEmpty)
                  ? u.region!.trim()
                  : null,
            ))
        .toList(growable: false);
  } catch (e) {
    AppLogger.warn(_logTag, 'community filter routes load failed', e);
    return const <CommunityFilterRoute>[];
  }
});

/// Forma (paradas en orden + color) de una ruta de comunidad para el mapa.
class CommunityRouteShape {
  CommunityRouteShape(this.routeId, this.name, this.code, this.color,
      this.points, this.stops, this.hoursByStop);
  final String routeId;
  final String name;
  final String code;
  final Color color;
  final List<LatLng> points;
  final List<MapStopPoint> stops;

  /// stopId → horas (HH:mm ordenadas) a las que el bus pasa por esa parada.
  final Map<String, List<String>> hoursByStop;

  /// Próxima hora desde ahora para la parada indicada (o null).
  String? nextHourFor(String stopId) {
    final hours = hoursByStop[stopId];
    if (hours == null || hours.isEmpty) return null;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final h in hours) {
      final parts = h.split(':');
      if (parts.length < 2) continue;
      final m = (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
      if (m >= nowMin) return h;
    }
    return hours.first; // si todas pasaron, la primera de mañana
  }
}

/// Fuente única: SOLO las rutas del usuario (creadas/importadas), con sus
/// paradas en orden. De aquí derivan las polilíneas, los marcadores y las
/// bounds para "ir a la línea".
///
/// El mapa NO dibuja todas las rutas públicas de la comunidad (saturaría
/// la vista); el usuario las descarga eligiéndolas e importándolas desde
/// `/community`.
final communityRouteShapesProvider =
    FutureProvider<List<CommunityRouteShape>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId =
      authState is AuthAuthenticated ? authState.user.id : null;

  if (userId == null) return const <CommunityRouteShape>[];

  final routesRepo = UserRoutesRepository(client);
  final stopsRepo = UserStopsRepository(client);
  final schedRepo = UserRouteSchedulesRepository(client);
  final byId = <String, UserRouteModel>{};
  try {
    for (final r in await routesRepo.getMyRoutes()) {
      byId[r.id] = r;
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'shapes routes load failed', e);
  }

  final out = <CommunityRouteShape>[];
  for (final r in byId.values) {
    try {
      final rs = await stopsRepo.getStopsForRoute(r.id);
      rs.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final coordOf = <String, LatLng>{};
      final stops = <MapStopPoint>[];
      for (final s in rs) {
        if (s.stop != null) {
          coordOf[s.userStopId] = LatLng(s.stop!.lat, s.stop!.lng);
          stops.add(MapStopPoint(
              s.userStopId, s.stop!.name, s.stop!.lat, s.stop!.lng));
        }
      }
      // Polilínea: usa el trazado guardado (parada origen → puntos
      // intermedios → parada destino por segmento) si existe; si no, une
      // las paradas en orden con líneas rectas.
      final pts = <LatLng>[];
      if (r.path != null && r.path!.isNotEmpty) {
        for (final seg in r.path!) {
          if (seg is! Map) continue;
          final from = coordOf[seg['from']];
          if (from != null) pts.add(from);
          for (final p in (seg['points'] as List? ?? const [])) {
            if (p is Map) {
              pts.add(LatLng((p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble()));
            }
          }
          final to = coordOf[seg['to']];
          if (to != null) pts.add(to);
        }
      }
      if (pts.isEmpty) {
        for (final s in rs) {
          if (s.stop != null) pts.add(LatLng(s.stop!.lat, s.stop!.lng));
        }
      }
      // Horarios por parada (origin_stop_id → horas HH:mm ordenadas).
      final hoursByStop = <String, List<String>>{};
      try {
        final schedules = await schedRepo.getForRoute(r.id);
        for (final s in schedules) {
          if (s.originStopId == null) continue;
          (hoursByStop[s.originStopId!] ??= []).add(s.departureTime);
        }
        for (final list in hoursByStop.values) {
          list.sort();
        }
      } catch (_) {}
      if (pts.isNotEmpty) {
        out.add(CommunityRouteShape(
            r.id,
            r.name,
            _shortCode(r),
            _parseColor(r.routeColor),
            pts,
            stops,
            hoursByStop));
      }
    } catch (_) {}
  }
  return out;
});

/// Distancia aproximada en metros entre dos coords (suficiente para
/// agrupar paradas que comparten ubicación entre rutas distintas).
double metersBetween(double lat1, double lng1, double lat2, double lng2) {
  const d = Distance();
  return d.as(LengthUnit.Meter, LatLng(lat1, lng1), LatLng(lat2, lng2));
}

/// Polilíneas derivadas (para dibujar en el mapa).
final myRoutePolylinesProvider = Provider<List<Polyline<Object>>>((ref) {
  final shapes = ref.watch(communityRouteShapesProvider).valueOrNull ?? const [];
  return [
    for (final s in shapes)
      if (s.points.length >= 2)
        Polyline<Object>(
          points: s.points,
          strokeWidth: 4,
          color: s.color.withValues(alpha: 0.85),
        ),
  ];
});

/// Paradas de comunidad marcadas como favoritas, resueltas a partir de las
/// rutas del usuario (creadas/importadas). Las favoritas oficiales las
/// resuelve Inicio con mockData; aquí solo salen las que corresponden a una
/// parada de comunidad. Dedup por proximidad (misma ubicación física puede
/// tener varios ids entre rutas).
final communityFavoriteStopsProvider = Provider<List<MapStopPoint>>((ref) {
  final favIds = ref.watch(userFavoriteStopsProvider);
  if (favIds.isEmpty) return const [];
  final shapes =
      ref.watch(communityRouteShapesProvider).valueOrNull ?? const [];
  final byId = <String, MapStopPoint>{};
  for (final sh in shapes) {
    for (final p in sh.stops) {
      byId[p.id] = p;
    }
  }
  final out = <MapStopPoint>[];
  final seen = <String>{};
  for (final id in favIds) {
    final p = byId[id];
    if (p == null) continue; // no es una parada de comunidad de mis rutas
    final key = '${p.lat.toStringAsFixed(4)},${p.lng.toStringAsFixed(4)}';
    if (seen.add(key)) out.add(p);
  }
  return out;
});

/// `true` si el id parece un UUID (rutas de comunidad) y no un código de
/// línea oficial (L1, C1…).
bool _looksLikeUuid(String s) => s.length == 36 && s.contains('-');

/// Una línea de comunidad favorita + su nº de paradas (para Inicio › Mis
/// líneas).
class CommunityFavoriteRoute {
  CommunityFavoriteRoute(this.route, this.stopCount);
  final RouteModel route;
  final int stopCount;
}

/// Líneas de comunidad marcadas como favoritas, resueltas a [RouteModel] con
/// su nº de paradas para mostrarlas en Inicio › Mis líneas (las oficiales las
/// resuelve Inicio con mockData). Una sola consulta por id-UUID; la RLS
/// devuelve solo las legibles (públicas o propias).
final communityFavoriteRoutesProvider =
    FutureProvider<List<CommunityFavoriteRoute>>((ref) async {
  final favIds = ref.watch(userFavoritesProvider);
  final uuidIds = favIds.where(_looksLikeUuid).toList();
  if (uuidIds.isEmpty) return const [];
  final client = ref.watch(supabaseClientProvider);
  try {
    final rows = await client
        .from('user_routes')
        .select('*, user_route_stops(count)')
        .inFilter('id', uuidIds);
    return (rows as List).map((j) {
      final m = j as Map<String, dynamic>;
      // user_route_stops(count) → [{count: N}].
      var stops = 0;
      final cnt = m['user_route_stops'];
      if (cnt is List && cnt.isNotEmpty && cnt.first is Map) {
        stops = ((cnt.first as Map)['count'] as num?)?.toInt() ?? 0;
      }
      return CommunityFavoriteRoute(
          _toRouteModel(UserRouteModel.fromJson(m)), stops);
    }).toList(growable: false);
  } catch (e) {
    AppLogger.warn(_logTag, 'fav community routes load failed', e);
    return const [];
  }
});

/// Marcadores de paradas derivados (dedup por id).
final myRouteStopsProvider = Provider<List<MapStopPoint>>((ref) {
  final shapes = ref.watch(communityRouteShapesProvider).valueOrNull ?? const [];
  final byId = <String, MapStopPoint>{};
  for (final s in shapes) {
    for (final p in s.stops) {
      byId[p.id] = p;
    }
  }
  return byId.values.toList(growable: false);
});

/// Una línea de comunidad que pasa por una parada, con sus horas de paso
/// por ESA parada agrupadas por tipo de día (mismos buckets que el horario
/// oficial: weekday / saturday / sunday_holiday).
class CommunityStopLine {
  CommunityStopLine(
      this.routeId, this.code, this.name, this.color, this.hoursByDay);
  final String routeId;
  final String code;
  final String name;
  final Color color;

  /// bucket de día → horas HH:mm ordenadas a las que el bus pasa por la parada.
  final Map<String, List<String>> hoursByDay;
}

/// Horario de una parada de comunidad: nombre + líneas que pasan por ella.
class CommunityStopTimetable {
  CommunityStopTimetable(this.stopName, this.lat, this.lng, this.lines);
  final String stopName;
  final double lat;
  final double lng;
  final List<CommunityStopLine> lines;
}

List<String> _dayBuckets(String dt) => switch (dt) {
      'saturday' => const ['saturday'],
      'sunday' || 'holiday' => const ['sunday_holiday'],
      'weekday' => const ['weekday'],
      'every_day' => const ['weekday', 'saturday', 'sunday_holiday'],
      _ => const ['weekday'],
    };

/// Horario de UNA parada de comunidad (solo lo de esa parada, como la
/// pantalla de detalle de las paradas oficiales). Resuelve, por proximidad,
/// todas las líneas del usuario que pasan por ahí y, para cada una, sus
/// horas de paso por la parada agrupadas por día.
final communityStopTimetableProvider = FutureProvider.autoDispose
    .family<CommunityStopTimetable?, String>((ref, stopId) async {
  final shapes = await ref.watch(communityRouteShapesProvider.future);

  // Ancla: la parada física a partir de su id (pertenece a una ruta concreta).
  MapStopPoint? anchor;
  for (final sh in shapes) {
    for (final p in sh.stops) {
      if (p.id == stopId) {
        anchor = p;
        break;
      }
    }
    if (anchor != null) break;
  }
  if (anchor == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final schedRepo = UserRouteSchedulesRepository(client);
  final lines = <CommunityStopLine>[];
  for (final sh in shapes) {
    // ¿Pasa esta línea por la parada? (mismo id o por proximidad <35m).
    String? stopInRoute;
    for (final p in sh.stops) {
      if (p.id == anchor.id ||
          metersBetween(p.lat, p.lng, anchor.lat, anchor.lng) < 35) {
        stopInRoute = p.id;
        break;
      }
    }
    if (stopInRoute == null) continue;

    final byDay = <String, List<String>>{};
    try {
      for (final s in await schedRepo.getForRoute(sh.routeId)) {
        if (s.originStopId != stopInRoute) continue;
        for (final b in _dayBuckets(s.dayType)) {
          (byDay[b] ??= []).add(s.departureTime);
        }
      }
    } catch (_) {}
    for (final l in byDay.values) {
      l.sort();
    }
    lines.add(CommunityStopLine(sh.routeId, sh.code, sh.name, sh.color, byDay));
  }
  lines.sort((a, b) => a.code.compareTo(b.code));
  return CommunityStopTimetable(anchor.name, anchor.lat, anchor.lng, lines);
});

RouteModel _toRouteModel(UserRouteModel u) {
  return RouteModel(
    id: u.id,
    operatorId: 'community',
    code: _shortCode(u),
    name: u.name,
    serviceType: _mapServiceType(u.serviceType),
    routeColor: _parseColor(u.routeColor),
    source: RouteSource.community,
    status: u.status == 'community_approved'
        ? RouteStatus.official
        : RouteStatus.verified,
    active: true,
    lastUpdatedAt: u.updatedAt ?? u.createdAt,
  );
}

/// Si `share_code` no existe, usamos las 2 primeras letras del nombre.
String _shortCode(UserRouteModel u) {
  if (u.shareCode != null && u.shareCode!.isNotEmpty) {
    return u.shareCode!.substring(0, u.shareCode!.length > 4 ? 4 : u.shareCode!.length);
  }
  final cleaned = u.name.trim().toUpperCase();
  return cleaned.isEmpty
      ? 'U'
      : cleaned.substring(0, cleaned.length > 3 ? 3 : cleaned.length);
}

ServiceType _mapServiceType(String raw) {
  return switch (raw) {
    'urban' => ServiceType.urban,
    'interurban' => ServiceType.interurban,
    'long_distance' => ServiceType.longDistance,
    'school' => ServiceType.school,
    'on_demand' => ServiceType.onDemand,
    _ => ServiceType.special,
  };
}

Color _parseColor(String hex) {
  try {
    final clean = hex.replaceFirst('#', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
  } catch (_) {}
  return const Color(0xFF977DDF);
}
