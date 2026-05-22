import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';
import 'package:transitly/data/nfc/nfc_l10n.dart';
import 'package:transitly/l10n/generated/app_localizations_es.dart';

void main() {
  group('NfcCardError', () {
    test('all expected error values exist', () {
      const expected = [
        NfcCardError.unsupported,
        NfcCardError.notMifareClassic,
        NfcCardError.authFailed,
        NfcCardError.readFailed,
        NfcCardError.tagLost,
        NfcCardError.unknown,
      ];

      expect(NfcCardError.values, orderedEquals(expected));
      expect(NfcCardError.values.length, 6);
    });

    test('NfcCardException stores error and optional message', () {
      const ex = NfcCardException(NfcCardError.readFailed);
      expect(ex.error, NfcCardError.readFailed);
      expect(ex.message, isNull);

      const exWithMsg = NfcCardException(NfcCardError.unknown, 'sector timeout');
      expect(exWithMsg.error, NfcCardError.unknown);
      expect(exWithMsg.message, 'sector timeout');
    });

    test('NfcCardErrorL10n maps every error to a non-empty string', () {
      final l10n = AppLocalizationsEs();

      for (final err in NfcCardError.values) {
        final msg = err.localizedMessage(l10n, fallback: 'fallback');
        expect(msg, isNotEmpty, reason: 'missing l10n for $err');
        expect(msg, isNot(contains('nfcError')), reason: 'untranslated key for $err');
      }
    });
  });
}
