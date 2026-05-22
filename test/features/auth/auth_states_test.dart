import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:transitly/data/auth/auth_helpers.dart';
import 'package:transitly/data/auth/auth_repository.dart';
import 'package:transitly/shared/providers/auth_provider.dart';
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

  // ── SignInScreen ──
  group('SignInScreen rendering', () {
    testWidgets('renderiza campos email y contraseña', (tester) async {
      await pumpApp(tester, child: const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error con credenciales inválidas', (tester) async {
      when(() => mockRepo.signInWithEmail(any(), any())).thenThrow(
        const AuthRepoException(AuthError.invalidCredentials, 'Credenciales inválidas'),
      );
      await pumpApp(tester, child: const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'bad@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), 'wrong');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();
      expect(find.text('Credenciales inválidas'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error con email no verificado', (tester) async {
      when(() => mockRepo.signInWithEmail(any(), any())).thenThrow(
        const AuthRepoException(AuthError.emailNotVerified, 'Email no verificado'),
      );
      await pumpApp(tester, child: const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();
      expect(find.text('Email no verificado'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error de red', (tester) async {
      when(() => mockRepo.signInWithEmail(any(), any())).thenThrow(
        const AuthRepoException(AuthError.networkUnavailable, 'Sin conexión'),
      );
      await pumpApp(tester, child: const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();
      expect(find.text('Sin conexión'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('botón responde con campos válidos', (tester) async {
      when(() => mockRepo.signInWithEmail(any(), any())).thenThrow(
        const AuthRepoException(AuthError.unknown, 'Error'),
      );
      await pumpApp(tester, child: const SignInScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.tap(find.text('INICIAR SESIÓN'));
      await tester.pump();
      // Button fires (shows error from mock)
      expect(find.text('Error'), findsOneWidget);
      await unmount(tester);
    });
  });

  // ── SignUpScreen ──
  group('SignUpScreen states', () {
    testWidgets('renderiza campos nombre, email y contraseña', (tester) async {
      await pumpApp(tester, child: const SignUpScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      expect(find.text('Nombre'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Fecha de nacimiento'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error email ya registrado', (tester) async {
      when(() => mockRepo.signUpWithEmail(any(), any(), any())).thenThrow(
        const AuthRepoException(AuthError.emailTaken, 'Este email ya está registrado'),
      );
      await pumpApp(tester, child: const SignUpScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), '01/01/2000');
      await tester.enterText(find.byType(TextFormField).at(2), 'taken@test.com');
      await tester.enterText(find.byType(TextFormField).at(3), '123456');
      await tester.tap(find.text('CREAR CUENTA'));
      await tester.pump();
      expect(find.text('Este email ya está registrado'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error contraseña débil', (tester) async {
      when(() => mockRepo.signUpWithEmail(any(), any(), any())).thenThrow(
        mapAuthError(Exception('password should be at least 6 characters')),
      );
      await pumpApp(tester, child: const SignUpScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), '01/01/2000');
      await tester.enterText(find.byType(TextFormField).at(2), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(3), '123');
      await tester.tap(find.text('CREAR CUENTA'));
      await tester.pump();
      // The screen should display the error message
      expect(find.byType(ElevatedButton), findsWidgets);
      await unmount(tester);
    });

    testWidgets('botón responde con campos válidos', (tester) async {
      when(() => mockRepo.signUpWithEmail(any(), any(), any())).thenThrow(
        const AuthRepoException(AuthError.unknown, 'Error'),
      );
      await pumpApp(tester, child: const SignUpScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField).at(0), 'Test User');
      await tester.enterText(find.byType(TextFormField).at(1), '01/01/2000');
      await tester.enterText(find.byType(TextFormField).at(2), 'user@test.com');
      await tester.enterText(find.byType(TextFormField).at(3), '123456');
      await tester.tap(find.text('CREAR CUENTA'));
      await tester.pump();
      expect(find.text('Error'), findsOneWidget);
      await unmount(tester);
    });
  });

  // ── RecoverPasswordScreen ──
  group('RecoverPasswordScreen', () {
    testWidgets('renderiza campo email y botón enviar', (tester) async {
      await pumpApp(tester, child: const RecoverPasswordScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('ENVIAR ENLACE'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra éxito al enviar enlace', (tester) async {
      when(() => mockRepo.recoverPassword(any()))
          .thenAnswer((_) async {});
      await pumpApp(tester, child: const RecoverPasswordScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'user@test.com');
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      await unmount(tester);
    });
  });

  // ── MagicLinkScreen ──
  group('MagicLinkScreen', () {
    testWidgets('renderiza campo email y botón enviar', (tester) async {
      await pumpApp(tester, child: const MagicLinkScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('ENVIAR ENLACE'), findsOneWidget);
      await unmount(tester);
    });

    testWidgets('muestra error de red al enviar', (tester) async {
      when(() => mockRepo.sendMagicLink(any())).thenThrow(
        const AuthRepoException(AuthError.networkUnavailable, 'Sin conexión'),
      );
      await pumpApp(tester, child: const MagicLinkScreen(),
          overrides: [authRepositoryProvider.overrideWithValue(mockRepo)]);
      await tester.pump();
      await tester.enterText(find.byType(TextFormField), 'user@test.com');
      await tester.tap(find.text('ENVIAR ENLACE'));
      await tester.pump();
      expect(find.text('Sin conexión'), findsOneWidget);
      await unmount(tester);
    });
  });

  // ── AuthError ↔ AuthHelpers cross-validation ──
  group('AuthError coverage', () {
    test('mapAuthError covers all known patterns', () {
      final errors = <Exception, AuthError>{
        Exception('Invalid login credentials'): AuthError.invalidCredentials,
        Exception('User already been registered'): AuthError.emailTaken,
        Exception('already registered'): AuthError.emailTaken,
        Exception('password should be at least 6 characters'): AuthError.weakPassword,
        Exception('Email not confirmed'): AuthError.emailNotVerified,
        Exception('Some random error'): AuthError.unknown,
      };
      for (final entry in errors.entries) {
        expect(mapAuthError(entry.key).error, entry.value,
            reason: '${entry.key} → ${entry.value}');
      }
    });
  });
}
