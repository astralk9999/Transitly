import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';

class Arrival {
  const Arrival({
    required this.departureTime,
    required this.minutesUntil,
  });

  final String departureTime;
  final double minutesUntil;

  factory Arrival.fromJson(Map<String, dynamic> json) {
    return Arrival(
      departureTime: json['departure_time'] as String,
      minutesUntil: (json['minutes_until'] as num).toDouble(),
    );
  }

  int get minutesRounded => minutesUntil.round();

  bool get isImminent => minutesUntil <= 5;
}

class ArrivalsRepository {
  ArrivalsRepository(this._supabase, this._hive);
  final SupabaseClient _supabase;
  final Box<Map<dynamic, dynamic>> _hive;
  static const _logTag = 'Repo:Arrivals';
  static const _cacheTtlSeconds = 90;

  Future<List<Arrival>> getForRoute(String routeCode, {int limit = 4}) async {
    final cacheKey = 'arrivals:$routeCode:$limit';
    final cached = _readCache(cacheKey);
    if (cached != null) return cached;

    try {
      final res = await _supabase.rpc('get_next_departures_for_route', params: {
        'p_route_code': routeCode,
        'p_limit': limit,
      });

      final list = _parseArrivals(res);
      _writeCache(cacheKey, list);
      return list;
    } catch (e) {
      AppLogger.warn(_logTag, 'getForRoute failed, using cache or empty', e);
      return cached ?? [];
    }
  }

  Future<List<Arrival>> getForRouteStop(
    String routeCode,
    int stopIndex, {
    int limit = 4,
  }) async {
    final cacheKey = 'arrivals:$routeCode:$stopIndex:$limit';
    final cached = _readCache(cacheKey);
    if (cached != null) return cached;

    try {
      final res = await _supabase.rpc('get_next_departures_for_route_stop', params: {
        'p_route_code': routeCode,
        'p_stop_index': stopIndex,
        'p_limit': limit,
      });

      final list = _parseArrivals(res);
      _writeCache(cacheKey, list);
      return list;
    } catch (e) {
      AppLogger.warn(_logTag, 'getForRouteStop failed, using cache or empty', e);
      return cached ?? [];
    }
  }

  List<Arrival> _parseArrivals(dynamic res) {
    if (res == null) return [];
    if (res is List) {
      return res.map((j) => Arrival.fromJson(j as Map<String, dynamic>)).toList();
    }
    if (res is String && (res == '[]' || res == 'null')) return [];
    return [];
  }

  List<Arrival>? _readCache(String key) {
    try {
      final entry = _hive.get(key);
      if (entry == null) return null;

      final timestamp = entry['ts'] as int? ?? 0;
      final ageSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 - timestamp;
      if (ageSeconds > _cacheTtlSeconds) return null;

      final data = entry['data'] as List<dynamic>?;
      if (data == null) return null;

      return data
          .map((j) => Arrival.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  void _writeCache(String key, List<Arrival> list) {
    try {
      _hive.put(key, {
        'ts': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'data': list.map((a) => {
          'departure_time': a.departureTime,
          'minutes_until': a.minutesUntil,
        }).toList(),
      });
    } catch (e) {
      AppLogger.warn(_logTag, 'cache write failed', e);
    }
  }
}

final arrivalsRepositoryProvider = Provider.autoDispose<ArrivalsRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;
  if (session == null) return null;
  final box = ref.watch(arrivalsCacheBoxProvider);
  return ArrivalsRepository(client, box);
});
