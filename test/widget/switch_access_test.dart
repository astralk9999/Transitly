import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Switch Access Dismissible', () {
    testWidgets('Dismissible with confirmDismiss works with switch access',
        (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Dismissible(
                  key: const Key('item-1'),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    dismissed = true;
                    return true;
                  },
                  background: Container(color: Colors.red),
                  child: const ListTile(
                    title: Text('Swipe to delete'),
                    subtitle: Text('Or use switch access'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify semantics label is descriptive
      final semantics = tester.getSemantics(find.text('Swipe to delete'));
      expect(semantics.label, isNotEmpty,
          reason: 'Dismissible items must have descriptive semantics');

      // Dismiss via swipe
      await tester.fling(
        find.text('Swipe to delete'),
        const Offset(-200, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(dismissed, isTrue,
          reason: 'Dismissible must respond to gesture for Switch Access users');
    });

    testWidgets(
        'Dismissible provides alternative action via button for switch access',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                Dismissible(
                  key: const Key('item-2'),
                  direction: DismissDirection.horizontal,
                  confirmDismiss: (_) async => false,
                  background: Container(color: Colors.orange),
                  secondaryBackground: Container(color: Colors.red),
                  child: ListTile(
                    title: const Text('Item with actions'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit item',
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          tooltip: 'Delete item',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Verify both swipe and button actions are available
      expect(find.byIcon(Icons.edit), findsOneWidget,
          reason: 'Edit button must be available for Switch Access');
      expect(find.byIcon(Icons.delete), findsOneWidget,
          reason: 'Delete button must be available for Switch Access');

      // Verify tooltip provides descriptive semantics
      final editBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.edit),
          matching: find.byType(IconButton),
        ),
      );
      expect(editBtn.tooltip, 'Edit item');

      final deleteBtn = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.delete),
          matching: find.byType(IconButton),
        ),
      );
      expect(deleteBtn.tooltip, 'Delete item');
    });
  });
}
