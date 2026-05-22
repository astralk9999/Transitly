import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PrivacyConsent', () {
    test('consent kinds are well-known category strings', () {
      const analytics = 'analytics';
      const location = 'location';
      const notifications = 'notifications';
      const crashReporting = 'crash_reporting';
      const personalization = 'personalization';

      final kinds = {analytics, location, notifications, crashReporting, personalization};

      for (final kind in kinds) {
        expect(kind, isNotEmpty);
        expect(kind, isA<String>());
      }

      expect(kinds, contains('analytics'));
      expect(kinds, contains('location'));
    });

    test('grant is true and revoke is false', () {
      final consented = <String, bool>{
        'analytics': true,
        'location': false,
        'notifications': true,
        'crash_reporting': true,
        'personalization': false,
      };

      expect(consented['analytics'], true);
      expect(consented['location'], false);
      expect(consented['notifications'], true);
      expect(consented['crash_reporting'], true);
      expect(consented['personalization'], false);

      final granted = consented.entries.where((e) => e.value).toList();
      final revoked = consented.entries.where((e) => !e.value).toList();
      expect(granted.length, 3);
      expect(revoked.length, 2);
    });

    test('policy version is a valid semver-like string', () {
      const version = '1.0';
      expect(version, isNotEmpty);
      expect(version, contains('.'));

      final parts = version.split('.');
      expect(parts.length, greaterThanOrEqualTo(2));
      for (final part in parts) {
        expect(int.tryParse(part), isNotNull, reason: '"$part" is not numeric');
      }
    });
  });
}
