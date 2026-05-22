import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/widgets/reputation_badge.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ReputationBadge', () {
    testWidgets('renders level label', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(ReputationLevel.trusted),
      );
      await tester.pumpAndSettle();
      expect(find.text('DE CONFIANZA'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders score', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(
          ReputationLevel.contributor,
          score: 75,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('75'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('renders new level label', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(ReputationLevel.new_),
      );
      await tester.pumpAndSettle();
      expect(find.text('NUEVO'), findsOneWidget);
      await unmount(tester);
    });
  });
}
