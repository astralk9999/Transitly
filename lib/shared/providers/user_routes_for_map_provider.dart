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

const _logTag = 'UserRoutesForMap';

/// Lee `user_routes` publicadas (públicas + propias publicadas) y las
/// convierte a [RouteModel] para que `MapTab` pueda mezclarlas con las
/// oficiales de COMUJESA.
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

  final repo = UserRoutesRepository(client);
  final results = <UserRouteModel>[];
  try {
    // 1) Rutas públicas + publicadas/aprobadas de cualquier autor.
    results.addAll(await repo.searchPublic(limit: 100));
    // 2) TODAS mis rutas (creadas, importadas, borradores, privadas…). El
    //    usuario debe ver sus propias rutas en su mapa sin necesidad de que
    //    un admin las oficialice ni de publicarlas.
    if (userId != null) {
      results.addAll(await repo.getMyRoutes());
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'load failed', e);
  }

  // Deduplicar por id (mis rutas públicas aparecen en ambas listas).
  final byId = <String, UserRouteModel>{};
  for (final r in results) {
    byId[r.id] = r;
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

/// Fuente única: rutas propias del usuario (creadas/importadas) + rutas
/// públicas de comunidad, con sus paradas en orden. De aquí derivan las
/// polilíneas, los marcadores y las bounds para "ir a la línea".
final communityRouteShapesProvider =
    FutureProvider<List<CommunityRouteShape>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  final userId =
      authState is AuthAuthenticated ? authState.user.id : null;

  final routesRepo = UserRoutesRepository(client);
  final stopsRepo = UserStopsRepository(client);
  final schedRepo = UserRouteSchedulesRepository(client);
  final byId = <String, UserRouteModel>{};
  try {
    for (final r in await routesRepo.searchPublic(limit: 100)) {
      byId[r.id] = r;
    }
    if (userId != null) {
      for (final r in await routesRepo.getMyRoutes()) {
        byId[r.id] = r;
      }
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
