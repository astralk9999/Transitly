import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show GoTrueClient, SupabaseClient;

import 'package:transitly/data/auth/auth_helpers.dart';
import 'package:transitly/data/auth/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
  });

  group('mapAuthError', () {
    test('maps invalid login credentials', () {
      final ex = mapAuthError(Exception('Invalid login credentials'));
      expect(ex.error, AuthError.invalidCredentials);
    });

    test('maps email already registered', () {
      final ex = mapAuthError(Exception('User already been registered'));
      expect(ex.error, AuthError.emailTaken);
    });

    test('maps weak password', () {
      final ex = mapAuthError(
        Exception('password should be at least 6 characters'),
      );
      expect(ex.error, AuthError.weakPassword);
    });
  });
}
