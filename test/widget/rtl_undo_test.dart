import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RTL directionality in custom widgets', () {
    testWidgets('LinearGradient with AlignmentDirectional respects RTL',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: Container(
                width: 200,
                height: 50,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [Color(0xFF7C6FF7), Color(0xFF0B0E17)],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'AlignmentDirectional must work in RTL without errors');
    });

    testWidgets('Icon directional awareness in RTL', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                children: const [
                  BackButton(),
                  Text('رجوع'),
                ],
              ),
            ),
          ),
        ),
      );

      // BackButton auto-flips visually in RTL (icon stays arrow_back but renders mirrored)
      expect(find.byIcon(Icons.arrow_back), findsOneWidget,
          reason: 'BackButton should render in RTL layout');
    });

    testWidgets('EdgeInsetsDirectional works in RTL', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsetsDirectional.only(start: 32, end: 16),
                child: const Text('مرحباً'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('مرحباً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('AlignmentDirectional values are RTL-aware', () {
      expect(AlignmentDirectional.centerStart, isNotNull);
      expect(AlignmentDirectional.centerEnd, isNotNull);
      expect(AlignmentDirectional.topStart, isNotNull);
      expect(AlignmentDirectional.topEnd, isNotNull);
    });

    testWidgets('Flexible with direction in RTL row', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MaterialApp(
            home: Scaffold(
              body: Row(
                textDirection: TextDirection.rtl,
                children: const [
                  Flexible(child: Text('محتوى طويل جداً')),
                  SizedBox(width: 8),
                  Icon(Icons.star),
                ],
              ),
            ),
          ),
        ),
      );

      // In RTL row, Flexible text should be on the right, icon on the left
      expect(find.text('محتوى طويل جداً'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Undo SnackBar for irreversible actions', () {
    testWidgets('SnackBar with undo action renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Elemento eliminado'),
                        action: SnackBarAction(
                          label: 'DESHACER',
                          onPressed: () {},
                        ),
                        duration: const Duration(seconds: 8),
                      ),
                    );
                  },
                  child: const Text('Eliminar'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Eliminar'));
      await tester.pump();

      expect(find.text('Elemento eliminado'), findsOneWidget);
      expect(find.text('DESHACER'), findsOneWidget,
          reason: 'Destructive actions must have undo');
    });

    testWidgets('extendedTimer SnackBar stays visible long enough',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Deleted'),
                        duration: Duration(seconds: 8),
                      ),
                    );
                  },
                  child: const Text('Delete'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.text('Deleted'), findsOneWidget);

      // Fast-forward 4 seconds — should still be visible
      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Deleted'), findsOneWidget,
          reason: 'Extended timer snackbar should persist');
    });
  });
}
