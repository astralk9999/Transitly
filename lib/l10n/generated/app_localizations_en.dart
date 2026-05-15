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

  @override
  String get adminOperatorsTitle => 'Operator management';

  @override
  String get adminOperatorsCreate => 'Create operator';

  @override
  String get adminOperatorsEdit => 'Edit operator';

  @override
  String get adminOperatorsDelete => 'Delete';

  @override
  String get adminOperatorsSlug => 'Slug';

  @override
  String get adminOperatorsName => 'Name';

  @override
  String get adminOperatorsRegion => 'Region';

  @override
  String get adminOperatorsWebsite => 'Website';

  @override
  String get adminOperatorsEmail => 'Contact email';

  @override
  String get adminOperatorsDeleteConfirm => 'Delete this operator?';

  @override
  String get adminOperatorsEmpty => 'No operators registered';

  @override
  String get adminOperatorsCreated => 'Operator created';

  @override
  String get adminOperatorsUpdated => 'Operator updated';

  @override
  String get adminOperatorsDeleted => 'Operator deleted';

  @override
  String get adminOperatorsError => 'Error loading operators';

  @override
  String get adminOperatorsNoConnection => 'No connection';

  @override
  String get adminOperatorsOffline =>
      'Connect to the internet to manage operators';

  @override
  String get adminOperatorsErrorDenied =>
      'Permission denied to manage operators';

  @override
  String get adminOperatorsErrorNetwork => 'Network error loading operators';

  @override
  String get adminOperatorsErrorUnknown => 'Unknown error loading operators';

  @override
  String get managerInboxTitle => 'Management inbox';

  @override
  String get managerInboxFeedback => 'Feedback';

  @override
  String get managerInboxSuggestions => 'Suggestions';

  @override
  String get managerInboxResolved => 'Resolved';

  @override
  String managerInboxPending(int count) {
    return '$count pending';
  }

  @override
  String get managerInboxMarkInReview => 'Mark in review';

  @override
  String get managerInboxResolve => 'Resolve';

  @override
  String get managerInboxReject => 'Reject';

  @override
  String get managerInboxEmptyFeedback => 'No pending feedback';

  @override
  String get managerInboxEmptySuggestions => 'No suggestions';

  @override
  String get managerInboxEmptyResolved => 'No resolved items';

  @override
  String get managerInboxOpen => 'Open';

  @override
  String get managerInboxStatus => 'Status';

  @override
  String get managerInboxItemDescription => 'Description';

  @override
  String get managerInboxItemDate => 'Date';

  @override
  String get managerInboxItemType => 'Type';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearancePalettesSection => 'PALETTES';

  @override
  String get appearanceBrightnessSection => 'BRIGHTNESS';

  @override
  String get appearanceBackgroundSection => 'BACKGROUND';

  @override
  String get appearanceTextSection => 'TEXT';

  @override
  String get appearanceAccessibilitySection => 'VISUAL ACCESSIBILITY';

  @override
  String get appearanceShowBackground => 'Show decorative background';

  @override
  String get appearanceBackgroundOpacity => 'Background opacity';

  @override
  String get appearanceFontScale => 'Font scale';

  @override
  String get appearanceDyslexiaFont => 'Dyslexia-friendly font';

  @override
  String get appearanceColorBlindMode => 'Color blind mode';

  @override
  String get appearanceReduceMotion => 'Reduce motion';

  @override
  String get appearanceResetButton => 'Restore defaults';

  @override
  String get appearanceResetConfirm =>
      'Restore all appearance settings to their defaults?';

  @override
  String get appearanceResetDone => 'Settings restored';

  @override
  String get appearanceColorBlindNone => 'None';

  @override
  String get appearanceColorBlindProtanopia => 'Protanopia';

  @override
  String get appearanceColorBlindDeuteranopia => 'Deuteranopia';

  @override
  String get appearanceColorBlindTritanopia => 'Tritanopia';

  @override
  String get appearanceBrightnessSystem => 'System';

  @override
  String get appearanceBrightnessLight => 'Light';

  @override
  String get appearanceBrightnessDark => 'Dark';

  @override
  String get appearanceLinkAppearance => 'Customize appearance';

  @override
  String get appearanceBgNone => 'None';

  @override
  String get appearanceBgSmoke => 'Smoke';

  @override
  String get appearanceBgGradient => 'Gradient';

  @override
  String get appearanceBgGrid => 'Grid';

  @override
  String get appearanceBgTopo => 'Topography';

  @override
  String get appearanceTextPreview =>
      'The quick brown fox jumps over the lazy dog. This sample text lets you preview how the typography looks with the current settings.';

  @override
  String get appearanceCustomPaletteTitle => 'Custom palette';

  @override
  String get appearanceCustomPalettePrimary => 'Primary';

  @override
  String get appearanceCustomPaletteSecondary => 'Secondary';

  @override
  String get appearanceCustomPaletteBgRoot => 'Root background';

  @override
  String get appearanceCustomPaletteBgSurface => 'Surface background';

  @override
  String get appearanceCustomPaletteTextHi => 'Primary text';

  @override
  String get appearanceCustomPalettePreview => 'Preview';

  @override
  String get appearanceCustomPaletteContrastPass => 'AA Contrast';

  @override
  String get appearanceCustomPaletteContrastFail => 'Low contrast';

  @override
  String get appearanceCustomPaletteSaved => 'Palette saved';

  @override
  String get appearanceCustomPaletteAdd => 'Create palette';

  @override
  String get appearanceMapStyleSection => 'MAP STYLE';

  @override
  String get mapStyleStreets => 'Streets';

  @override
  String get mapStyleBasic => 'Basic';

  @override
  String get mapStyleBright => 'Bright';

  @override
  String get mapStyleDark => 'Dark';

  @override
  String get mapStyleLight => 'Light';

  @override
  String get appearanceHighContrast => 'High contrast';

  @override
  String get appearanceHighContrastSubtitle =>
      'Thicker borders and higher text contrast';

  @override
  String get accessibilityHighContrast => 'High contrast';

  @override
  String get accessibleBusesTitle => 'Nearby buses';

  @override
  String get accessibleBusesEmpty => 'No active buses';

  @override
  String get accessibleBusesNoActiveBuses =>
      'No buses found in operation right now';

  @override
  String get accessibleBusesError => 'Error loading buses';

  @override
  String get accessibleBusesNextStop => 'Next stop';

  @override
  String get accessibleBusesSourceEstimated => 'Estimated';

  @override
  String get accessibleBusesSourceDriver => 'Driver';

  @override
  String get accessibleBusesSourceOfficial => 'Official';

  @override
  String get accessibleBusesLinkLabel => 'View bus list';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get onboardingPage1Title => 'Real-time transport';

  @override
  String get onboardingPage1Description =>
      'Check where your bus is right now, without unnecessary waiting.';

  @override
  String get onboardingPage2Title => 'Your community helps you';

  @override
  String get onboardingPage2Description =>
      'Report incidents, suggest routes and help other passengers like you.';

  @override
  String get onboardingPage3Title => 'Works offline';

  @override
  String get onboardingPage3Description =>
      'Download your routes and check schedules even without connection.';

  @override
  String get reputationRankNone => 'No rank';

  @override
  String get reputationRankNovice => 'Novice';

  @override
  String get reputationRankContributor => 'Contributor';

  @override
  String get reputationRankAdvocate => 'Advocate';

  @override
  String get reputationRankCartographer => 'Cartographer';

  @override
  String get reputationRankGuardian => 'Guardian';

  @override
  String get reputationRankLegend => 'Legend';

  @override
  String get reputationEventIncidentCreated => 'Report created';

  @override
  String get reputationEventIncidentRejectedSpam => 'Report rejected (spam)';

  @override
  String get reputationEventFeedbackSubmitted => 'Feedback submitted';

  @override
  String get reputationEventFeedbackAccepted => 'Feedback accepted';

  @override
  String get reputationEventSuggestionCreated => 'Suggestion created';

  @override
  String get reputationEventSuggestionVoteReceived => 'Vote received';

  @override
  String get reputationEventSuggestionVerified => 'Suggestion verified';

  @override
  String get reputationEventSuggestionOfficial => 'Suggestion officialized';

  @override
  String get reputationEventDuplicateReport => 'Duplicate report';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String achievementsLevel(String level, int xp) {
    return 'Level: $level · $xp XP';
  }

  @override
  String get achievementsCategoryContribution => 'Contribution';

  @override
  String get achievementsCategoryUsage => 'Usage';

  @override
  String get reputationTitle => 'Reputation';

  @override
  String get reputationHowToEarn => 'How to earn';

  @override
  String get reputationRanks => 'Ranks';

  @override
  String get reputationTooltip =>
      'Reputation is decorative. It will unlock privileges later.';

  @override
  String get reputationPoints => 'points';

  @override
  String get reputationNextRank => 'Next rank';

  @override
  String get reputationMaxRank => 'Max rank reached';

  @override
  String get offlineRegionsTitle => 'Offline maps';

  @override
  String get offlineRegionsAddRegion => 'Add region';

  @override
  String get offlineRegionsEmpty => 'No offline maps downloaded';

  @override
  String get offlineRegionsEmptySubtitle =>
      'Download map areas to use them without connection';

  @override
  String get offlineRegionsDeleteConfirm => 'Delete this region?';

  @override
  String get offlineRegionsDeleteDesc =>
      'Downloaded tiles will be lost and you will need to download them again to use the map offline';

  @override
  String get offlineRegionsStatusReady => 'Ready';

  @override
  String get offlineRegionsStatusDownloading => 'Downloading';

  @override
  String get offlineRegionsStatusError => 'Error';

  @override
  String get offlineRegionsStatusStale => 'Stale';

  @override
  String get offlineRegionsDownloaded => 'Downloaded';

  @override
  String get offlineRegionsSize => 'Size';

  @override
  String get offlineRegionsActionDownload => 'Download';

  @override
  String get offlineRegionsActionDelete => 'Delete';

  @override
  String get offlineRegionsRegionName => 'Region name';

  @override
  String get offlineRegionsRegionNameHint => 'e.g. Downtown Jerez';

  @override
  String get offlineRegionsZoomMin => 'Min zoom';

  @override
  String get offlineRegionsZoomMax => 'Max zoom';

  @override
  String get offlineRegionsEstimatedSize => 'Estimated size';

  @override
  String get offlineRegionsSelectArea => 'Move the map to select an area';

  @override
  String get offlineRegionsDataSynced => 'Data synced';

  @override
  String offlineRegionsDataSyncedAt(String date) {
    return 'Synced on $date';
  }

  @override
  String get offlineRegionsMapLink => 'Offline maps';

  @override
  String get appearanceStorageSection => 'OFFLINE STORAGE';

  @override
  String get appearanceStorageTotal => 'Storage used';

  @override
  String get appearanceStorageFmtc => 'FMTC maps';

  @override
  String get appearanceStorageHive => 'Local data';

  @override
  String get appearanceStoragePending => 'Pending uploads';

  @override
  String get appearanceStorageClearCache => 'Clear map cache';

  @override
  String get appearanceStorageClearCacheConfirm =>
      'Delete all downloaded offline maps?';

  @override
  String get appearanceStorageClearCacheDone => 'Map cache cleared';

  @override
  String get appearanceStorageMaxInfo => 'Maximum storage: 500 MB';

  @override
  String get appearanceStorageNotAvailable => 'Not available';
}
