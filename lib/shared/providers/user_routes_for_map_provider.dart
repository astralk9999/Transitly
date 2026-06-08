import 'dart:ui';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
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

/// Polylines de las rutas propias del usuario (creadas o importadas), para
/// dibujarlas en SU mapa sin necesidad de que un admin las oficialice.
/// Carga las paradas de cada ruta y las une en orden.
final myRoutePolylinesProvider =
    FutureProvider<List<Polyline<Object>>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState is! AuthAuthenticated) return const [];

  final routesRepo = UserRoutesRepository(client);
  final stopsRepo = UserStopsRepository(client);
  final out = <Polyline<Object>>[];
  try {
    final mine = await routesRepo.getMyRoutes();
    for (final r in mine) {
      final rs = await stopsRepo.getStopsForRoute(r.id);
      final pts = (rs..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)))
          .where((s) => s.stop != null)
          .map((s) => LatLng(s.stop!.lat, s.stop!.lng))
          .toList();
      if (pts.length >= 2) {
        out.add(Polyline<Object>(
          points: pts,
          strokeWidth: 4,
          color: _parseColor(r.routeColor).withValues(alpha: 0.85),
        ));
      }
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'polylines load failed', e);
  }
  return out;
});

/// Paradas (con coordenadas) de las rutas propias del usuario, para
/// dibujarlas como marcadores en SU mapa. Dedup por id.
class MapStopPoint {
  MapStopPoint(this.id, this.name, this.lat, this.lng);
  final String id;
  final String name;
  final double lat;
  final double lng;
}

final myRouteStopsProvider =
    FutureProvider<List<MapStopPoint>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).valueOrNull;
  if (authState is! AuthAuthenticated) return const [];

  final routesRepo = UserRoutesRepository(client);
  final stopsRepo = UserStopsRepository(client);
  final byId = <String, MapStopPoint>{};
  try {
    final mine = await routesRepo.getMyRoutes();
    for (final r in mine) {
      final rs = await stopsRepo.getStopsForRoute(r.id);
      for (final s in rs) {
        if (s.stop != null) {
          byId[s.userStopId] =
              MapStopPoint(s.userStopId, s.stop!.name, s.stop!.lat, s.stop!.lng);
        }
      }
    }
  } catch (e) {
    AppLogger.warn(_logTag, 'stops load failed', e);
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
