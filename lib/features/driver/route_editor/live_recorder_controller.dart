import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../data/geo/location_service.dart';
import 'recorded_session.dart';

class MarkedStop {
  const MarkedStop({
    required this.number,
    required this.position,
    required this.distanceKm,
    required this.markedAt,
  });

  final int number;
  final LatLng position;
  final double distanceKm;
  final Duration markedAt;
}

/// Predefined GPS path based on L1 stops with intermediates.
/// Fallback para tests y demo cuando no hay GPS disponible.
const List<LatLng> gpsSimulatedPath = <LatLng>[
  LatLng(36.6819, -6.1365),
  LatLng(36.6826, -6.1357),
  LatLng(36.6834, -6.1349),
  LatLng(36.6831, -6.1352),
  LatLng(36.6828, -6.1355),
  LatLng(36.6821, -6.1347),
  LatLng(36.6815, -6.1340),
  LatLng(36.6807, -6.1330),
  LatLng(36.6800, -6.1320),
  LatLng(36.6793, -6.1303),
  LatLng(36.6786, -6.1287),
  LatLng(36.6773, -6.1313),
  LatLng(36.6760, -6.1340),
  LatLng(36.6740, -6.1350),
  LatLng(36.6720, -6.1360),
  LatLng(36.6710, -6.1365),
  LatLng(36.6700, -6.1370),
  LatLng(36.6690, -6.1360),
  LatLng(36.6680, -6.1350),
  LatLng(36.6685, -6.1340),
  LatLng(36.6690, -6.1330),
  LatLng(36.6695, -6.1320),
  LatLng(36.6700, -6.1310),
];

/// Ephemeral state holder for the live recording flow.
///
/// Supports two modes:
/// - **Real GPS** via [LocationService.subscribe] (default, F11).
/// - **Simulated path** via [gpsSimulatedPath] timer (fallback/demo).
class LiveRecorderController extends ChangeNotifier {
  LiveRecorderController({
    this.path = gpsSimulatedPath,
    LocationService? locationService,
  }) : _locationService = locationService;

  final List<LatLng> path;
  final LocationService? _locationService;

  final MapController mapController = MapController();

  bool isRecording = false;
  bool isPaused = false;
  final List<LatLng> trace = [];
  final List<LatLng> lowAccuracyTrace = [];
  final List<MarkedStop> markedStops = [];
  int gpsIndex = 0;
  int elapsedSeconds = 0;
  double totalDistanceKm = 0;
  bool flashVisible = false;
  bool blinkOn = true;

  /// Precisión GPS actual en metros. Null si no disponible (simulado).
  double? currentAccuracyM;
  bool get isRealGps => _locationService != null;

  Timer? _gpsTimer;
  Timer? _clockTimer;
  Timer? _blinkTimer;
  StreamSubscription<Position>? _gpsSub;

  /// Callback fired whenever a stop is marked. Use to show snackbars or
  /// haptic feedback — the controller stays view-agnostic.
  void Function(MarkedStop stop)? onStopMarked;

  Future<void> start() async {
    if (isRecording) return;
    isRecording = true;
    notifyListeners();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds++;
      notifyListeners();
    });

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      blinkOn = !blinkOn;
      notifyListeners();
    });

    if (_locationService != null) {
      await _startRealGps();
    } else {
      _startSimulatedGps();
    }
  }

  Future<void> _startRealGps() async {
    try {
      final positionStream = _locationService!.subscribe(
        settings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      _gpsSub = positionStream.listen(
        (pos) {
          if (!isRecording || isPaused) return;

          final point = LatLng(pos.latitude, pos.longitude);
          final accuracyM = pos.accuracy;

          currentAccuracyM = accuracyM;

          // Ignorar posiciones con precisión muy mala (> 100m).
          if (accuracyM > 100) return;

          if (accuracyM > 50) {
            // Baja precisión: guardar en traza separada (color amarillo).
            lowAccuracyTrace.add(point);
          }

          // Only add to trace if accuracy is acceptable (< 50m).
          if (accuracyM <= 50) {
            if (trace.isNotEmpty) {
              totalDistanceKm += _distKm(trace.last, point);
            }
            trace.add(point);
          }

          mapController.move(point, 15);
          notifyListeners();
        },
        onError: (e) {
          AppLogger.warn('LiveRecorder', 'GPS stream error', e);
        },
      );
    } on LocationServiceException catch (e) {
      AppLogger.warn('LiveRecorder', 'GPS permission error, falling back to simulated', e);
      _startSimulatedGps();
    }
  }

  void _startSimulatedGps() {
    _gpsTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!isRecording || isPaused) return;
      if (gpsIndex >= path.length) return;
      final point = path[gpsIndex];
      if (trace.isNotEmpty) {
        totalDistanceKm += _distKm(trace.last, point);
      }
      trace.add(point);
      gpsIndex++;
      currentAccuracyM = 5.0;
      mapController.move(point, 15);
      notifyListeners();
    });
  }

  void pause() {
    if (!isRecording || isPaused) return;
    isPaused = true;
    notifyListeners();
  }

  void resume() {
    if (!isRecording || !isPaused) return;
    isPaused = false;
    notifyListeners();
  }

  void markStop() {
    if (trace.isEmpty) return;
    final pos = trace.last;
    final n = markedStops.length + 1;
    final distFromLast = markedStops.isNotEmpty
        ? _distKm(markedStops.last.position, pos)
        : totalDistanceKm;

    final stop = MarkedStop(
      number: n,
      position: pos,
      distanceKm: distFromLast,
      markedAt: Duration(seconds: elapsedSeconds),
    );
    markedStops.add(stop);
    flashVisible = true;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      flashVisible = false;
      notifyListeners();
    });

    onStopMarked?.call(stop);
  }

  void stop() {
    _gpsTimer?.cancel();
    _gpsSub?.cancel();
    _clockTimer?.cancel();
    _blinkTimer?.cancel();
    _gpsTimer = null;
    _gpsSub = null;
    _clockTimer = null;
    _blinkTimer = null;
    isRecording = false;
    isPaused = false;
    notifyListeners();
  }

  /// Snapshot inmutable del estado actual de la grabación.
  RecordedSession getCurrentSession() => RecordedSession(
        trace: List<LatLng>.unmodifiable(trace),
        stops: markedStops
            .map((m) => RecordedStop(
                  position: m.position,
                  arrivalOffset: m.markedAt,
                ))
            .toList(growable: false),
      );

  @override
  void dispose() {
    stop();
    mapController.dispose();
    super.dispose();
  }

  double distanceFromLastMarkedKm() {
    if (markedStops.isEmpty || trace.isEmpty) return 0.0;
    return _distKm(markedStops.last.position, trace.last);
  }

  double speedKmh() {
    if (elapsedSeconds == 0) return 0;
    return totalDistanceKm / elapsedSeconds * 3600;
  }

  /// Haversine great-circle distance in km.
  static double _distKm(LatLng a, LatLng b) {
    const r = 6371.0;
    final dLat = (b.latitude - a.latitude) * pi / 180;
    final dLng = (b.longitude - a.longitude) * pi / 180;
    final lat1 = a.latitude * pi / 180;
    final lat2 = b.latitude * pi / 180;
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * r * asin(sqrt(h));
  }
}
