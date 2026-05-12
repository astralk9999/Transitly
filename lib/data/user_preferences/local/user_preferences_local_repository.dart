import 'package:hive/hive.dart';

import '../../../shared/models/user_preferences.dart';
import '../domain/user_preferences_repository.dart';

/// Cache local singleton para las preferencias del usuario.
/// Una sola entrada por `uid` con clave `user:<uid>:pref`.
class UserPreferencesLocalRepository implements UserPreferencesRepository {
  UserPreferencesLocalRepository(this._box);

  final Box<UserPreferences> _box;

  static String _key(String uid) => 'user:$uid:pref';

  @override
  Future<UserPreferences> getMine() async {
    for (final entry in _box.values) {
      return entry;
    }
    throw const UserPreferencesRepositoryException(
      error: UserPreferencesRepositoryError.notFound,
      message: 'No cached preferences found',
    );
  }

  @override
  Future<UserPreferences> update(UserPreferences prefs) async {
    await _box.put(_key(prefs.userId), prefs);
    return prefs;
  }

  Future<void> deleteByUserId(String uid) async {
    await _box.delete(_key(uid));
  }
}
