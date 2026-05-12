import '../../../shared/models/user_preferences.dart';
import '../domain/user_preferences_repository.dart';

/// Mock repo para modo invitado. El usuario invitado no tiene `uid`
/// real, así que devolvemos defaults y persistimos cambios en memoria
/// efímera.
class UserPreferencesMockRepository implements UserPreferencesRepository {
  UserPreferences _cached = const UserPreferences(userId: 'guest');

  @override
  Future<UserPreferences> getMine() async => _cached;

  @override
  Future<UserPreferences> update(UserPreferences prefs) async {
    _cached = prefs;
    return prefs;
  }
}
