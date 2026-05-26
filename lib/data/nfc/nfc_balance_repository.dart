import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';
import 'nfc_card_service.dart';

class NfcBalanceRepository {
  NfcBalanceRepository(this._supabase, this._hive);

  final SupabaseClient _supabase;
  final Box<Map<dynamic, dynamic>> _hive;

  static const _logTag = 'NfcBalanceRepo';
  static const _maxHistory = 10;

  String _key(NfcCardResult scan) =>
      '${scan.cardId}_${scan.scannedAt.millisecondsSinceEpoch}';

  Future<void> saveScan(NfcCardResult scan) async {
    final key = _key(scan);
    final entry = <String, dynamic>{
      'cardId': scan.cardId,
      'balance': scan.balance,
      'scannedAt': scan.scannedAt.toIso8601String(),
      'synced': false,
    };
    await _hive.put(key, entry);

    await _trySyncEntry(key, scan);
  }

  Future<bool> _trySyncEntry(String key, NfcCardResult scan) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      await _supabase.from('nfc_scans').insert({
        'user_id': userId,
        'card_id': scan.cardId,
        'balance': scan.balance,
        'scanned_at': scan.scannedAt.toIso8601String(),
      });

      final entry = _hive.get(key);
      if (entry is Map) {
        entry['synced'] = true;
        await _hive.put(key, entry);
      }
      AppLogger.info(_logTag, 'synced to Supabase: $key');
      return true;
    } catch (e) {
      AppLogger.warn(_logTag, 'sync failed for $key', e);
      return false;
    }
  }

  Future<void> syncPending() async {
    final unsyncedKeys = <String>[];
    for (final key in _hive.keys) {
      if (key is! String) continue;
      final entry = _hive.get(key);
      if (entry is Map && entry['synced'] == false) {
        unsyncedKeys.add(key);
      }
    }

    if (unsyncedKeys.isEmpty) return;

    AppLogger.info(_logTag, 'syncing ${unsyncedKeys.length} pending entries');

    for (final key in unsyncedKeys) {
      final entry = _hive.get(key);
      if (entry is! Map) continue;
      final scan = _decodeEntry(key, entry);
      await _trySyncEntry(key, scan);
    }
  }

  List<NfcCardResult> getHistory() {
    final results = <NfcCardResult>[];
    for (final key in _hive.keys) {
      if (key is! String) continue;
      final entry = _hive.get(key);
      if (entry is Map) {
        results.add(_decodeEntry(key, entry));
      }
    }
    results.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    return results.take(_maxHistory).toList();
  }

  int get pendingCount {
    int count = 0;
    for (final key in _hive.keys) {
      final entry = _hive.get(key);
      if (entry is Map && entry['synced'] == false) count++;
    }
    return count;
  }

  NfcCardResult _decodeEntry(String key, Map<dynamic, dynamic> entry) {
    return NfcCardResult(
      cardId: entry['cardId'] as String,
      balance: (entry['balance'] as num).toDouble(),
      scannedAt: DateTime.parse(entry['scannedAt'] as String),
    );
  }
}

final nfcBalanceRepositoryProvider = Provider<NfcBalanceRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final box = ref.watch(nfcScansBoxProvider);
  return NfcBalanceRepository(supabase, box);
});
