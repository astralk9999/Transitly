import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/mock/mock_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDataService svc;

  setUpAll(() async {
    svc = await MockDataService.init();
  });

  group('MockDataService basic checks', () {
    test('operator is not null', () {
      expect(svc.operator_.id, isNotEmpty);
    });

    test('routes is not empty', () {
      expect(svc.routes, isNotEmpty);
    });

    test('stops is not empty', () {
      expect(svc.stops, isNotEmpty);
    });

    test('schedules for L1 exist', () {
      final l1 = svc.getRouteById('L1');
      expect(l1, isNotNull, reason: 'L1 route not found');
      final schedules = svc.getSchedulesForRoute(l1!.id);
      expect(schedules, isNotEmpty, reason: 'No schedules found for L1');
    });
  });
}
