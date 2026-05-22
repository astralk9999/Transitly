import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/providers/locale_provider.dart';

void main() {
  group('localeProvider', () {
    test('default value is null (follow system)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final locale = container.read(localeProvider);
      expect(locale, isNull);
    });

    test('can set locale to Spanish', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).state = const Locale('es');
      expect(container.read(localeProvider), const Locale('es'));
    });

    test('can switch between locales', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider.notifier).state = const Locale('en');
      expect(container.read(localeProvider), const Locale('en'));

      container.read(localeProvider.notifier).state = const Locale('ar');
      expect(container.read(localeProvider), const Locale('ar'));

      container.read(localeProvider.notifier).state = null;
      expect(container.read(localeProvider), isNull);
    });
  });
}
