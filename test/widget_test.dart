import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:transitly/app.dart';

void main() {
  testWidgets('App renders TRANSITLY text', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: TransitlyApp()),
    );
    expect(find.text('TRANSITLY'), findsOneWidget);
  });
}
