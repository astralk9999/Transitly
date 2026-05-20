import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/active_trip_model.dart';
import '../../shared/models/enums.dart';
import 'mock_data_service.dart';

class MockRealtimeService {
  MockRealtimeService(this._mockData);

  final MockDataService _mockData;

  final _tripController = StreamController<List<ActiveTripModel>>.broadcast();
  final _clockController = StreamController<DateTime>.broadcast();

  Timer? _tripTimer;
  Timer? _clockTimer;
  int _tickCount = 0;
  bool _paused = false;

  // Internal state
  late List<ActiveTripModel> _currentTrips;
  final Map<String, int> _countdownMinutes = {};
  final Map<String, int> _currentStopIndices = {};
  final Map<String, int> _delayMinutes = {};

  Stream<List<ActiveTripModel>> get tripsStream => _tripController.stream;
  Stream<DateTime> get clockTick => _clockController.stream;
  List<ActiveTripModel> get currentTrips => _currentTrips;

  void init() {
    _currentTrips = List.from(_mockData.activeTrips);

    // Initialize internal tracking maps
    for (final trip in _currentTrips) {
      if (trip.status == TripStatus.cancelled) continue;
      _currentStopIndices[trip.id] = trip.currentStopIndex ?? 0;
      _delayMinutes[trip.id] = trip.delayMinutes;
      _countdownMinutes[trip.id] = 3; // start with 3 ticks to next stop
    }

    // Emit initial state
    _tripController.add(_currentTrips);

    // Trip updates every 15 seconds
    _tripTimer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());

