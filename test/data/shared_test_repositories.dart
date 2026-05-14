import 'package:transitly/data/user_preferences/domain/user_preferences_repository.dart';
import 'package:transitly/shared/models/user_preferences.dart';

UserPreferencesRepository mockUserPreferencesRepo() => _MockUserPreferencesRepo();

class _MockUserPreferencesRepo implements UserPreferencesRepository {
  UserPreferences _cached = const UserPreferences(userId: 'test');

  @override
  Future<UserPreferences> getMine() async => _cached;

  @override
  Future<UserPreferences> update(UserPreferences prefs) async {
    _cached = prefs;
    return prefs;
  }
}
