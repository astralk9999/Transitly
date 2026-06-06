import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, SupabaseClient, User;

import '../../core/utils/app_logger.dart';
import '../../data/auth/auth_repository.dart';
import '../../data/supabase/supabase_client_provider.dart';
import 'auth_provider.dart';

// B2: Favoritos sincronizados entre dispositivos vía Supabase.
//
// Hive sigue siendo cache local + fallback offline. Si hay usuario
// autenticado, la BD es la fuente de verdad: al cargar mergeamos
// remoto + local (set union) y subimos los locales que aún no estén
// en remoto (preserva favoritos creados antes del login).
//
// Al añadir/quitar actualizamos state al instante (UI), Hive
// siempre, y Supabase si hay sesión. Errores de red no bloquean al
// usuario — quedan persistidos localmente y subirán en el siguiente
// merge.

const _boxName = 'userFavorites';
const _kindLine = 'line';
const _kindStop = 'stop';
const _logTag = 'Favorites';

class UserFavoritesNotifier extends StateNotifier<Set<String>> {
  UserFavoritesNotifier(this._readClient, this._readUser) : super(<String>{}) {
    _loadLocal();
  }

  final SupabaseClient Function() _readClient;
  final User? Function() _readUser;
  static const _hiveKey = 'lines';

  Future<void> _loadLocal() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    if (!mounted) return;
    final raw = box.get(_hiveKey, defaultValue: <String>[]) ?? <String>[];
    state = Set<String>.from(raw);
  }

  Future<void> syncWithRemote() async {
    final user = _readUser();
    if (user == null) return;
    final client = _readClient();
    try {
      final remote = await client
          .from('user_favorites')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('kind', _kindLine);
      final remoteIds = <String>{
        for (final r in remote) r['entity_id'] as String,
      };
      final localOnly = state.difference(remoteIds);
      final merged = {...state, ...remoteIds};
      if (!mounted) return;
      state = merged;
      await _persistLocal();
      if (localOnly.isNotEmpty) {
        await client.from('user_favorites').upsert(
              [
                for (final id in localOnly)
                  {'user_id': user.id, 'kind': _kindLine, 'entity_id': id},
              ],
              onConflict: 'user_id,kind,entity_id',
            );
      }
    } on PostgrestException catch (e) {
      AppLogger.warn(_logTag, 'sync lines failed: ${e.message}');
    } catch (e) {
      AppLogger.warn(_logTag, 'sync lines failed: $e');
    }
  }

  Future<void> addLine(String routeId) async {
    if (state.contains(routeId)) return;
    state = {...state, routeId};
    await _persistLocal();
    await _pushRemote(routeId, add: true);
  }

  Future<void> removeLine(String routeId) async {
    if (!state.contains(routeId)) return;
    state = {...state}..remove(routeId);
    await _persistLocal();
    await _pushRemote(routeId, add: false);
  }

  Future<void> _pushRemote(String routeId, {required bool add}) async {
    final user = _readUser();
    if (user == null) return;
    final client = _readClient();
    try {
      if (add) {
        await client.from('user_favorites').upsert(
          {'user_id': user.id, 'kind': _kindLine, 'entity_id': routeId},
          onConflict: 'user_id,kind,entity_id',
        );
      } else {
        await client
            .from('user_favorites')
            .delete()
            .match({'user_id': user.id, 'kind': _kindLine, 'entity_id': routeId});
      }
    } on PostgrestException catch (e) {
      AppLogger.warn(_logTag, 'push line failed: ${e.message}');
    } catch (e) {
      AppLogger.warn(_logTag, 'push line failed: $e');
    }
  }

  Future<void> _persistLocal() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    await box.put(_hiveKey, state.toList());
  }

  bool isFavorite(String routeId) => state.contains(routeId);
}

final userFavoritesProvider =
    StateNotifierProvider<UserFavoritesNotifier, Set<String>>((ref) {
  final notifier = UserFavoritesNotifier(
    () => ref.read(supabaseClientProvider),
    () => ref.read(currentAuthUserProvider),
  );
  // Resync solo cuando cambia el id del usuario (login/logout),
  // no en cada tokenRefreshed.
  // Listen a authStateProvider (reactivo vía StreamProvider), no a
  // currentAuthUserProvider — éste es síncrono y nunca cambia su
  // valor en runtime: si el provider de favoritos se crea ANTES del
  // login, currentAuthUserProvider sigue devolviendo null y el sync
  // jamás dispara. El bug era: tras borrar caché, abrir la app, hacer
  // login → los favoritos remotos solo aparecían tras reiniciar.
  String? lastUserId;
  ref.listen<AsyncValue<AuthSessionState>>(authStateProvider, (_, next) {
    final state = next.valueOrNull;
    final user = state is AuthAuthenticated ? state.user : null;
    final id = user?.id;
    if (id == lastUserId) return;
    lastUserId = id;
    if (id != null) notifier.syncWithRemote();
  }, fireImmediately: true);
  return notifier;
});

