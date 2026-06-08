import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/arrivals/arrivals_repository.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_route_schedules_repository.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/widgets_native/widget_data_writer.dart';
import 'home_habitual_config_provider.dart';
import 'user_favorites_provider.dart';

final widgetDataSyncProvider = Provider<void>((ref) {
  final cfg = ref.watch(homeHabitualConfigProvider);
  if (!cfg.isConfigured) {
    // Sin viaje habitual: rellena el widget "mi línea" con la primera línea
    // favorita, para que el widget tenga datos desde el primer momento.
    _fillFromFavorite(ref);
    return;
  }

  final mockData = ref.watch(mockDataServiceProvider);
  final route = mockData.getRouteById(cfg.routeId!);
  if (route == null) return;

  final stop = mockData.getStopById(cfg.stopId!);

  final arrivalsRepo = ref.read(arrivalsRepositoryProvider);

  if (arrivalsRepo != null) {
    unawaited(_pushFromSupabase(arrivalsRepo, route.code, stop, mockData, cfg));
  }

  final deps = mockData.getNextDepartures(cfg.routeId!, cfg.stopId!, 4);
  if (deps.isNotEmpty) {
    final dep = deps.first;
    final now = DateTime.now();
    final parts = dep.departureTime.split(':');
    final depHour = int.tryParse(parts[0]) ?? 0;
    final depMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    final depTotalMin = depHour * 60 + depMin;
    final nowMinutes = now.hour * 60 + now.minute;
    var etaMinutes = depTotalMin - nowMinutes;
    if (etaMinutes < 0) etaMinutes += 24 * 60;

    WidgetDataWriter.writeNextBus(
      stopName: stop?.name ?? cfg.stopId!,
      routeCode: route.code,
      etaMinutes: etaMinutes,
      source: 'schedule',
      updatedAt: now,
    );

    WidgetDataWriter.writeMyLineStatus(
      routeCode: route.code,
      upcoming: deps
          .map((d) => {
                'time': d.departureTime,
              })
          .toList(),
    );
  }
});

/// Rellena el widget "mi línea" desde la primera línea favorita (cuando no
/// hay viaje habitual configurado), para que el widget no quede vacío.
/// Soporta líneas OFICIALES y de la COMUNIDAD (estas se cargan de Supabase).
void _fillFromFavorite(Ref ref) {
  final favs = ref.watch(userFavoritesProvider);
  if (favs.isEmpty) return;
  final mockData = ref.watch(mockDataServiceProvider);

  // 1) Primera favorita OFICIAL (mockData).
  for (final id in favs) {
    final route = mockData.getRouteById(id);
    if (route == null) continue;
    final stops = mockData.getStopsForRoute(route.id);
    final stopId = stops.isNotEmpty ? stops.first.id : '';
    final deps = mockData.getNextDepartures(route.id, stopId, 4);
    if (deps.isEmpty) continue;
    WidgetDataWriter.writeMyLineStatus(
      routeCode: route.code,
      upcoming: deps.map((d) => {'time': d.departureTime}).toList(),
    );
    final now = DateTime.now();
    final parts = deps.first.departureTime.split(':');
    final depMin = (int.tryParse(parts[0]) ?? 0) * 60 +
        (parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0);
    var eta = depMin - (now.hour * 60 + now.minute);
    if (eta < 0) eta += 24 * 60;
    WidgetDataWriter.writeNextBus(
      stopName: stops.isNotEmpty ? stops.first.name : route.name,
      routeCode: route.code,
      etaMinutes: eta,
      source: 'favorite',
      updatedAt: now,
    );
    return; // ya hay una oficial; suficiente para el widget
  }

  // 2) Si no hay favorita oficial, intenta una de COMUNIDAD (UUID) desde
  //    Supabase (línea + sus horarios del día).
  final community = favs.where((s) => s.length == 36 && s.contains('-'));
  if (community.isNotEmpty) {
    unawaited(_pushFromCommunity(ref, community.first));
  }
}

/// Escribe el widget desde una línea de comunidad favorita: su código/nombre
/// y las próximas salidas del día actual (user_route_schedules).
Future<void> _pushFromCommunity(Ref ref, String routeId) async {
  try {
    final client = ref.read(supabaseClientProvider);
    final route = await UserRoutesRepository(client).getById(routeId);
    if (route == null) return;
    final scheds = await UserRouteSchedulesRepository(client).getForRoute(routeId);
    if (scheds.isEmpty) return;
    // Día actual → buckets de user_route_schedules.
    final today = switch (DateTime.now().weekday) {
      DateTime.saturday => const ['saturday', 'every_day'],
      DateTime.sunday => const ['sunday', 'holiday', 'every_day'],
      _ => const ['weekday', 'every_day'],
    };
    final times = scheds
        .where((s) => today.contains(s.dayType))
        .map((s) => s.departureTime)
        .toSet()
        .toList()
      ..sort();
    if (times.isEmpty) return;
    final code = (route.code != null && route.code!.isNotEmpty)
        ? route.code!
        : route.name;
    WidgetDataWriter.writeMyLineStatus(
      routeCode: code,
      upcoming: times.map((t) => {'time': t}).toList(),
    );
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    // Próxima salida desde ahora.
    var nextEta = 24 * 60;
    for (final t in times) {
      final p = t.split(':');
      final m = (int.tryParse(p[0]) ?? 0) * 60 +
          (p.length > 1 ? (int.tryParse(p[1]) ?? 0) : 0);
      var eta = m - nowMin;
      if (eta < 0) eta += 24 * 60;
      if (eta < nextEta) nextEta = eta;
    }
    WidgetDataWriter.writeNextBus(
      stopName: route.name,
      routeCode: code,
      etaMinutes: nextEta,
      source: 'community',
      updatedAt: now,
    );
  } catch (_) {}
}

Future<void> _pushFromSupabase(
  ArrivalsRepository repo,
  String routeCode,
  dynamic stop,
  dynamic mockData,
  dynamic cfg,
) async {
  try {
    final arrivals = await repo.getForRoute(routeCode, limit: 4);
    if (arrivals.isEmpty) return;

    final first = arrivals.first;
    final now = DateTime.now();

    WidgetDataWriter.writeNextBus(
      stopName: (stop?.name as String?) ?? (cfg.stopId as String),
      routeCode: routeCode,
      etaMinutes: first.minutesRounded,
      source: 'supabase',
      updatedAt: now,
    );

    WidgetDataWriter.writeMyLineStatus(
      routeCode: routeCode,
      upcoming: arrivals
          .map((a) => {
                'time': a.departureTime,
              })
          .toList(),
    );
  } catch (_) {}
}
