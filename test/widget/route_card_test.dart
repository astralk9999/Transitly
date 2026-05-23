import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_model.dart';
import 'package:transitly/shared/widgets/route_card.dart';
import '../helpers/pump_app.dart';

void main() {
  group('RouteCard', () {
    testWidgets('renders route code', (tester) async {
      await pumpApp(
        tester,
        child: const RouteCard(
          route: RouteModel(
            id: 'L1',
            operatorId: 'comujesa',
            code: 'L1',
            name: 'Plaza Redonda - Carretera',
            serviceType: ServiceType.urban,
            routeColor: Colors.blue,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('L1'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders route name', (tester) async {
      await pumpApp(
        tester,
        child: const RouteCard(
          route: RouteModel(
            id: 'M-123',
            operatorId: 'comujesa',
            code: 'M-123',
            name: 'Metropolitano Centro',
            serviceType: ServiceType.metropolitan,
            routeColor: Colors.green,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('METROPOLITANO CENTRO'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders with estimated minutes', (tester) async {
      await pumpApp(
        tester,
        child: const RouteCard(
          route: RouteModel(
            id: 'L2',
            operatorId: 'comujesa',
            code: 'L2',
            name: 'Plaza - Hospital',
            serviceType: ServiceType.urban,
            routeColor: Colors.red,
          ),
          estimatedMinutes: '5 min',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('5 min'), findsOneWidget);
      await unmount(tester);
    });
  });
}
