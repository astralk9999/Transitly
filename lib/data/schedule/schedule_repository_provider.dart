import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/schedule_model.dart';
import '../cache/hive_box_provider.dart';
import '../mock/mock_data_service.dart';
import '../supabase/supabase_client_provider.dart';
import 'domain/schedule_repository.dart';
import 'local/schedule_local_repository.dart';
import 'local/schedule_mock_repository.dart';
import 'remote/schedule_remote_repository.dart';

/// Stale-while-revalidate sobre cache local + Supabase para horarios.
class ScheduleRepositorySwr implements ScheduleRepository {
  ScheduleRepositorySwr({required this.local, required this.remote});

  final ScheduleLocalRepository local;
  final ScheduleRemoteRepository remote;

  static const _logTag = 'Repo:Schedule';

  @override
  Future<List<ScheduleModel>> forRoute(
    String routeId, {
    DayType? dayType,
  }) async {
    final cached = await local.forRoute(routeId, dayType: dayType);
    if (cached.isNotEmpty) {
      unawaited(_refreshForRoute(routeId, dayType: dayType));
      return cached;
    }
    final fresh = await remote.forRoute(routeId, dayType: dayType);
    await local.upsertAll(fresh);
    return fresh;
  }

  Future<void> _refreshForRoute(
    String routeId, {
    DayType? dayType,
  }) async {
    try {
      final fresh = await remote.forRoute(routeId, dayType: dayType);
      await local.upsertAll(fresh);
    } on ScheduleRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh forRoute($routeId)', e);
    }
  }

  @override
  Future<List<ScheduleModel>> nextDepartures(
      String routeId, int count) async {
    final cached = await local.nextDepartures(routeId, count);
    if (cached.length >= count) {
      unawaited(_refreshForRoute(routeId));
      return cached;
    }
    try {
      final fresh = await remote.nextDepartures(routeId, count);
      await local.upsertAll(fresh);
      return fresh;
    } on ScheduleRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'nextDepartures remote failed, returning cache',
          e);
      return cached;
    }
  }
}

final scheduleRepositoryProvider = Provider.autoDispose<ScheduleRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    final mockData = ref.watch(mockDataServiceProvider);
    return ScheduleMockRepository(mockData);
  }

  final box = ref.watch(schedulesBoxProvider);
  return ScheduleRepositorySwr(
    local: ScheduleLocalRepository(box),
    remote: ScheduleRemoteRepository(client),
  );
});
