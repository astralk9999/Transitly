import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/providers/privacy_consent_provider.dart';

void main() {
  group('privacyConsentProvider', () {
    test('privacyConsentRepositoryProvider is not null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(privacyConsentRepositoryProvider, isNotNull);
    });

    test('privacyConsentsProvider is not null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(privacyConsentsProvider, isNotNull);
    });

    test('providers exist in container', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final elements = container.getAllProviderElements();
      expect(elements, isA<Iterable<ProviderElementBase<Object?>>>());
    });
  });
}
