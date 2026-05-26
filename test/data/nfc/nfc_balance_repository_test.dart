import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:transitly/data/nfc/nfc_balance_repository.dart';
import 'package:transitly/data/nfc/nfc_card_service.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockUser extends Mock implements User {}

class FakePostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {
  final Future<PostgrestList> _future;
  FakePostgrestFilterBuilder(this._future);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList) onValue, {
    Function? onError,
  }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future<PostgrestList> catchError(
    Function onError, {
    bool Function(Object)? test,
  }) {
    return _future.catchError(onError, test: test);
  }
}

NfcCardResult _scan(int secondsAgo) => NfcCardResult(
      cardId: 'CARD001',
      balance: 12.50,
      scannedAt: DateTime.now().subtract(Duration(seconds: secondsAgo)),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    Hive.init('test/.hive_test_nfc_balance');
    registerFallbackValue(MockSupabaseQueryBuilder());
    registerFallbackValue(
        FakePostgrestFilterBuilder(Future.value(PostgrestList.from([]))));
  });

  Future<Box<Map<dynamic, dynamic>>> freshBox() async {
    final box =
        await Hive.openBox<Map<dynamic, dynamic>>('nfc_scans_test_${DateTime.now().microsecondsSinceEpoch}');
    await box.clear();
    return box;
  }

  group('saveScan', () {
    test('saves to Hive always, even without Supabase user', () async {
      final box = await freshBox();
      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final repo = NfcBalanceRepository(supabase, box);
      await repo.saveScan(_scan(0));

      expect(box.length, 1);
      final saved = box.get(box.keys.first);
      expect(saved?['cardId'], 'CARD001');
      expect(saved?['balance'], 12.50);
      expect(saved?['synced'], false);

      await box.close();
    });

    test('saves to Hive and marks synced when Supabase insert succeeds',
        () async {
      final box = await freshBox();
      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      final user = MockUser();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.id).thenReturn('user-123');

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => supabase.from('nfc_scans'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) =>
              FakePostgrestFilterBuilder(Future.value(PostgrestList.from([]))));

      final repo = NfcBalanceRepository(supabase, box);
      await repo.saveScan(_scan(0));

      expect(box.length, 1);
      final saved = box.get(box.keys.first);
      expect(saved?['synced'], true);

      await box.close();
    });

    test('saves to Hive with synced=false when Supabase insert fails',
        () async {
      final box = await freshBox();
      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      final user = MockUser();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.id).thenReturn('user-123');

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => supabase.from('nfc_scans'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenThrow(Exception('network error'));

      final repo = NfcBalanceRepository(supabase, box);
      await repo.saveScan(_scan(0));

      expect(box.length, 1);
      final saved = box.get(box.keys.first);
      expect(saved?['synced'], false);

      await box.close();
    });
  });

  group('getHistory', () {
    test('returns scans sorted by scannedAt descending, max 10', () async {
      final box = await freshBox();

      for (int i = 0; i < 12; i++) {
        final key = 'CARD001_${1000 + i}';
        await box.put(key, <String, dynamic>{
          'cardId': 'CARD001',
          'balance': 10.0 + i,
          'scannedAt': DateTime(2026, 5, 26, 10, i).toIso8601String(),
          'synced': true,
        });
      }

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final repo = NfcBalanceRepository(supabase, box);
      final history = repo.getHistory();

      expect(history.length, 10);
      expect(history.first.balance, 21.0);
      expect(history.last.balance, 12.0);
      expect(history.first.scannedAt.isAfter(history.last.scannedAt), true);

      await box.close();
    });

    test('reads entries correctly from box', () async {
      final box = await freshBox();
      await box.put('CARD001_1000', <String, dynamic>{
        'cardId': 'A_TEST_CARD',
        'balance': 7.50,
        'scannedAt': DateTime(2026, 5, 26, 10, 0).toIso8601String(),
        'synced': true,
      });

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(null);

      final repo = NfcBalanceRepository(supabase, box);
      final history = repo.getHistory();

      expect(history.length, 1);
      expect(history.first.cardId, 'A_TEST_CARD');
      expect(history.first.balance, 7.50);

      await box.close();
    });
  });

  group('syncPending', () {
    test('syncs unsynced entries and updates flag on success', () async {
      final box = await freshBox();
      final key1 = 'CARD001_1000';
      final key2 = 'CARD002_2000';

      await box.put(key1, <String, dynamic>{
        'cardId': 'CARD001',
        'balance': 10.0,
        'scannedAt': DateTime(2026, 5, 26, 10, 0).toIso8601String(),
        'synced': false,
      });
      await box.put(key2, <String, dynamic>{
        'cardId': 'CARD002',
        'balance': 20.0,
        'scannedAt': DateTime(2026, 5, 26, 11, 0).toIso8601String(),
        'synced': false,
      });

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      final user = MockUser();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.id).thenReturn('user-123');

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => supabase.from('nfc_scans'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) =>
              FakePostgrestFilterBuilder(Future.value(PostgrestList.from([]))));

      final repo = NfcBalanceRepository(supabase, box);
      await repo.syncPending();

      expect(box.get(key1)?['synced'], true);
      expect(box.get(key2)?['synced'], true);

      await box.close();
    });

    test('does not re-sync already synced entries', () async {
      final box = await freshBox();

      await box.put('CARD001_1000', <String, dynamic>{
        'cardId': 'CARD001',
        'balance': 10.0,
        'scannedAt': DateTime(2026, 5, 26, 10, 0).toIso8601String(),
        'synced': false,
      });
      await box.put('CARD002_2000', <String, dynamic>{
        'cardId': 'CARD002',
        'balance': 20.0,
        'scannedAt': DateTime(2026, 5, 26, 11, 0).toIso8601String(),
        'synced': true,
      });

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      final user = MockUser();

      when(() => supabase.auth).thenReturn(auth);
      when(() => auth.currentUser).thenReturn(user);
      when(() => user.id).thenReturn('user-123');

      final mockQueryBuilder = MockSupabaseQueryBuilder();
      when(() => supabase.from('nfc_scans'))
          .thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any()))
          .thenAnswer((_) =>
              FakePostgrestFilterBuilder(Future.value(PostgrestList.from([]))));

      final repo = NfcBalanceRepository(supabase, box);
      await repo.syncPending();

      verify(() => mockQueryBuilder.insert(any())).called(1);

      await box.close();
    });
  });

  group('pendingCount', () {
    test('returns count of unsynced entries', () async {
      final box = await freshBox();
      await box.put('A', <String, dynamic>{
        'cardId': 'A',
        'balance': 1.0,
        'scannedAt': '2026-05-26T10:00:00.000',
        'synced': false,
      });
      await box.put('B', <String, dynamic>{
        'cardId': 'B',
        'balance': 2.0,
        'scannedAt': '2026-05-26T11:00:00.000',
        'synced': true,
      });
      await box.put('C', <String, dynamic>{
        'cardId': 'C',
        'balance': 3.0,
        'scannedAt': '2026-05-26T12:00:00.000',
        'synced': false,
      });

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => supabase.auth).thenReturn(auth);

      final repo = NfcBalanceRepository(supabase, box);
      expect(repo.pendingCount, 2);

      await box.close();
    });

    test('returns 0 when all synced', () async {
      final box = await freshBox();
      await box.put('A', <String, dynamic>{
        'cardId': 'A',
        'balance': 1.0,
        'scannedAt': '2026-05-26T10:00:00.000',
        'synced': true,
      });

      final supabase = MockSupabaseClient();
      final auth = MockGoTrueClient();
      when(() => supabase.auth).thenReturn(auth);

      final repo = NfcBalanceRepository(supabase, box);
      expect(repo.pendingCount, 0);

      await box.close();
    });
  });
}