    // Clock every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clockController.add(DateTime.now());
    });
  }

  void _tick() {
    _tickCount++;
    final updated = <ActiveTripModel>[];

    for (final trip in _currentTrips) {
      if (trip.status == TripStatus.cancelled ||
          trip.status == TripStatus.completed) {
        updated.add(trip);
        continue;
      }

      final routeStops =
          _mockData.routeStops[trip.routeId] ?? const [];
      final sortedStops = [...routeStops]
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      final totalStops = sortedStops.length;

      if (totalStops < 2) {
        updated.add(trip);
        continue;
      }

      var stopIdx = _currentStopIndices[trip.id] ?? 0;
      var countdown = _countdownMinutes[trip.id] ?? 3;
      var delay = _delayMinutes[trip.id] ?? 0;

      // Decrement countdown
      countdown--;

      // Advance stop if countdown reached 0
      if (countdown <= 0) {
        stopIdx++;
        countdown = 2 + (stopIdx % 3); // vary: 2-4 ticks per segment
      }

      // Check if completed
      if (stopIdx >= totalStops - 1) {
        stopIdx = totalStops - 1;
        updated.add(ActiveTripModel(
          id: trip.id,
          routeId: trip.routeId,
          driverId: trip.driverId,
          startedAt: trip.startedAt,
          currentLat: trip.currentLat,
          currentLng: trip.currentLng,
          currentBearing: trip.currentBearing,
          currentStopIndex: stopIdx,
          status: TripStatus.completed,
          delayMinutes: 0,
          capacity: trip.capacity,
          vehicleNumber: trip.vehicleNumber,
        ));
        _currentStopIndices[trip.id] = stopIdx;
        _countdownMinutes[trip.id] = 0;
        _delayMinutes[trip.id] = 0;
        continue;
      }

      // Delay reduction for delayed trips
      if (delay > 0 && _tickCount % 3 == 0) {
        delay--;
      }

      // Interpolate position along polyline
      final currentStopId = sortedStops[stopIdx].stopId;
      final nextStopId = sortedStops[stopIdx + 1].stopId;
      final currentStop = _mockData.getStopById(currentStopId);
      final nextStop = _mockData.getStopById(nextStopId);

      double lat = trip.currentLat ?? 0;
      double lng = trip.currentLng ?? 0;
      double bearing = trip.currentBearing ?? 0;

      if (currentStop != null && nextStop != null) {
        final maxCountdown = 2 + (stopIdx % 3);
        final progress = 1.0 - (countdown / maxCountdown);

        final polyCoords = _mockData.polylines[trip.routeId];
        if (polyCoords != null && polyCoords.length >= 2) {
          // Find polyline segment between current and next stop
          final startIdx = _closestPolylineIndex(
              polyCoords, currentStop.lat, currentStop.lng);
          final endIdx = _closestPolylineIndex(
              polyCoords, nextStop.lat, nextStop.lng);

          if (startIdx != endIdx) {
            final from = min(startIdx, endIdx);
            final to = max(startIdx, endIdx);
            final pos = _interpolateAlongPolyline(
                polyCoords, from, to, progress);
            lat = pos[0];
            lng = pos[1];
          } else {
            lat = currentStop.lat +
                (nextStop.lat - currentStop.lat) * progress;
            lng = currentStop.lng +
                (nextStop.lng - currentStop.lng) * progress;
          }
        } else {
          lat = currentStop.lat +
              (nextStop.lat - currentStop.lat) * progress;
          lng = currentStop.lng +
              (nextStop.lng - currentStop.lng) * progress;
        }
        bearing = _bearingDegrees(lat, lng, nextStop.lat, nextStop.lng);
      }

      // Update state
      _currentStopIndices[trip.id] = stopIdx;
      _countdownMinutes[trip.id] = countdown;
      _delayMinutes[trip.id] = delay;

      final status = delay > 0 ? TripStatus.delay : TripStatus.onTime;

      updated.add(ActiveTripModel(
        id: trip.id,
        routeId: trip.routeId,
        driverId: trip.driverId,
        startedAt: trip.startedAt,
        currentLat: lat,
        currentLng: lng,
        currentBearing: bearing,
        currentStopIndex: stopIdx,
        status: status,
        delayMinutes: delay,
        capacity: trip.capacity,
        vehicleNumber: trip.vehicleNumber,
      ));
    }

    _currentTrips = updated;
    _tripController.add(_currentTrips);
  }

  void simulateStopRegistration(String tripId) {
    final idx = _currentStopIndices[tripId];
    if (idx == null) return;
    _countdownMinutes[tripId] = 0; // force advance on next tick
    _tick();
  }

  /// Find the polyline point index closest to the given lat/lng.
  int _closestPolylineIndex(
      List<List<double>> poly, double lat, double lng) {
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < poly.length; i++) {
      final dLat = poly[i][0] - lat;
      final dLng = poly[i][1] - lng;
      final d = dLat * dLat + dLng * dLng;
      if (d < bestDist) {
        bestDist = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  /// Interpolate along polyline points from [fromIdx] to [toIdx] by [t] (0-1).
  List<double> _interpolateAlongPolyline(
      List<List<double>> poly, int fromIdx, int toIdx, double t) {
    if (fromIdx == toIdx) return [poly[fromIdx][0], poly[fromIdx][1]];

    // Calculate cumulative distances between points
    var totalDist = 0.0;
    final segDists = <double>[];
    for (var i = fromIdx; i < toIdx; i++) {
      final dLat = poly[i + 1][0] - poly[i][0];
      final dLng = poly[i + 1][1] - poly[i][1];
      final d = sqrt(dLat * dLat + dLng * dLng);
      segDists.add(d);
      totalDist += d;
    }

    if (totalDist == 0) return [poly[fromIdx][0], poly[fromIdx][1]];

    // Find the target distance along the path
    final targetDist = t * totalDist;
    var accumulated = 0.0;

    for (var i = 0; i < segDists.length; i++) {
      if (accumulated + segDists[i] >= targetDist) {
        final segProgress =
            segDists[i] > 0 ? (targetDist - accumulated) / segDists[i] : 0.0;
        final idx = fromIdx + i;
        return [
          poly[idx][0] + (poly[idx + 1][0] - poly[idx][0]) * segProgress,
          poly[idx][1] + (poly[idx + 1][1] - poly[idx][1]) * segProgress,
        ];
      }
      accumulated += segDists[i];
    }

    return [poly[toIdx][0], poly[toIdx][1]];
  }

  double _bearingDegrees(
      double lat1, double lng1, double lat2, double lng2) {
    final dLng = (lng2 - lng1) * pi / 180;
    final lat1Rad = lat1 * pi / 180;
    final lat2Rad = lat2 * pi / 180;
    final x = sin(dLng) * cos(lat2Rad);
    final y =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLng);
    return (atan2(x, y) * 180 / pi + 360) % 360;
  }

  void pause() {
    if (_paused) return;
    _paused = true;
    _tripTimer?.cancel();
    _tripTimer = null;
    _clockTimer?.cancel();
    _clockTimer = null;
  }

  void resume() {
    if (!_paused) return;
    _paused = false;
    _tripTimer = Timer.periodic(const Duration(seconds: 15), (_) => _tick());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clockController.add(DateTime.now());
    });
  }

  void dispose() {
    _tripTimer?.cancel();
    _clockTimer?.cancel();
    _tripController.close();
    _clockController.close();
  }
}

// ── Providers ──

final mockRealtimeServiceProvider = Provider<MockRealtimeService>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);
  final service = MockRealtimeService(mockData);
  service.init();
  ref.onDispose(() => service.dispose());
  return service;
});

// autoDispose: suscripción se libera cuando ninguna pantalla observa.
// El servicio subyacente (mockRealtimeServiceProvider) sigue vivo
// porque otras partes lo pueden necesitar; el pause/resume por lifecycle
// (P3-5) sigue rigiendo la actividad del Timer.
final realtimeTripsProvider =
    StreamProvider.autoDispose<List<ActiveTripModel>>((ref) {
  final service = ref.watch(mockRealtimeServiceProvider);
  return service.tripsStream;
});

final realtimeClockProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final service = ref.watch(mockRealtimeServiceProvider);
  return service.clockTick;
});
