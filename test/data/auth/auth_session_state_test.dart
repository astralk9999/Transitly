import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('AuthSessionState sealed hierarchy', () {
    test('AuthInitial, AuthLoading, AuthUnauthenticated are distinct', () {
      final states = <AuthSessionState>[
        AuthInitial(),
        AuthLoading(),
        AuthUnauthenticated(),
      ];
      expect(states[0], isA<AuthInitial>());
      expect(states[1], isA<AuthLoading>());
      expect(states[2], isA<AuthUnauthenticated>());
      expect(states[0], isNot(equals(states[1])));
      expect(states[1], isNot(equals(states[2])));
    });

    test('AuthError enum has 8 values', () {
      expect(AuthError.values.length, 8);
      expect(AuthError.values, contains(AuthError.invalidCredentials));
      expect(AuthError.values, contains(AuthError.emailTaken));
      expect(AuthError.values, contains(AuthError.weakPassword));
      expect(AuthError.values, contains(AuthError.networkUnavailable));
      expect(AuthError.values, contains(AuthError.providerCancelled));
      expect(AuthError.values, contains(AuthError.emailNotVerified));
      expect(AuthError.values, contains(AuthError.unknown));
    });

    test('AuthRepoException stores error and message', () {
      final exc = const AuthRepoException(
        AuthError.emailTaken,
        'This email is already in use',
      );
      expect(exc.error, AuthError.emailTaken);
      expect(exc.message, 'This email is already in use');
      expect(exc.toString(), contains('emailTaken'));
      expect(exc.toString(), contains('This email is already in use'));
    });
  });
}
