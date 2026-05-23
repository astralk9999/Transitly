import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('AuthRepository edge cases', () {
    test('AuthEmailVerificationPending is AuthSessionState subtype', () {
      expect(AuthEmailVerificationPending, isA<Type>());
      expect(AuthEmailVerificationPending, isNot(equals(AuthUnauthenticated)));
    });

    test('AuthRepoException toString with null message', () {
      const ex = AuthRepoException(AuthError.unknown);
      final str = ex.toString();
      expect(str, contains('unknown'));
    });

    test('AuthRepoException.toString with message includes both', () {
      const ex = AuthRepoException(AuthError.emailTaken, 'already in use');
      final str = ex.toString();
      expect(str, contains('emailTaken'));
      expect(str, contains('already in use'));
    });
  });
}
