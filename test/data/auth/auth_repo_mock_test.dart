import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('AuthRepository enums and exceptions', () {
    test('AuthError has all 8 error types', () {
      expect(AuthError.values.length, 8);
      expect(AuthError.values, contains(AuthError.invalidCredentials));
      expect(AuthError.values, contains(AuthError.emailTaken));
      expect(AuthError.values, contains(AuthError.weakPassword));
      expect(AuthError.values, contains(AuthError.networkUnavailable));
      expect(AuthError.values, contains(AuthError.providerCancelled));
      expect(AuthError.values, contains(AuthError.emailNotVerified));
      expect(AuthError.values, contains(AuthError.unknown));
    });

    test('AuthRepoException stores error and optional message', () {
      const ex = AuthRepoException(AuthError.emailTaken, 'Already registered');
      expect(ex.error, AuthError.emailTaken);
      expect(ex.message, 'Already registered');
    });

    test('AuthSessionState sealed subtypes exist', () {
      expect(AuthInitial(), isA<AuthSessionState>());
      expect(AuthLoading(), isA<AuthSessionState>());
      expect(AuthUnauthenticated(), isA<AuthSessionState>());
    });
  });
}