class UserFavoriteStopsNotifier extends StateNotifier<Set<String>> {
  UserFavoriteStopsNotifier(this._readClient, this._readUser)
      : super(<String>{}) {
    _loadLocal();
  }

  final SupabaseClient Function() _readClient;
  final User? Function() _readUser;
  static const _hiveKey = 'stops';

  Future<void> _loadLocal() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    if (!mounted) return;
    final raw = box.get(_hiveKey, defaultValue: <String>[]) ?? <String>[];
    state = Set<String>.from(raw);
  }

  Future<void> syncWithRemote() async {
    final user = _readUser();
    if (user == null) return;
    final client = _readClient();
    try {
      final remote = await client
          .from('user_favorites')
          .select('entity_id')
          .eq('user_id', user.id)
          .eq('kind', _kindStop);
      final remoteIds = <String>{
        for (final r in remote) r['entity_id'] as String,
      };
      final localOnly = state.difference(remoteIds);
      final merged = {...state, ...remoteIds};
      if (!mounted) return;
      state = merged;
      await _persistLocal();
      if (localOnly.isNotEmpty) {
        await client.from('user_favorites').upsert(
              [
                for (final id in localOnly)
                  {'user_id': user.id, 'kind': _kindStop, 'entity_id': id},
              ],
              onConflict: 'user_id,kind,entity_id',
            );
      }
    } on PostgrestException catch (e) {
      AppLogger.warn(_logTag, 'sync stops failed: ${e.message}');
    } catch (e) {
      AppLogger.warn(_logTag, 'sync stops failed: $e');
    }
  }

  Future<void> addStop(String stopId) async {
    if (state.contains(stopId)) return;
    state = {...state, stopId};
    await _persistLocal();
    await _pushRemote(stopId, add: true);
  }

  Future<void> removeStop(String stopId) async {
    if (!state.contains(stopId)) return;
    state = {...state}..remove(stopId);
    await _persistLocal();
    await _pushRemote(stopId, add: false);
  }

  Future<void> toggleStop(String stopId) async {
    if (state.contains(stopId)) {
      await removeStop(stopId);
    } else {
      await addStop(stopId);
    }
  }

  bool isStopFavorite(String stopId) => state.contains(stopId);

  Future<void> _pushRemote(String stopId, {required bool add}) async {
    final user = _readUser();
    if (user == null) return;
    final client = _readClient();
    try {
      if (add) {
        await client.from('user_favorites').upsert(
          {'user_id': user.id, 'kind': _kindStop, 'entity_id': stopId},
          onConflict: 'user_id,kind,entity_id',
        );
      } else {
        await client
            .from('user_favorites')
            .delete()
            .match({'user_id': user.id, 'kind': _kindStop, 'entity_id': stopId});
      }
    } on PostgrestException catch (e) {
      AppLogger.warn(_logTag, 'push stop failed: ${e.message}');
    } catch (e) {
      AppLogger.warn(_logTag, 'push stop failed: $e');
    }
  }

  Future<void> _persistLocal() async {
    final box = await Hive.openBox<List<dynamic>>(_boxName);
    await box.put(_hiveKey, state.toList());
  }
}

final userFavoriteStopsProvider =
    StateNotifierProvider<UserFavoriteStopsNotifier, Set<String>>((ref) {
  final notifier = UserFavoriteStopsNotifier(
    () => ref.read(supabaseClientProvider),
    () => ref.read(currentAuthUserProvider),
  );
  // Listen a authStateProvider (reactivo vía StreamProvider), no a
  // currentAuthUserProvider — éste es síncrono y nunca cambia su
  // valor en runtime: si el provider de favoritos se crea ANTES del
  // login, currentAuthUserProvider sigue devolviendo null y el sync
  // jamás dispara. El bug era: tras borrar caché, abrir la app, hacer
  // login → los favoritos remotos solo aparecían tras reiniciar.
  String? lastUserId;
  ref.listen<AsyncValue<AuthSessionState>>(authStateProvider, (_, next) {
    final state = next.valueOrNull;
    final user = state is AuthAuthenticated ? state.user : null;
    final id = user?.id;
    if (id == lastUserId) return;
    lastUserId = id;
    if (id != null) notifier.syncWithRemote();
  }, fireImmediately: true);
  return notifier;
});
