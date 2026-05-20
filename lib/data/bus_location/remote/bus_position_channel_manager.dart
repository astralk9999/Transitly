import 'dart:async';
import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/bus_location.dart';

const _logTag = 'BusChannelMgr';

/// Gestiona suscripciones Realtime con multiplexación y reconexión
/// con backoff exponencial + jitter. Cada ruta abre una suscripción
/// filtrada por `route_id`, pero la reconexión se gestiona de forma
/// centralizada con backoff para no saturar el servidor.
class BusPositionChannelManager {
  BusPositionChannelManager(this._client);

  final SupabaseClient _client;
  final Map<String, _RouteSubscription> _subscriptions = {};
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  Stream<BusLocation?> watch(String routeId) {
    final controller = StreamController<BusLocation?>();

    _subscriptions[routeId] = _RouteSubscription(
      controller: controller,
      routeId: routeId,
    );

    _openChannel(routeId, controller);

    controller.onCancel = () {
      _subscriptions.remove(routeId)?.channel.unsubscribe();
    };

    return controller.stream;
  }

  void _openChannel(String routeId, StreamController<BusLocation?> controller) {
    final channel = _client
        .channel('bus-pos-$routeId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'bus_positions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'route_id',
            value: routeId,
          ),
          callback: (payload) {
            try {
              final loc = BusLocation(
                lat: _coordOf(payload.newRecord, 1),
                lng: _coordOf(payload.newRecord, 0),
                bearing:
                    (payload.newRecord['bearing'] as num?)?.toDouble(),
                recordedAt: DateTime.parse(
                    payload.newRecord['recorded_at'] as String),
                accuracy: null,
              );
              if (!controller.isClosed) controller.add(loc);
            } catch (e) {
              AppLogger.warn(_logTag, 'parse failed (route=$routeId)', e);
            }
          },
        )
        .subscribe((status, _) {
          if (status == RealtimeSubscribeStatus.closed &&
              !controller.isClosed) {
            AppLogger.warn(_logTag, 'channel closed (route=$routeId)');
            _scheduleReconnect(routeId, controller);
          }
        });

    _subscriptions[routeId]?.channel = channel;
    AppLogger.debug(_logTag, 'channel opened for $routeId');
  }

  void _scheduleReconnect(
      String routeId, StreamController<BusLocation?> controller) {
    if (controller.isClosed || !_subscriptions.containsKey(routeId)) return;

    final jitter = math.Random().nextInt(1000);
    final delay = math.min(
      (_reconnectAttempts + 1) * 2 * 1000 + jitter,
      30000,
    );
    _reconnectAttempts++;

    AppLogger.info(_logTag, 'reconnecting route=$routeId in ${delay}ms');

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delay), () {
      if (!controller.isClosed && _subscriptions.containsKey(routeId)) {
        _openChannel(routeId, controller);
        _reconnectAttempts = 0;
      }
    });
  }

  void dispose() {
    _reconnectTimer?.cancel();
    for (final sub in _subscriptions.values) {
      sub.channel.unsubscribe();
      sub.controller.close();
    }
    _subscriptions.clear();
    _reconnectAttempts = 0;
  }

  static double _coordOf(Map<String, dynamic> record, int index) {
    final geom = record['geom'] as Map<String, dynamic>?;
    final coords = (geom?['coordinates'] as List<dynamic>?) ?? const [];
    return coords.length > index ? (coords[index] as num).toDouble() : 0.0;
  }
}

class _RouteSubscription {
  _RouteSubscription({
    required this.controller,
    required this.routeId,
  });
  final StreamController<BusLocation?> controller;
  final String routeId;
  late RealtimeChannel channel;
}
