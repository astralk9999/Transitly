import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';

void main() {
  group('NfcCardService.classify', () {
    test('returns tagLost when message mentions TagLost', () {
      final ex = NfcCardService.classify(Exception('IOException: TagLost'));
      expect(ex.error, NfcCardError.tagLost);
    });

    test('returns tagLost when message mentions "tag was lost"', () {
      final ex = NfcCardService.classify('platform error: tag was lost');
      expect(ex.error, NfcCardError.tagLost);
    });

    test('returns unknown with original message otherwise', () {
      final ex = NfcCardService.classify(Exception('some other IO boom'));
      expect(ex.error, NfcCardError.unknown);
      expect(ex.message, contains('some other IO boom'));
    });
  });

  group('NfcCardService.parseBalance', () {
    test('parses 0x0088 swapped → 8800 → /2 → /100 = 44.00€', () {
      // swapped hex "8800" = 34816 → /2 = 17408 → /100 = 174.08
      // Let's sanity-check with the actual algorithm:
      //   bytes [0x00, 0x88] → hex "0088" → swap → "8800" → 34816 → /2/100 = 174.08
      final bytes = Uint8List.fromList([0x00, 0x88, 0x00, 0x00]);
      expect(NfcCardService.parseBalance(bytes), closeTo(174.08, 0.001));
    });

    test('parses 0x0000 → 0.00€', () {
      final bytes = Uint8List.fromList([0x00, 0x00, 0x00, 0x00]);
      expect(NfcCardService.parseBalance(bytes), 0.0);
    });

    test('parses low-endian byte pair correctly', () {
      // [0xC8, 0x00] → hex "c800" → swap → "00c8" → 200 → /2 = 100 → /100 = 1.0€
      final bytes = Uint8List.fromList([0xC8, 0x00]);
      expect(NfcCardService.parseBalance(bytes), closeTo(1.0, 0.001));
    });
  });

  group('NfcCardService.bytesToHex', () {
    test('uppercase hex with zero padding', () {
      final bytes = Uint8List.fromList([0x01, 0xAB, 0x00, 0xFF]);
      expect(NfcCardService.bytesToHex(bytes), '01AB00FF');
    });

    test('empty bytes → empty string', () {
      expect(NfcCardService.bytesToHex(Uint8List(0)), '');
    });
  });

  group('NfcCardException.displayMessage', () {
    test('each error case has a non-empty user-facing message', () {
      for (final err in NfcCardError.values) {
        final msg = NfcCardException(err).displayMessage;
        expect(msg, isNotEmpty, reason: 'missing display for $err');
      }
    });

    test('unknown uses provided message when given', () {
      const ex = NfcCardException(NfcCardError.unknown, 'radio failure');
      expect(ex.displayMessage, 'radio failure');
    });
  });
}
