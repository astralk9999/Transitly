import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/widgets/user_avatar.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(body: Center(child: child)),
      );

  testWidgets('UserAvatar shows two-letter initials for full name',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Itziar Uruburu', accent: Colors.purple),
    ));
    expect(find.text('IU'), findsOneWidget);
  });

  testWidgets('UserAvatar shows single initial for one-word name',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Itziar', accent: Colors.purple),
    ));
    expect(find.text('I'), findsOneWidget);
  });

  testWidgets('UserAvatar shows ? for empty name', (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: '', accent: Colors.purple),
    ));
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('UserAvatar falls back to initials when photoUrl is null',
      (tester) async {
    await tester.pumpWidget(wrap(
      const UserAvatar(name: 'Test User', accent: Colors.purple),
    ));
    expect(find.byType(Image), findsNothing);
    expect(find.text('TU'), findsOneWidget);
  });
}
