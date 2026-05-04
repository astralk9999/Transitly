import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:transitly/features/driver/route_editor/live_recorder_controller.dart';
import 'package:transitly/features/driver/route_editor/recorded_session.dart';

void main() {
  group('RecordedStop / RecordedSession', () {
    test('toJson/fromJson roundtrip preserva todos los campos', () {
      final session = RecordedSession(
        trace: const [
          LatLng(36.6819, -6.1365),
          LatLng(36.6820, -6.1360),
        ],
        stops: const [
          RecordedStop(
            position: LatLng(36.6819, -6.1365),
            arrivalOffset: Duration(seconds: 0),
          ),
          RecordedStop(
            name: 'Plaza Esteve',
            position: LatLng(36.6820, -6.1360),
            arrivalOffset: Duration(seconds: 42),
          ),
        ],
      );

      final encoded = session.toJson();
      final decoded = RecordedSession.fromJson(encoded);

      expect(decoded.trace.length, 2);
      expect(decoded.trace[0].latitude, closeTo(36.6819, 1e-9));
      expect(decoded.trace[1].longitude, closeTo(-6.1360, 1e-9));
      expect(decoded.stops.length, 2);
      expect(decoded.stops[0].name, isNull);
      expect(decoded.stops[0].arrivalOffset, Duration.zero);
      expect(decoded.stops[1].name, 'Plaza Esteve');
      expect(decoded.stops[1].arrivalOffset, const Duration(seconds: 42));
    });

    test('isEmpty / isNotEmpty', () {
      const empty = RecordedSession(trace: [], stops: []);
      const filled = RecordedSession(
        trace: [LatLng(0, 0)],
        stops: [],
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.isNotEmpty, isFalse);
      expect(filled.isNotEmpty, isTrue);
    });

    test('copyWith muta solo el name', () {
      const original = RecordedStop(
        position: LatLng(36.6, -6.1),
        arrivalOffset: Duration(seconds: 10),
      );
      final renamed = original.copyWith(name: 'Esteve');
      expect(renamed.name, 'Esteve');
      expect(renamed.position, original.position);
      expect(renamed.arrivalOffset, original.arrivalOffset);
    });
  });

  group('LiveRecorderController.getCurrentSession', () {
    test('controller vacío → sesión sin trace ni stops', () {
      final c = LiveRecorderController();
      addTearDown(c.dispose);

      final session = c.getCurrentSession();
      expect(session.trace, isEmpty);
      expect(session.stops, isEmpty);
    });

    test('mapea markedStops a RecordedStop con arrivalOffset', () {
      final c = LiveRecorderController();
      addTearDown(c.dispose);

      // Inyectamos estado directamente: el controller expone los campos
      // públicos para evitar drives indirectos vía timers.
      c.trace
        ..add(const LatLng(36.6819, -6.1365))
        ..add(const LatLng(36.6820, -6.1360));
      c.markedStops.add(const MarkedStop(
        number: 1,
        position: LatLng(36.6819, -6.1365),
        distanceKm: 0,
        markedAt: Duration(seconds: 0),
      ));
      c.markedStops.add(const MarkedStop(
        number: 2,
        position: LatLng(36.6820, -6.1360),
        distanceKm: 0.05,
        markedAt: Duration(seconds: 17),
      ));

      final session = c.getCurrentSession();
      expect(session.trace.length, 2);
      expect(session.stops.length, 2);
      expect(session.stops[0].arrivalOffset, Duration.zero);
      expect(
          session.stops[1].arrivalOffset, const Duration(seconds: 17));
      expect(session.stops[1].position.latitude, closeTo(36.6820, 1e-9));
    });

    test('la sesión es inmutable: añadir al controller no muta la session',
        () {
      final c = LiveRecorderController();
      addTearDown(c.dispose);

      c.trace.add(const LatLng(0, 0));
      final session = c.getCurrentSession();
      c.trace.add(const LatLng(1, 1));

      // session.trace fue creado con List.unmodifiable: no refleja el cambio.
      expect(session.trace.length, 1);
    });
  });
}
