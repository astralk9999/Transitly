import 'package:latlong2/latlong.dart';

/// Value object inmutable que representa una parada marcada durante una
/// grabación en vivo: posición geográfica, offset desde el inicio de la
/// grabación y, opcionalmente, un nombre asignado por el conductor.
class RecordedStop {
  const RecordedStop({
    this.name,
    required this.position,
    required this.arrivalOffset,
  });

  final String? name;
  final LatLng position;
  final Duration arrivalOffset;

  RecordedStop copyWith({String? name}) => RecordedStop(
        name: name ?? this.name,
        position: position,
        arrivalOffset: arrivalOffset,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'lat': position.latitude,
        'lng': position.longitude,
        'arrivalOffsetSeconds': arrivalOffset.inSeconds,
      };

  factory RecordedStop.fromJson(Map<String, dynamic> j) => RecordedStop(
        name: j['name'] as String?,
        position: LatLng(
          (j['lat'] as num).toDouble(),
          (j['lng'] as num).toDouble(),
        ),
        arrivalOffset:
            Duration(seconds: (j['arrivalOffsetSeconds'] as num).toInt()),
      );
}

/// Snapshot completo de una grabación en vivo: el track GPS completo y
/// las paradas marcadas. Sirve como contrato entre `LiveRecorderController`
/// y `PostRecordingEditor`, y como formato de borrador en disco.
class RecordedSession {
  const RecordedSession({
    required this.trace,
    required this.stops,
  });

  final List<LatLng> trace;
  final List<RecordedStop> stops;

  bool get isEmpty => trace.isEmpty;
  bool get isNotEmpty => trace.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'trace': trace
            .map((p) => <double>[p.latitude, p.longitude])
            .toList(),
        'stops': stops.map((s) => s.toJson()).toList(),
      };

  factory RecordedSession.fromJson(Map<String, dynamic> j) => RecordedSession(
        trace: (j['trace'] as List<dynamic>).map((p) {
          final pp = p as List<dynamic>;
          return LatLng(
            (pp[0] as num).toDouble(),
            (pp[1] as num).toDouble(),
          );
        }).toList(),
        stops: (j['stops'] as List<dynamic>)
            .map((s) => RecordedStop.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}
