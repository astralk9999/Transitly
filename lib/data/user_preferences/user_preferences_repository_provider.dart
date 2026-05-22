import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import '../../shared/models/user_preferences.dart';
import '../cache/hive_box_provider.dart';
import '../supabase/supabase_client_provider.dart';
import '../sync/offline_sync_provider.dart';
import '../sync/pending_action.dart';
import 'domain/user_preferences_repository.dart';
import 'local/user_preferences_local_repository.dart';
import 'local/user_preferences_mock_repository.dart';
import 'remote/user_preferences_remote_repository.dart';

class UserPreferencesRepositorySwr implements UserPreferencesRepository {
  UserPreferencesRepositorySwr({required this.local, required this.remote});

  final UserPreferencesLocalRepository local;
  final UserPreferencesRemoteRepository remote;

  static const _logTag = 'Repo:UserPreferences';

  @override
  Future<UserPreferences> getMine() async {
    try {
      final cached = await local.getMine();
      unawaited(_refreshPrefs());
      return cached;
    } on UserPreferencesRepositoryException {
      final fresh = await remote.getMine();
      await local.update(fresh);
      return fresh;
    }
  }

  Future<void> _refreshPrefs() async {
    try {
      final fresh = await remote.getMine();
      await local.update(fresh);
    } on UserPreferencesRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background refresh getMine() failed', e);
    }
  }

  @override
  Future<UserPreferences> update(UserPreferences prefs) async {
    await local.update(prefs);
    unawaited(_pushUpdate(prefs));
    return prefs;
  }

  Future<void> _pushUpdate(UserPreferences prefs) async {
    try {
      await remote.update(prefs);
    } on UserPreferencesRepositoryException catch (e) {
      AppLogger.warn(_logTag, 'background push update() failed', e);
    }
  }
}

final userPreferencesRepositoryProvider =
    Provider.autoDispose<UserPreferencesRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return UserPreferencesMockRepository();
  }

  final queue = ref.watch(pendingActionsQueueProvider);
  final box = ref.watch(userPreferencesBoxProvider);
  final remote = UserPreferencesRemoteRepository(
    client: client,
    queue: queue,
  );

  final sync = ref.read(offlineSyncServiceProvider);
  sync.registerExecutor(
    PendingActionKind.updateUserPrefs,
    (payload) async {
      await client.from('user_preferences').upsert(payload);
    },
  );

  return UserPreferencesRepositorySwr(
    local: UserPreferencesLocalRepository(box),
    remote: remote,
  );
});
