import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/core/env.dart';

void main() {
  group('Env', () {
    test('required keys throw EnvException when missing', () {
      expect(
        () => Env.supabaseUrl,
        throwsA(isA<EnvException>()),
      );
      expect(
        () => Env.supabaseAnonKey,
        throwsA(isA<EnvException>()),
      );
    });

    test('optional keys return null when not set', () {
      expect(Env.postHogApiKey, isNull);
      expect(Env.sentryDsn, isNull);
      expect(Env.mapTilerApiKey, isNull);
    });

    test('optional keys with defaults return defaults when not set', () {
      expect(Env.postHogHost, 'https://eu.posthog.com');
      expect(Env.tosUrl, 'https://transitly.app/terms');
      expect(Env.privacyUrl, 'https://transitly.app/privacy');
    });
  });
}
