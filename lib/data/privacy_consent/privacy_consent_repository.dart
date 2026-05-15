import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_logger.dart';

class PrivacyConsentRepository {
  PrivacyConsentRepository(this._client);

  final SupabaseClient _client;

  static const _logTag = 'PrivacyConsent';

  Future<Map<String, bool>> getConsents(String userId) async {
    try {
      final response = await _client
          .from('privacy_consents')
          .select()
          .eq('user_id', userId);

      final result = <String, bool>{};
      for (final row in response) {
        final kind = row['consent_kind'] as String;
        final granted = row['granted'] as bool;
        result[kind] = granted;
      }

      AppLogger.info(
          _logTag, 'consents loaded for $userId (${result.length} rows)');
      return result;
    } catch (e) {
      AppLogger.warn(_logTag, 'getConsents failed for $userId', e);
      return {};
    }
  }

  Future<void> setConsent(String userId, String kind, bool granted) async {
    try {
      final existing = await _client
          .from('privacy_consents')
          .select('id')
          .eq('user_id', userId)
          .eq('consent_kind', kind)
          .maybeSingle();

      final now = DateTime.now().toUtc().toIso8601String();

      if (existing != null) {
        await _client.from('privacy_consents').update({
          'granted': granted,
          if (granted) 'granted_at': now else 'revoked_at': now,
        }).eq('id', existing['id'] as String);
      } else {
        await _client.from('privacy_consents').insert({
          'user_id': userId,
          'consent_kind': kind,
          'granted': granted,
          if (granted) 'granted_at': now,
          'policy_version': '1.0',
        });
      }

      AppLogger.info(_logTag, 'setConsent $kind=$granted for $userId');
    } catch (e, st) {
      AppLogger.error(
          _logTag, 'setConsent failed $kind=$granted for $userId', e, st);
      rethrow;
    }
  }
}
