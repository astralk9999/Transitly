import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/models/stop_model.dart';
import 'package:transitly/shared/widgets/stop_list_item.dart';
import '../helpers/pump_app.dart';

void main() {
  group('StopListItem', () {
    testWidgets('renders stop name', (tester) async {
      await pumpApp(
        tester,
        child: const StopListItem(
          stop: StopModel(
            id: 'parada-1',
            name: 'Pza. Redonda',
            officialCode: 'P001',
            lat: 36.5,
            lng: -6.2,
            municipality: 'Cádiz',
          ),
          scheduledTime: '10:30',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pza. Redonda'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders scheduled time', (tester) async {
      await pumpApp(
        tester,
        child: const StopListItem(
          stop: StopModel(
            id: 'parada-2',
            name: 'Av. Principal',
            officialCode: 'P002',
            lat: 36.6,
            lng: -6.3,
            municipality: '',
          ),
          scheduledTime: '14:15',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('14:15'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders current stop with accent circle', (tester) async {
      await pumpApp(
        tester,
        child: const StopListItem(
          stop: StopModel(
            id: 'parada-3',
            name: 'Estación',
            officialCode: 'P003',
            lat: 36.7,
            lng: -6.4,
            municipality: 'Cádiz',
          ),
          scheduledTime: '12:00',
          isCurrent: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Estación'), findsOneWidget);
      await unmount(tester);
    });
  });
}
