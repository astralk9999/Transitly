import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/arrivals/arrivals_repository.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/widgets_native/widget_data_writer.dart';
import 'home_habitual_config_provider.dart';

final widgetDataSyncProvider = Provider<void>((ref) {
  final cfg = ref.watch(homeHabitualConfigProvider);
  if (!cfg.isConfigured) return;

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
