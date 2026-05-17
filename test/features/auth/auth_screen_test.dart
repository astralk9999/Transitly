import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/auth/auth_repository.dart';
import 'package:transitly/features/auth/auth_provider.dart';
import 'package:transitly/features/auth/magic_link_screen.dart';
import 'package:transitly/features/auth/recover_password_screen.dart';
import 'package:transitly/features/auth/signin_screen.dart';
import 'package:transitly/features/auth/signup_screen.dart';

import '../../helpers/pump_app.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  group('SignInScreen', () {
    testWidgets('renderiza campos email y contraseña', (tester) async {
      await pumpApp(
        tester,
        child: const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('INICIAR SESIÓN'), findsOneWidget);

      await unmount(tester);
    });

    testWidgets('muestra error con email inválido', (tester) async {
      when(() => mockRepo.signInWithEmail(any(), any())).thenThrow(
        const AuthRepoException(
          AuthError.invalidCredentials,
          'Credenciales inválidas',
        ),
      );

      await pumpApp(
        tester,
        child: const SignInScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pump();

      await tester.enterText(find.byType(TextFormField).at(0), 'bad@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();

      expect(find.text('Credenciales inválidas'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('SignUpScreen', () {
    testWidgets('renderiza campos nombre, email y contraseña', (tester) async {
      await pumpApp(
        tester,
        child: const SignUpScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pump();

      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('CREAR CUENTA'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('RecoverPasswordScreen', () {
    testWidgets('renderiza campo email', (tester) async {
      await pumpApp(
        tester,
        child: const RecoverPasswordScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('ENVIAR ENLACE'), findsOneWidget);

      await unmount(tester);
    });
  });

  group('MagicLinkScreen', () {
    testWidgets('renderiza campo email y botón enviar', (tester) async {
      await pumpApp(
        tester,
        child: const MagicLinkScreen(),
        overrides: [
          authRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      await tester.pump();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('ENVIAR ENLACE'), findsOneWidget);

      await unmount(tester);
    });
  });
}
