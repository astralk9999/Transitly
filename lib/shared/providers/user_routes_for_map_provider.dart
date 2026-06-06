import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_routes_repository.dart';
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
    // 2) Mis propias rutas publicadas, aunque sean unlisted/private.
    if (userId != null) {
      final mine = await repo.getMyRoutes();
      for (final r in mine) {
        if (r.status == 'published' || r.status == 'community_approved') {
          results.add(r);
        }
      }
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
