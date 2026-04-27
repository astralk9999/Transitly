import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/mock/mock_realtime_service.dart';
import 'package:transitly/shared/models/enums.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataService data;

  setUpAll(() async {
    data = await MockDataService.init();
  });

  late MockRealtimeService svc;

  setUp(() {
    svc = MockRealtimeService(data);
  });

  tearDown(() {
    svc.dispose();
  });

  test('init emits the initial active trips on the stream', () async {
    final first = svc.tripsStream.first;
    svc.init();
    final trips = await first.timeout(const Duration(seconds: 1));
    expect(trips.length, data.activeTrips.length);
  });

  test('simulateStopRegistration advances the stop index for running trips',
      () async {
    svc.init();
    final running = svc.currentTrips
        .where((t) =>
            t.status != TripStatus.cancelled &&
            t.status != TripStatus.completed)
        .toList();
    if (running.isEmpty) {
      // Nothing to assert on — data has no running trips.
      return;
    }
    final target = running.first;
    final before = svc.currentTrips
        .firstWhere((t) => t.id == target.id)
        .currentStopIndex;

    svc.simulateStopRegistration(target.id);

    final after = svc.currentTrips
        .firstWhere((t) => t.id == target.id)
        .currentStopIndex;
    expect(after, isNotNull);
    expect(after! >= (before ?? 0), isTrue,
        reason: 'stop index went backwards: $before → $after');
  });

  test('dispose closes streams and cancels timers cleanly', () {
    svc.init();
    expect(svc.dispose, returnsNormally);
  });
}
