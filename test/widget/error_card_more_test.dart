import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/widgets/error_card.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ErrorCard edge', () {
    testWidgets('onRetry fires exactly once per tap', (tester) async {
      var count = 0;
      await pumpApp(
        tester,
        child: ErrorCard('Fail', onRetry: () => count++),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('REINTENTAR'));
      expect(count, 1);
      await tester.tap(find.text('REINTENTAR'));
      expect(count, 2);
      await unmount(tester);
    });

    testWidgets('very long message does not crash', (tester) async {
      final long = 'ERR' * 80;
      await pumpApp(tester, child: ErrorCard(long));
      await tester.pumpAndSettle();
      expect(find.textContaining('ERR'), findsOneWidget);
      await unmount(tester);
    });
  });
}
