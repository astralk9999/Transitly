// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Transitly';

  @override
  String get tabHome => 'Home';

  @override
  String get tabSearch => 'Search';

  @override
  String get tabMap => 'Map';

  @override
  String get tabCard => 'Card';

  @override
  String get tabProfile => 'Profile';

  @override
  String get nfcErrorUnsupported => 'NFC is not available on this device';

  @override
  String get nfcErrorNotMifareClassic => 'This card is not supported';

  @override
  String get nfcErrorAuthFailed => 'Could not authenticate the card';

  @override
  String get nfcErrorReadFailed => 'Error reading the card';

  @override
  String get nfcErrorTagLost => 'Card removed too soon';

  @override
  String get nfcErrorUnknown => 'Unknown error';

  @override
  String get profileSectionAppearance => 'APPEARANCE';

  @override
  String get profileSectionDemoProfile => 'DEMO PROFILE';

  @override
  String get profileSectionAccessibility => 'ACCESSIBILITY';

  @override
  String get profileSectionOfflineData => 'OFFLINE DATA';

  @override
  String get profileSectionAbout => 'ABOUT';

  @override
  String get accessibilityTitle => 'Accessibility';

  @override
  String get accessibilityThemeSection => 'THEME';

  @override
  String get accessibilityThemeSystem => 'System';

  @override
  String get accessibilityThemeLight => 'Light';

  @override
  String get accessibilityThemeDark => 'Dark';

  @override
  String get accessibilitySystemPreferencesSection => 'SYSTEM PREFERENCES';

  @override
  String get accessibilityLanguageSection => 'LANGUAGE';

  @override
  String get accessibilityLanguageEs => 'Spanish';

  @override
  String get accessibilityLanguageEn => 'English';

  @override
  String get accessibilityLanguageSystem => 'Follow system language';

  @override
  String get offlineDataTitle => 'Offline data';

  @override
  String get offlineDataContent => 'CONTENT';

  @override
  String get offlineDataArchive => 'FILE';

  @override
  String get offlineDataReload => 'Reload from assets';

  @override
  String get offlineDataReloaded => 'Data reloaded';

  @override
  String get offlineDataSize => 'Size';

  @override
  String get offlineDataLoaded => 'Loaded';

  @override
  String get offlineDataRoutes => 'Routes';

  @override
  String get offlineDataStops => 'Stops';

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get adminUsersTitle => 'User management';

  @override
  String get adminUsersSearchHint => 'Search user...';

  @override
  String get adminUsersFilterAll => 'All';

  @override
  String get adminUsersEmpty => 'No users found';

  @override
  String get adminUsersOffline => 'Connect to the internet to manage users';

  @override
  String get adminUsersRoleAdmin => 'Admin';

  @override
  String get adminUsersRoleModerator => 'Moderator';

  @override
  String get adminUsersRoleOperatorAdmin => 'Operator Admin';

  @override
  String get adminUsersRoleDriver => 'Driver';

  @override
  String get adminUsersRolePassenger => 'Passenger';

  @override
  String get adminUsersRoleAll => 'All';

  @override
  String get adminUsersError => 'Error loading users';

  @override
  String get adminUsersNoConnection => 'No connection';

  @override
  String get adminUsersNoResults => 'No results';

  @override
  String adminUsersNoMatchSearch(String query) {
    return 'No users matching \"$query\"';
  }

  @override
  String get adminUsersNoMatchRole => 'No users with the selected role';
}
