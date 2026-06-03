import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('AuthError enum', () {
    test('has exactly 8 error types', () {
      expect(AuthError.values.length, 8);
    });

    test('contains all expected error kinds', () {
      expect(AuthError.values, contains(AuthError.invalidCredentials));
      expect(AuthError.values, contains(AuthError.emailTaken));
      expect(AuthError.values, contains(AuthError.weakPassword));
      expect(AuthError.values, contains(AuthError.networkUnavailable));
      expect(AuthError.values, contains(AuthError.providerCancelled));
      expect(AuthError.values, contains(AuthError.emailNotVerified));
      expect(AuthError.values, contains(AuthError.unknown));
    });

    test('AuthRepoException stores error and message', () {
      const ex = AuthRepoException(
        AuthError.invalidCredentials,
        'Invalid credentials',
      );
      expect(ex.error, AuthError.invalidCredentials);
      expect(ex.message, 'Invalid credentials');
      expect(ex.toString(), contains('invalidCredentials'));
    });
  });
}
