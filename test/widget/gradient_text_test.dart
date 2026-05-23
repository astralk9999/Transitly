import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/gradient_text.dart';
import '../helpers/pump_app.dart';

void main() {
  group('GradientText', () {
    testWidgets('renders text content', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: GradientText(
            'Hello World',
            style: TextStyle(fontSize: 16),
            gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hello World'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('wraps text in ShaderMask for gradient fill', (tester) async {
      await pumpApp(
        tester,
        child: const Scaffold(
          body: GradientText(
            'Gradient',
            style: TextStyle(fontSize: 20),
            gradient: LinearGradient(colors: [Colors.red, Colors.orange]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ShaderMask), findsOneWidget);
      await unmount(tester);
    });
  });
}
