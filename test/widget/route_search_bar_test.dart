import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/models/stop_model.dart';
import 'package:transitly/shared/widgets/route_search_bar.dart';

import '../helpers/pump_app.dart';

StopModel _makeStop(String name, String code) => StopModel(
      id: code,
      name: name,
      officialCode: code,
      lat: 40.0,
      lng: -3.0,
      municipality: 'Test',
    );

void main() {
  group('RouteSearchBar', () {
    testWidgets('renders two text fields and a search button', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: RouteSearchBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('BUSCAR RUTA'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('filters suggestions when typing 2+ characters', (tester) async {
      final stops = [
        _makeStop('Alcala de Henares', 'ACH'),
        _makeStop('Alcorcon', 'ALC'),
        _makeStop('Madrid Centro', 'MAD'),
      ];

      await pumpApp(
        tester,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: RouteSearchBar(availableStops: stops),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fromField = find.byType(TextField).first;
      await tester.enterText(fromField, 'Alc');
      await tester.pumpAndSettle();

      expect(find.text('Alcala de Henares'), findsOneWidget);
      expect(find.text('Alcorcon'), findsOneWidget);
      expect(find.text('Madrid Centro'), findsNothing);
      await unmount(tester);
    });

    testWidgets('selecting a suggestion fills the text field', (tester) async {
      final stops = [
        _makeStop('Sol', 'SOL'),
        _makeStop('Atocha', 'ATO'),
      ];

      await pumpApp(
        tester,
        child: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              child: RouteSearchBar(availableStops: stops),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fromField = find.byType(TextField).first;
      await tester.enterText(fromField, 'Sol');
      await tester.pumpAndSettle();

      expect(find.text('Sol'), findsWidgets);
      await tester.tap(find.text('Sol').last);
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(fromField);
      expect(field.controller!.text, 'Sol');
      await unmount(tester);
    });
  });
}
