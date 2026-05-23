import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/widgets/reputation_badge.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ReputationBadge edge', () {
    testWidgets('score=0 renders level badge not rank badge', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(ReputationLevel.expert, score: 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('EXPERTO'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      await unmount(tester);
    });

    testWidgets('score=100 renders rank icon visible', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(
          ReputationLevel.contributor,
          score: 100,
        ),
      );
      await tester.pumpAndSettle();
      // ReputationRank.forScore(100) → contributor → Icons.star_half
      expect(find.byIcon(Icons.star_half), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('score=0 with trusted level shows level label', (tester) async {
      await pumpApp(
        tester,
        child: const ReputationBadge(ReputationLevel.trusted, score: 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('DE CONFIANZA'), findsOneWidget);
      await unmount(tester);
    });
  });
}
