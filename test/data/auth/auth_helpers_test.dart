import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/auth/auth_helpers.dart';
import 'package:transitly/data/auth/auth_repository.dart';

void main() {
  group('mapAuthError', () {
    test('invalid credentials → AuthError.invalidCredentials', () {
      final result = mapAuthError(Exception('Invalid login credentials'));
      expect(result.error, AuthError.invalidCredentials);
    });

    test('invalid credentials (lowercase) → AuthError.invalidCredentials', () {
      final result = mapAuthError(Exception('invalid login credentials'));
      expect(result.error, AuthError.invalidCredentials);
    });

    test('email already registered → AuthError.emailTaken', () {
      final result =
          mapAuthError(Exception('User already been registered'));
      expect(result.error, AuthError.emailTaken);
    });

    test('already registered variant → AuthError.emailTaken', () {
      final result =
          mapAuthError(Exception('already registered'));
      expect(result.error, AuthError.emailTaken);
    });

    test('weak password → AuthError.weakPassword', () {
      final result = mapAuthError(
          Exception('password should be at least 6 characters'));
      expect(result.error, AuthError.weakPassword);
    });

    test('email not confirmed → AuthError.emailNotVerified', () {
      final result = mapAuthError(Exception('Email not confirmed'));
      expect(result.error, AuthError.emailNotVerified);
    });

    test('unknown error → AuthError.unknown with original message', () {
      final result = mapAuthError(Exception('Some random error'));
      expect(result.error, AuthError.unknown);
      expect(result.message, 'Exception: Some random error');
    });

    test('case-insensitive matching works', () {
      final result =
          mapAuthError(Exception('INVALID LOGIN CREDENTIALS'));
      expect(result.error, AuthError.invalidCredentials);
    });

    test('partial substring match works', () {
      final result = mapAuthError(
          Exception('Error: invalid login credentials for user@email.com'));
      expect(result.error, AuthError.invalidCredentials);
    });
  });

  group('AuthError enum', () {
    test('all 8 error cases are reachable', () {
      expect(AuthError.values.length, 8);
      expect(AuthError.values, contains(AuthError.invalidCredentials));
      expect(AuthError.values, contains(AuthError.emailTaken));
      expect(AuthError.values, contains(AuthError.weakPassword));
      expect(AuthError.values, contains(AuthError.networkUnavailable));
      expect(AuthError.values, contains(AuthError.providerCancelled));
      expect(AuthError.values, contains(AuthError.emailNotVerified));
      expect(AuthError.values, contains(AuthError.rateLimited));
      expect(AuthError.values, contains(AuthError.unknown));
    });
  });
}
