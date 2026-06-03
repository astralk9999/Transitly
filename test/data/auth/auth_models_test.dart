import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('AuthSessionState sealed class', () {
    test('AuthInitial is AuthSessionState', () {
      expect(AuthInitial(), isA<AuthSessionState>());
    });

    test('AuthLoading is AuthSessionState', () {
      expect(AuthLoading(), isA<AuthSessionState>());
    });

    test('AuthUnauthenticated is AuthSessionState', () {
      expect(AuthUnauthenticated(), isA<AuthSessionState>());
    });
  });

  group('AuthError enum', () {
    test('AuthError has 8 values', () {
      expect(AuthError.values.length, 8);
    });

    test('AuthRepoException stores error and message', () {
      const ex = AuthRepoException(AuthError.networkUnavailable, 'No network');
      expect(ex.error, AuthError.networkUnavailable);
      expect(ex.message, 'No network');
    });

    test('AuthRepoException toString includes error name', () {
      const ex = AuthRepoException(AuthError.invalidCredentials);
      expect(ex.toString(), contains('invalidCredentials'));
    });
  });
}
