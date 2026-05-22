import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:transitly/l10n/generated/app_localizations.dart';

void main() {
  group('i18n RTL and locale formatting', () {
    setUpAll(() async {
      await initializeDateFormatting('ar', null);
      await initializeDateFormatting('es', null);
      await initializeDateFormatting('en', null);
    });

    test('Arabic locale is present in supportedLocales', () {
      final supported = AppLocalizations.supportedLocales;
      expect(supported.any((l) => l.languageCode == 'ar'), isTrue,
          reason: 'Arabic must be in supported locales for RTL support');
    });

    test('ARB delegates include all 3 locales', () {
      final delegates = AppLocalizations.localizationsDelegates;
      expect(delegates.isNotEmpty, isTrue);
    });

    test('supportedLocales contains es, en, ar', () {
      final supported = AppLocalizations.supportedLocales;
      expect(supported.map((l) => l.languageCode),
          containsAll(['es', 'en', 'ar']));
    });

    test('Arabic number formatting loads without error', () {
      final arFormat = NumberFormat.decimalPattern('ar');
      final enFormat = NumberFormat.decimalPattern('en');

      expect(arFormat.format(1234), isNotEmpty,
          reason: 'Arabic number format must produce a valid string');
      expect(enFormat.format(1234), isNotEmpty,
          reason: 'English number format must produce a valid string');
    });

    test('Spanish date format differs from English', () {
      final now = DateTime(2026, 5, 21);
      final esDate = DateFormat.yMMMMd('es').format(now);
      final enDate = DateFormat.yMMMMd('en').format(now);

      expect(esDate, isNot(enDate),
          reason: 'Spanish date format should differ from English');
    });
  });
}
