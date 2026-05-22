import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';
import 'package:transitly/shared/widgets/shimmer_skeleton.dart';
import '../helpers/pump_app.dart';

void main() {
  group('ShimmerSkeleton', () {
    testWidgets('renders list skeleton', (tester) async {
      await pumpApp(tester, child: Builder(
        builder: (context) => ShimmerSkeleton.list(
          context: context,
          count: 3,
          builder: () => const SizedBox(height: 60),
        ),
      ));
      await tester.pump();
      expect(find.byType(SizedBox), findsNWidgets(3));
      await unmount(tester);
    });
    testWidgets('renders route card skeleton', (tester) async {
      await pumpApp(tester, child: Builder(
        builder: (context) => ShimmerSkeleton.routeCard(context),
      ));
      await tester.pump();
      expect(find.byType(Shimmer), findsOneWidget);
      await unmount(tester);
    });
  });
}
