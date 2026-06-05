import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/nfc/nfc_balance_repository.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';

void main() {
  late Box<Map<dynamic, dynamic>> box;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_nfc_balance_test_');
    Hive.init(dir.path);
  });

  setUp(() async {
    final name = 'nfc_scans_test_${DateTime.now().microsecondsSinceEpoch}';
    box = await Hive.openBox<Map<dynamic, dynamic>>(name);
  });

  tearDown(() async {
    await box.close();
  });

  test('saveScan stores userId in entry; getHistory(userId) filters by it',
      () async {
    final repo = NfcBalanceRepository.forTest(box);

    final alice = NfcCardResult(
      cardId: 'CARD_A',
      balance: 5.0,
      scannedAt: DateTime(2026, 6, 1, 9),
    );
    final bob = NfcCardResult(
      cardId: 'CARD_B',
      balance: 12.5,
      scannedAt: DateTime(2026, 6, 2, 10),
    );

    await repo.saveScanForUser(alice, userId: 'alice');
    await repo.saveScanForUser(bob, userId: 'bob');

    final aliceHistory = repo.getHistory(userId: 'alice');
    expect(aliceHistory.length, 1);
    expect(aliceHistory.first.cardId, 'CARD_A');

    final bobHistory = repo.getHistory(userId: 'bob');
    expect(bobHistory.length, 1);
    expect(bobHistory.first.cardId, 'CARD_B');
  });

  test('getHistory() without userId returns scans from "guest" slot only',
      () async {
    final repo = NfcBalanceRepository.forTest(box);

    await repo.saveScanForUser(
      NfcCardResult(
        cardId: 'CARD_G',
        balance: 3.0,
        scannedAt: DateTime(2026, 6, 1),
      ),
      userId: null,
    );
    await repo.saveScanForUser(
      NfcCardResult(
        cardId: 'CARD_A',
        balance: 10.0,
        scannedAt: DateTime(2026, 6, 1),
      ),
      userId: 'alice',
    );

    final guest = repo.getHistory();
    expect(guest.length, 1);
    expect(guest.first.cardId, 'CARD_G');
  });

  test('legacy entries without userId are returned for guest view', () async {
    final key = 'LEGACY_CARD_${DateTime.now().millisecondsSinceEpoch}';
    await box.put(key, {
      'cardId': 'LEGACY_CARD',
      'balance': 7.5,
      'scannedAt': DateTime(2026, 5, 1).toIso8601String(),
      'synced': false,
    });

    final repo = NfcBalanceRepository.forTest(box);
    final guest = repo.getHistory();
    expect(guest.any((s) => s.cardId == 'LEGACY_CARD'), isTrue);
  });
}
