import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/user_preferences.dart';
import '../../sync/pending_action.dart';
import '../../sync/pending_actions_queue.dart';
import '../domain/user_preferences_repository.dart';

class UserPreferencesRemoteRepository implements UserPreferencesRepository {
  UserPreferencesRemoteRepository({
    required SupabaseClient client,
    required PendingActionsQueue queue,
  })  : _client = client,
        _queue = queue;

  final SupabaseClient _client;
  final PendingActionsQueue _queue;

  static const _logTag = 'Repo:UserPreferences:Remote';

  @override
  Future<UserPreferences> getMine() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw const UserPreferencesRepositoryException(
        error: UserPreferencesRepositoryError.denied,
        message: 'No authenticated user',
      );
    }

    try {
      final row = await _client
          .from('user_preferences')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (row == null) return UserPreferences(userId: uid);
      return _fromRow(row);
    } catch (e, st) {
      throw _mapError(e, st, 'getMine');
    }
  }

  @override
  Future<UserPreferences> update(UserPreferences prefs) async {
    final payload = _toDbRow(prefs);

    try {
      await _client.from('user_preferences').upsert(payload);
      return prefs;
    } on PostgrestException catch (e, st) {
      throw _mapError(e, st, 'update');
    } catch (e) {
      AppLogger.warn(_logTag, 'update network failed; enqueueing', e);
      await _queue.enqueue(
        PendingAction(
          id: 'prefs-${prefs.userId}',
          kind: PendingActionKind.updateUserPrefs,
          payload: payload,
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return prefs;
    }
  }

  UserPreferences _fromRow(Map<String, dynamic> row) {
    return UserPreferences(
      userId: row['user_id'] as String,
      themePaletteId: row['theme_palette_id'] as String? ?? 'default',
      customColors: row['custom_colors'] != null
          ? Map<String, String>.from(row['custom_colors'] as Map)
          : null,
      backgroundId: row['background_id'] as String? ?? 'smoke',
      backgroundEnabled: row['background_enabled'] as bool? ?? true,
      backgroundOpacity: (row['background_opacity'] as num?)?.toDouble() ?? 1.0,
      fontScale: (row['font_scale'] as num?)?.toDouble() ?? 1.0,
      colorBlindMode: _parseColorBlindMode(row['color_blind_mode'] as String?),
      dyslexiaFontEnabled: row['dyslexia_font_enabled'] as bool? ?? false,
      reduceMotion: row['reduce_motion'] as bool? ?? false,
    );
  }

  Map<String, dynamic> _toDbRow(UserPreferences p) {
    return <String, dynamic>{
      'user_id': p.userId,
      'theme_palette_id': p.themePaletteId,
      if (p.customColors != null) 'custom_colors': p.customColors,
      'background_id': p.backgroundId,
      'background_enabled': p.backgroundEnabled,
      'background_opacity': p.backgroundOpacity,
      'font_scale': p.fontScale,
      'color_blind_mode': p.colorBlindMode.name,
      'dyslexia_font_enabled': p.dyslexiaFontEnabled,
      'reduce_motion': p.reduceMotion,
    };
  }

  ColorBlindMode _parseColorBlindMode(String? value) {
    if (value == null) return ColorBlindMode.none;
    return ColorBlindMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ColorBlindMode.none,
    );
  }

  UserPreferencesRepositoryException _mapError(
    Object e,
    StackTrace st,
    String op,
  ) {
    AppLogger.warn(_logTag, '$op failed', e);
    if (e is PostgrestException) {
      final code = e.code;
      if (code == 'PGRST116') {
        return UserPreferencesRepositoryException(
          error: UserPreferencesRepositoryError.notFound,
          message: 'User preferences not found',
          cause: e,
          stackTrace: st,
        );
      }
      if (code == '42501') {
        return UserPreferencesRepositoryException(
          error: UserPreferencesRepositoryError.denied,
          message: 'Access denied by RLS',
          cause: e,
          stackTrace: st,
        );
      }
      return UserPreferencesRepositoryException(
        error: UserPreferencesRepositoryError.unknown,
        message: 'Postgrest error: ${e.message}',
        cause: e,
        stackTrace: st,
      );
    }
    return UserPreferencesRepositoryException(
      error: UserPreferencesRepositoryError.network,
      message: 'Network or unknown error in $op',
      cause: e,
      stackTrace: st,
    );
  }
}
