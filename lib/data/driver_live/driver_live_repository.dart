import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../supabase/supabase_client_provider.dart';

const _logTag = 'DriverLive';

/// Un viaje de conductor en vivo (su posición GPS actual + la línea/hora).
class DriverLiveTrip {
  DriverLiveTrip({
    required this.id,
    required this.driverId,
    required this.routeId,
    required this.routeCode,
    required this.routeName,
    required this.routeColor,
    required this.departureTime,
    required this.lat,
    required this.lng,
    required this.driverName,
    required this.updatedAt,
  });

  final String id;
  final String driverId;
  final String routeId;
  final String? routeCode;
  final String? routeName;
  final String? routeColor;
  final String? departureTime;
  final double lat;
  final double lng;
  final String? driverName;
  final DateTime? updatedAt;

  factory DriverLiveTrip.fromJson(Map<String, dynamic> j) => DriverLiveTrip(
        id: j['id'] as String,
        driverId: j['driver_id'] as String,
        routeId: j['route_id'] as String,
        routeCode: j['route_code'] as String?,
        routeName: j['route_name'] as String?,
        routeColor: j['route_color'] as String?,
        departureTime: j['departure_time'] as String?,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        driverName: j['driver_name'] as String?,
        updatedAt: j['updated_at'] != null
            ? DateTime.tryParse(j['updated_at'] as String)
            : null,
      );
}

class DriverLiveRepository {
  DriverLiveRepository(this._client);
  final SupabaseClient _client;

  /// Inicia un viaje en vivo (cierra cualquiera previo del conductor).
  Future<String> startTrip({
    required String routeId,
    String? routeCode,
    String? routeName,
    String? routeColor,
    String? departureTime,
    String? operatorId,
    String? driverName,
    required double lat,
    required double lng,
  }) async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw StateError('Auth requerida');
    // Cierra cualquier viaje activo previo (índice único de 1 activo/driver).
    await endTrip();
    final res = await _client.from('driver_live_trips').insert({
      'driver_id': uid,
      'operator_id': operatorId,
      'route_id': routeId,
      'route_code': routeCode,
      'route_name': routeName,
      'route_color': routeColor,
      'departure_time': departureTime,
      'driver_name': driverName,
      'lat': lat,
      'lng': lng,
      'active': true,
    }).select('id').single();
    return res['id'] as String;
  }

  /// Actualiza la posición del viaje activo del conductor.
  Future<void> updatePosition({
    required String tripId,
    required double lat,
    required double lng,
    double? heading,
  }) async {
    try {
      await _client.from('driver_live_trips').update({
        'lat': lat,
        'lng': lng,
        if (heading != null) 'heading': heading,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', tripId);
    } catch (e) {
      AppLogger.warn(_logTag, 'updatePosition failed', e);
    }
  }

  /// Cierra el viaje activo del conductor actual. BORRA la fila (no solo
  /// marca inactivo) para que el stream Realtime emita el DELETE y el bus
  /// desaparezca del mapa al instante; si solo marcáramos active=false, el
  /// stream filtrado por active=true a veces no retiraba la fila → el bus
  /// "se quedaba pillado".
  Future<void> endTrip() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await _client.from('driver_live_trips').delete().eq('driver_id', uid);
    } catch (e) {
      AppLogger.warn(_logTag, 'endTrip failed', e);
      // Respaldo: al menos marcar inactivo.
      try {
        await _client.rpc('end_my_live_trip');
      } catch (_) {}
    }
  }

  /// Viaje activo del conductor actual (o null).
  Future<DriverLiveTrip?> myActiveTrip() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    try {
      final res = await _client
          .from('driver_live_trips')
          .select()
          .eq('driver_id', uid)
          .eq('active', true)
          .maybeSingle();
      return res == null ? null : DriverLiveTrip.fromJson(res);
    } catch (_) {
      return null;
    }
  }
}

final driverLiveRepositoryProvider = Provider<DriverLiveRepository>((ref) {
  return DriverLiveRepository(ref.watch(supabaseClientProvider));
});

/// Buses en vivo (todos los viajes activos), refrescados por Realtime. El mapa
/// los pinta moviéndose. Se descartan los "zombi": viajes que llevan más de 2
/// min sin actualizar su posición (un conductor que cerró la app sin terminar)
/// para que no queden buses parados en el mapa.
final liveBusesProvider = StreamProvider<List<DriverLiveTrip>>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client
      .from('driver_live_trips')
      .stream(primaryKey: ['id'])
      .eq('active', true)
      .map((rows) {
    final now = DateTime.now();
    return rows
        .map((r) => DriverLiveTrip.fromJson(r))
        .where((t) {
          final u = t.updatedAt;
          if (u == null) return true;
          return now.difference(u.toLocal()).inMinutes < 2;
        })
        .toList(growable: false);
  });
});
