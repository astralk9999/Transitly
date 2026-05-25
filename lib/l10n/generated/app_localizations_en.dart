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
  String get actionSend => 'Send';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSignOut => 'Sign out';

  @override
  String get actionSaveDraft => 'Save draft';

  @override
  String get actionSendSuggestion => 'Send suggestion';

  @override
  String get actionSendFeedback => 'Send feedback';

  @override
  String get actionSendImprovement => 'Send improvement';

  @override
  String get actionSendRequest => 'Send request';

  @override
  String get actionSending => 'Sending...';

  @override
  String get sectionUpcomingArrivals => 'UPCOMING ARRIVALS';

  @override
  String get sectionSchedules => 'SCHEDULES';

  @override
  String get sectionRecentChanges => 'RECENT CHANGES';

  @override
  String get routeDayWeekday => 'Weekday';

  @override
  String get routeDaySaturday => 'Saturday';

  @override
  String get routeDaySunday => 'Sunday';

  @override
  String get routeDayHoliday => 'Holiday';

  @override
  String get stopLinesHeader => 'LINES';

  @override
  String get routeTimeline => 'ROUTE';

  @override
  String get editorStepInfo => 'Information';

  @override
  String get editorStepTrace => 'Trace';

  @override
  String get editorStepStops => 'Stops';

  @override
  String get editorStepReturn => 'Return';

  @override
  String get editorStepReview => 'Review';

  @override
  String get actionNext => 'Next';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionPause => 'Pause';

  @override
  String get actionResume => 'Resume';

  @override
  String get actionFinish => 'Finish';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionPublish => 'Publish';

  @override
  String get actionGenerate => 'Generate';

  @override
  String get actionRevoke => 'Revoke';

  @override
  String get actionShare => 'Share';

  @override
  String get actionApply => 'Apply';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionStop => 'Stop';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionFollow => 'Follow';

  @override
  String get featureComingSoon => 'Coming soon in a future update.';

  @override
  String get statusPaused => 'PAUSED';

  @override
  String get statusLive => 'LIVE';

  @override
  String get statusRecordingRoute => 'RECORDING ROUTE';

  @override
  String get recorderMarkStop => 'MARK STOP';

  @override
  String recorderStopMarkedFmt(int number, String distance) {
    return 'STOP #$number MARKED · $distance km';
  }

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
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'You have no notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsAllRead => 'All read';

  @override
  String get notificationTypeIncidentResolved => 'Incident resolved';

  @override
  String get notificationTypeRoutePromoted => 'Route promoted';

  @override
  String get notificationTypeShareReceived => 'Route shared with you';

  @override
  String get notificationTypeFeatureRequestReplied =>
      'Response to your request';

  @override
  String get notificationTypeBusApproaching => 'Bus approaching';

  @override
  String get notificationTypeCustom => 'Notice';

  @override
  String get notificationTimeNow => 'Now';

  @override
  String notificationTimeMinutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String notificationTimeHours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n h ago',
      one: '1 h ago',
    );
    return '$_temp0';
  }

  @override
  String notificationTimeDays(num n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n d ago',
      one: '1 d ago',
    );
    return '$_temp0';
  }

  @override
  String get notifPrefSectionTitle => 'NOTIFICATIONS';

  @override
  String get notifPrefIncidentResolved => 'Resolved reports';

  @override
  String get notifPrefRoutePromoted => 'My routes';

  @override
  String get notifPrefBusApproaching => 'Nearby buses';

  @override
  String get notifPrefFeatureRequestReplied => 'Suggestions';

  @override
  String get notifPrefQuietHoursSection => 'QUIET HOURS';

  @override
  String get notifPrefQuietHoursEnabled => 'Enable quiet hours';

  @override
  String get notifPrefQuietHoursDescription =>
      'During this time you will not receive sound notifications. Notifications will still appear in the notification center.';

  @override
  String get notifPrefQuietHoursStart => 'From';

  @override
  String get notifPrefQuietHoursEnd => 'To';

  @override
  String get notifPrefQuietHoursNotSet => 'Not set';

  @override
  String get notifPrefSelectTime => 'Select time';

  @override
  String get privacyTitle => 'Privacy';

  @override
  String get privacySectionConsents => 'CONSENTS';

  @override
  String get privacyConsentAnalytics => 'Analytics';

  @override
  String get privacyConsentAnalyticsDesc =>
      'Anonymous usage data to improve the app';

  @override
  String get privacyConsentCrashReporting => 'Crash reporting';

  @override
  String get privacyConsentCrashReportingDesc =>
      'Send automatic reports when the app crashes';

  @override
  String get privacyConsentMarketing => 'Marketing';

  @override
  String get privacyConsentMarketingDesc =>
      'Receive news and promotions about Transitly';

  @override
  String get privacySectionMyData => 'MY DATA';

  @override
  String get privacyDownloadData => 'Download my data';

  @override
  String get privacyRequestDeletion => 'Request account deletion';

  @override
  String get privacySectionLegal => 'LEGAL';

  @override
  String get privacyTermsOfService => 'Terms of service';

  @override
  String get privacyPrivacyPolicy => 'Privacy policy';

  @override
  String get privacyDataExportRequested =>
      'Export request sent. You will receive a link when ready.';

  @override
  String get privacyDeletionRequested =>
      'Deletion request sent. Your data will be deleted in 30 days.';

  @override
  String get privacyDeleteConfirmTitle => 'Request account deletion?';

  @override
  String get privacyDeleteConfirmMessage =>
      'Your data will be deleted after a 30-day waiting period.';

  @override
  String get privacyDeleteConfirmCancel => 'Cancel';

  @override
  String get privacyDeleteConfirmAction => 'Request deletion';

  @override
  String get privacyLinkLabel => 'Privacy';

  @override
  String get widgetsTitle => 'Widgets';

  @override
  String get widgetsSectionInstructions => 'INSTRUCTIONS';

  @override
  String get widgetsInstructionsAndroid =>
      'On Android, long-press the home screen and select \"Add widget\". Find Transitly in the list.';

  @override
  String get widgetsInstructionsIos =>
      'On iOS, long-press the home screen, tap the + button, and find Transitly.';

  @override
  String get widgetsFavoriteStop => 'Favorite stop';

  @override
  String get widgetsFavoriteLine => 'Favorite line';

  @override
  String get widgetsHowToAdd => 'How to add the widget';

  @override
  String get widgetsConfigSaved => 'Settings saved';

  @override
  String get offlineBannerOffline =>
      'Offline. Changes will be saved and sent when you\'re back.';

  @override
  String offlineBannerQueued(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actions queued',
      one: '1 action queued',
    );
    return 'Offline · $_temp0.';
  }

  @override
  String offlineBannerSyncing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pending actions',
      one: '1 pending action',
    );
    return 'Syncing $_temp0…';
  }

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'you@email.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => '••••••••';

  @override
  String get authPasswordMinHint => 'Minimum 6 characters';

  @override
  String get authName => 'Name';

  @override
  String get authNameHint => 'Your name';

  @override
  String get authRequired => 'Required';

  @override
  String get authRequiredField => 'Required';

  @override
  String get authInvalidEmail => 'Invalid email';

  @override
  String get authMinChars => 'Minimum 6 characters';

  @override
  String get authEnterValidEmail => 'Enter a valid email';

  @override
  String get authErrorConnection => 'Connection error';

  @override
  String get authErrorGoogle => 'Google connection error';

  @override
  String get authSignInSubtitle => 'Sign in to continue';

  @override
  String get authSignInButton => 'SIGN IN';

  @override
  String get authSignInError => 'Error signing in';

  @override
  String get authNoAccount => 'Don\'t have an account?';

  @override
  String get authRegister => 'Register';

  @override
  String get authForgotPassword => 'Forgot your password?';

  @override
  String get authOrContinue => 'or continue with';

  @override
  String get authGoogleButton => 'GOOGLE';

  @override
  String get authMagicLink => 'Access with magic link';

  @override
  String get authSignUpTitle => 'Create account';

  @override
  String get authSignUpSubtitle => 'Join Transitly';

  @override
  String get authSignUpButton => 'CREATE ACCOUNT';

  @override
  String get authSignUpError => 'Error signing up';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authSignInLink => 'Sign in';

  @override
  String get signupAgeGateTitle => 'Age verification';

  @override
  String get signupAgeGateUnder16 => 'You must be at least 16';

  @override
  String get signupAgeGateLabel => 'Date of birth';

  @override
  String get authRecoverTitle => 'Recover password';

  @override
  String get authRecoverSent =>
      'If the email exists, you will receive a link to reset your password.';

  @override
  String get authRecoverHint => 'Enter your email and we\'ll send you a link';

  @override
  String get authSendLinkButton => 'SEND LINK';

  @override
  String get authBackToSignIn => 'Back to sign in';

  @override
  String get authRecoverError => 'Error sending recovery';

  @override
  String get authMagicLinkTitle => 'Magic link';

  @override
  String get authMagicLinkSent =>
      'Check your email. We\'ve sent you an access link.';

  @override
  String get authMagicLinkHint => 'We\'ll send an access link to your email';

  @override
  String get authMagicLinkError => 'Error sending the link';

  @override
  String get authVerifyTitle => 'Verify your email';

  @override
  String get authVerifyMessage =>
      'We\'ve sent you a verification email. Check your inbox and click the link to continue.';

  @override
  String get authResendButton => 'RESEND EMAIL';

  @override
  String get authSignOutAndBack => 'Sign out and go back';

  @override
  String get authResendSuccess => 'Verification email resent.';

  @override
  String get authResendError => 'Error resending';

  @override
  String get authActivateDriverTitle => 'Activate driver mode';

  @override
  String get authActivateDriverHint =>
      'Your company gave you a code.\nEnter it here to activate driver mode.';

  @override
  String get authActivateNeedLogin =>
      'You need to sign in to activate driver mode.';

  @override
  String get authActivateButton => 'ACTIVATE';

  @override
  String get authActivateEnterCode => 'Enter the code';

  @override
  String get authActivateCodeNotFound => 'Code not found';

  @override
  String get authActivateCodeExpired => 'The code has expired';

  @override
  String get authActivateCodeDepleted => 'The code has no more uses available';

  @override
  String get authActivateError => 'Error activating the code';

  @override
  String get authActivateNeedSession => 'You need to sign in first';

  @override
  String get authActivateSuccess => 'Welcome. You can now use driver mode.';

  @override
  String get authSignOutTitle => 'Sign out?';

  @override
  String get authSignOutMessage => 'You will return to the sign in screen.';

  @override
  String get authSignOutCancel => 'CANCEL';

  @override
  String get authSignOutConfirm => 'SIGN OUT';

  @override
  String get authDeleteAccountTitle => 'Delete account?';

  @override
  String get authDeleteAccountMessage => 'This action is irreversible.';

  @override
  String get authDeleteAccountButton => 'DELETE';

  @override
  String get authDeleteAccountError => 'Could not delete the account';

  @override
  String get authDeleteAccountCancel => 'CANCEL';

  @override
  String get filterPresetsTitle => 'Filter presets';

  @override
  String get filterPresetsEmptyTitle => 'No saved presets';

  @override
  String get filterPresetsEmptySubtitle =>
      'Save your most-used map filter combination to apply it with one tap.';

  @override
  String get filterPresetsActionSave => 'SAVE CURRENT FILTERS';

  @override
  String get filterPresetsTileHint => 'Tap to apply';

  @override
  String get filterPresetsTileDelete => 'Delete';

  @override
  String get filterPresetsDialogTitle => 'Save filters';

  @override
  String get filterPresetsDialogHint => 'Preset name';

  @override
  String get filterPresetsDialogConfirm => 'SAVE';

  @override
  String filterPresetsApplied(String name) {
    return 'Filters \"$name\" applied';
  }

  @override
  String get driverStatsTitle => 'Statistics';

  @override
  String get driverStatsEmptyTitle => 'No data yet';

  @override
  String get driverStatsEmptySubtitle =>
      'Your statistics are calculated from your trip history.';

  @override
  String get driverStatsTrips => 'Trips';

  @override
  String get driverStatsDistinctLines => 'Distinct lines';

  @override
  String get driverStatsTotalCost => 'Total cost';

  @override
  String get driverStatsDistance => 'Distance';

  @override
  String get driverStatsCo2Saved => 'CO₂ saved';

  @override
  String get driverHistoryTitle => 'Driver history';

  @override
  String get driverHistoryEmptyTitle => 'No trips yet';

  @override
  String get driverHistoryEmptySubtitle =>
      'When you complete routes they will appear here with their route and cost.';

  @override
  String get driverHistoryUnknownRoute => 'Unknown route';

  @override
  String get plannedTripsTitle => 'Planned trips';

  @override
  String get plannedTripsEmptyTitle => 'No planned trips';

  @override
  String get plannedTripsEmptySubtitle =>
      'Mark a route as favorite and set an alert to see it here as a regular trip.';

  @override
  String get plannedTripsNoStop => 'Stop not defined';

  @override
  String plannedTripsFrom(String stop) {
    return 'From $stop';
  }

  @override
  String get aiScheduleImportTitle => 'Import schedule';

  @override
  String get aiScheduleImportEmptyTitle => 'Import schedules';

  @override
  String get aiScheduleImportEmptySubtitle =>
      'Paste schedule text to automatically extract departure times.';

  @override
  String get aiScheduleImportHint =>
      'Paste the schedule and departure times will be extracted. Parsing is local (demo): detects HH:MM patterns, no AI or backend used.';

  @override
  String get aiScheduleImportFieldHint => 'e.g. 06:00  06:30  07:00 ...';

  @override
  String get aiScheduleImportAnalyze => 'ANALYZE';

  @override
  String get aiScheduleImportNoTimes => 'No times detected';

  @override
  String aiScheduleImportDetected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count departures detected',
      one: '1 departure detected',
    );
    return '$_temp0';
  }

  @override
  String get suggestionContributeTitle => 'Contribute to suggestions';

  @override
  String get suggestionContributeEmptyTitle => 'Nothing to contribute now';

  @override
  String get suggestionContributeEmptySubtitle =>
      'No open suggestions. Check back later or propose a new route from the suggestions tab.';

  @override
  String get cityPickerErrorOperators => 'Error loading operators';

  @override
  String get driversErrorLoading => 'Error loading drivers';

  @override
  String get driversErrorRevoking => 'Error revoking driver';

  @override
  String get invitationCodesErrorLoading => 'Error loading codes';

  @override
  String get invitationCodesErrorGenerating => 'Error generating code';

  @override
  String get invitationCodesErrorRevoking => 'Error revoking code';

  @override
  String get routeOfficializeError => 'Error sending request';

  @override
  String get routeShareUserNotFound => 'User not found';

  @override
  String routeShareSuccess(String email) {
    return 'Route shared with $email';
  }

  @override
  String get routeShareError => 'Error sharing route';

  @override
  String get routeShareErrorGeneratingLink => 'Error generating link';

  @override
  String get routeDetailNotFound => 'Route not found';

  @override
  String get routeDetailAddFavorite => 'ADD TO MY LINES ★';

  @override
  String get routeDetailRemoveFavorite => 'IN MY LINES ✓';

  @override
  String get favoriteAdded => 'Line added to your favorites';

  @override
  String get favoriteRemoved => 'Line removed from your favorites';

  @override
  String get stopDetailNotFound => 'Stop not found';

  @override
  String get feedbackErrorSending => 'Error sending feedback';

  @override
  String get incidentErrorSending => 'Error sending report';

  @override
  String homeRouteSemanticsLabel(String code, String time) {
    return '$code, $time';
  }

  @override
  String nfcCardBalance(String amount) {
    return 'Balance: $amount euros';
  }

  @override
  String homeNextBusSemantics(String route) {
    return 'Your next bus, $route';
  }

  @override
  String generalComingSoon(String feature) {
    return '$feature: coming soon';
  }

  @override
  String capacitySemanticsLabel(String level) {
    return 'Occupancy: $level';
  }

  @override
  String reputationSemanticsLabel(String level) {
    return 'Reputation: $level';
  }

  @override
  String reputationScoreSemantics(String label, int score) {
    return '$label: $score points';
  }

  @override
  String routeCardSemantics(
    String code,
    String name,
    String status,
    String minutes,
  ) {
    return 'Line $code, $name$status$minutes';
  }

  @override
  String get adminPanelTitle => 'Admin panel';

  @override
  String get adminPanelSubtitle => 'Manage the platform';

  @override
  String get cityPickerSelectOperator => 'Select operator';

  @override
  String get driverPermissionRequired => 'Location permission required';

  @override
  String get driverModeLabel => 'Driver mode';

  @override
  String driverGreeting(String name) {
    return 'Hi $name';
  }

  @override
  String driverCurrentOperator(String name) {
    return 'Operator: $name';
  }

  @override
  String get driverSelectRoute => 'Select route';

  @override
  String get driverNoRoutesLoaded => 'No routes loaded';

  @override
  String get driverChooseAnother => 'Choose another';

  @override
  String envErrorLabel(String name) {
    return 'Error: $name';
  }

  @override
  String envKeyLabel(String key) {
    return 'Key: $key';
  }

  @override
  String get feedbackSelectCategoryFirst => 'Select a category first';

  @override
  String get feedbackEnterDescription => 'Write a description';

  @override
  String get feedbackSent => 'Feedback sent · Thanks';

  @override
  String get routeFeedbackImprovementSent => 'Improvement sent. Thanks!';

  @override
  String get mapSearchComingSoon => 'Map search: coming soon';

  @override
  String get profileDeleteAccount => 'Delete account';

  @override
  String get profileCreateAccount => 'Create account';

  @override
  String get profileColorBlindModeNone => 'Mode: None';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get incidentReportSent => 'Report sent. Thanks for your contribution.';

  @override
  String inviteCodeGenerated(String code) {
    return 'Code generated: $code';
  }

  @override
  String get inviteGenerateCode => 'Generate code';

  @override
  String get operatorPanelTitle => 'Operator panel';

  @override
  String get operatorPanelSubtitle => 'Manage your transit operator';

  @override
  String get routeChangelogEmpty => 'No recent changes';

  @override
  String get routeFeedbackThanksConfirming => 'Thanks for confirming!';

  @override
  String get routeNoUpcomingSchedules => 'No upcoming schedules';

  @override
  String get stopNoLinesRegistered => 'No lines registered';

  @override
  String get suggestRouteSent => 'Suggestion sent · We\'ll let you know';

  @override
  String suggestRouteSubmitError(String error) {
    return 'Failed to send: $error';
  }

  @override
  String get searchEmptyTitle => 'Enter origin and destination';

  @override
  String get searchEmptySubtitle => 'We\'ll show you the fastest routes';

  @override
  String get searchUnderConstructionTitle => 'Search under construction';

  @override
  String get searchUnderConstructionSubtitle =>
      'In the meantime, suggest routes to us';

  @override
  String get searchReportRouteAction => 'Suggest route';

  @override
  String get driverPanelTitle => 'DRIVER MODE';

  @override
  String get driverPanelStartRoute => 'Start route';

  @override
  String get driverPanelActiveRoute => 'Active route';

  @override
  String get driverPanelCreateManualRoute => 'Create manual route';

  @override
  String get driverPanelCreateLiveRoute => 'Create live route';

  @override
  String get driverPanelMyRoutes => 'My routes';

  @override
  String get driverPanelImportSchedules => 'Import schedules';

  @override
  String get driverPanelManagementInbox => 'Management inbox';

  @override
  String get driverActiveNoActiveRoute => 'No active route';

  @override
  String get driverActiveRouteHeader => 'ACTIVE ROUTE';

  @override
  String driverActiveRouteStartedAt(String code, String time) {
    return '$code · $time START';
  }

  @override
  String get driverActiveNextStopHeader => 'NEXT STOP';

  @override
  String driverActiveStopRegisteredFmt(String time) {
    return 'STOP REGISTERED · $time';
  }

  @override
  String get driverActiveRegisterStop => 'REGISTER STOP';

  @override
  String get driverActiveIncidentButton => 'INCIDENT';

  @override
  String get driverActiveFinishRouteButton => 'FINISH ROUTE';

  @override
  String get driverActiveFinishConfirmTitle => 'Finish route?';

  @override
  String get driverActiveFinishConfirmMessage =>
      'The route will be registered as completed.';

  @override
  String get driverActiveFinishConfirmButton => 'FINISH';

  @override
  String get driverStartTitle => 'START ROUTE';

  @override
  String driverStartSuggestionFmt(String code, String time, String day) {
    return 'SUGGESTION: $code · $time · $day';
  }

  @override
  String get driverStartIsThisYourRoute => 'Is this your route?';

  @override
  String get driverStartYesStart => 'YES, START';

  @override
  String get driverStartSelectLine => 'SELECT LINE';

  @override
  String get driverStartSelectSchedule => 'SELECT SCHEDULE';

  @override
  String driverStartDepartureFmt(String time) {
    return 'Departure: $time';
  }

  @override
  String driverStartStopsAndTime(int count, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count stops',
      one: '1 stop',
    );
    return '$_temp0 · ~$minutes min';
  }

  @override
  String get driverStartStartButton => 'START ROUTE';

  @override
  String feedbackScreenTitleFmt(String code) {
    return 'FEEDBACK · $code';
  }

  @override
  String get feedbackDescriptionLabel => 'Description';

  @override
  String get feedbackDescriptionHint => 'Description of what you found';

  @override
  String get feedbackCategoryRouteLabel => 'The route on the map';

  @override
  String get feedbackCategoryStopsLabel =>
      'A stop (missing, extra or incorrect)';

  @override
  String get feedbackCategorySchedulesLabel => 'The schedules';

  @override
  String get feedbackCategoryInfoLabel => 'General information';

  @override
  String get feedbackCategorySuggestionLabel => 'I have a suggestion';

  @override
  String get suggestRouteScreenTitle => 'SUGGEST ROUTE';

  @override
  String get suggestRouteHelpText => 'Help us complete the transport map';

  @override
  String get suggestRouteFromLabel => 'From';

  @override
  String get suggestRouteFromHint => 'Origin';

  @override
  String get suggestRouteToLabel => 'To';

  @override
  String get suggestRouteToHint => 'Destination';

  @override
  String get suggestRouteOperatorLabel => 'Operator?';

  @override
  String get suggestRouteOperatorComujesa => 'COMUJESA';

  @override
  String get suggestRouteOperatorOther => 'Other';

  @override
  String get suggestRouteOperatorDontKnow => 'I don\'t know';

  @override
  String get suggestRouteCodeLabel => 'Line code';

  @override
  String get suggestRouteCodeHint => 'e.g. M-250';

  @override
  String get suggestRouteHowKnow => 'How do you know?';

  @override
  String get suggestRouteSourceUseIt => 'I use it';

  @override
  String get suggestRouteSourceSawIt => 'I\'ve seen it';

  @override
  String get suggestRouteSourceTold => 'Someone told me';

  @override
  String get suggestRouteSourceWeb => 'Official website';

  @override
  String get suggestRouteAddDetails => 'Add more details';

  @override
  String get suggestRouteStopsRemember => 'Stops you remember';

  @override
  String suggestRouteStopNumber(int number) {
    return 'Stop $number';
  }

  @override
  String get suggestRouteAddStop => '+ Add stop';

  @override
  String get suggestRouteTimesKnown => 'Times you know';

  @override
  String get suggestRouteNotesLabel => 'Notes';

  @override
  String get suggestRouteNotesHint => 'Any additional details...';

  @override
  String get suggestRouteAddTimeTitle => 'Add time';

  @override
  String get suggestRouteAddTimeHint => 'HH:MM';

  @override
  String get suggestRouteAddTimeConfirm => 'ADD';

  @override
  String get incidentSheetTitle => 'WHAT HAPPENED?';

  @override
  String get incidentNoShow => 'No show';

  @override
  String get incidentDelay => 'Delay';

  @override
  String get incidentFull => 'Full';

  @override
  String get incidentDetour => 'Detour';

  @override
  String get incidentBreakdown => 'Breakdown';

  @override
  String get incidentOther => 'Other';

  @override
  String get incidentPositiveLabel => 'POSITIVE:';

  @override
  String get incidentPunctual => 'Punctual';

  @override
  String get incidentKind => 'Kind';

  @override
  String get incidentClean => 'Clean';

  @override
  String get incidentCommentHint => 'Comment (optional)';

  @override
  String get driverStartTrip => 'Start trip';

  @override
  String get driverSelectRouteFirst => 'Select a route';

  @override
  String get driverLoadRoutes => 'Load routes';

  @override
  String get routeShareTitle => 'Share route';

  @override
  String get routeShareWithUser => 'Share with user';

  @override
  String get routeShareEmailHint => 'email@example.com';

  @override
  String get routeSharePublicLink => 'Public link';

  @override
  String get routeShareGenerateLink => 'Generate link';

  @override
  String get routeShareRegenerateLink => 'Regenerate link';

  @override
  String get routeShareNeedLogin => 'Sign in to share routes';

  @override
  String get routeShareLinkGenerated => 'Link generated';

  @override
  String get mapFilterTitle => 'Map filters';

  @override
  String get mapFilterRouteSource => 'Route source';

  @override
  String get mapFilterOfficial => 'Official';

  @override
  String get mapFilterCommunity => 'Community';

  @override
  String get mapFilterUpcoming => 'Upcoming departures';

  @override
  String mapFilterMinutes(int m) {
    return '$m min';
  }

  @override
  String get mapFilterAccessibility => 'Accessibility';

  @override
  String get mapFilterOnlyAccessible => 'Accessible only';

  @override
  String get mapFilterFavorites => 'Favorites';

  @override
  String get mapFilterOnlyFavorites => 'Favorites only';

  @override
  String get myContributionsTitle => 'My contributions';

  @override
  String get myContributionsReload => 'Reload';

  @override
  String myContributionsSummary(int suggestions, int feedbacks, int reports) {
    return '$suggestions suggestions · $feedbacks feedback · $reports reports';
  }

  @override
  String get myContributionsLabelSuggestions => 'suggestions';

  @override
  String get myContributionsLabelCorrections => 'corrections';

  @override
  String get myContributionsLabelReports => 'reports';

  @override
  String get myContributionsLabelPhotos => 'photos';

  @override
  String get myContributionsTabSuggestions => 'Suggestions';

  @override
  String get myContributionsTabFeedback => 'Feedback';

  @override
  String get myContributionsTabReports => 'Reports';

  @override
  String get myContributionsEmptyFeedback => 'No feedback';

  @override
  String get myContributionsEmptyFeedbackSubtitle =>
      'Your submitted feedback will appear here';

  @override
  String get myContributionsEmptyReports => 'No reports';

  @override
  String get myContributionsEmptyReportsSubtitle =>
      'Your incident reports will appear here';

  @override
  String get myContributionsLocalDraft => 'Local draft';

  @override
  String get myContributionsNoDescription => 'No description';

  @override
  String get reputationCurrentRank => 'Current';

  @override
  String get appTagline => 'Universal public transport platform';

  @override
  String get homeSectionNearbyStops => 'STOPS NEAR YOU';

  @override
  String get homeSectionMyLines => 'MY LINES';

  @override
  String get homeSectionAlerts => 'ALERTS';

  @override
  String get homeSectionNextBus => 'YOUR NEXT BUS';

  @override
  String get homeChangeCityTooltip => 'Change city';

  @override
  String get homeDefaultCity => 'Jerez de la Frontera';

  @override
  String get accessibilityThemeSystemSubtitle => 'Follow device settings';

  @override
  String get accessibilityThemeLightSubtitle =>
      'Light background, daytime high contrast';

  @override
  String get accessibilityThemeDarkSubtitle =>
      'Dark background, lower OLED consumption';

  @override
  String get accessibilityLanguageSystemSubtitle => 'Follow device language';

  @override
  String get accessibilityLanguageEsSubtitle => 'Force Spanish';

  @override
  String get accessibilityLanguageEnSubtitle => 'Force English';

  @override
  String get accessibilitySystemPrefAnimations => 'Animations';

  @override
  String get accessibilitySystemPrefTextSize => 'Text size';

  @override
  String get accessibilitySystemPrefBoldText => 'Bold text';

  @override
  String get accessibilitySystemPrefActivated => 'On';

  @override
  String get accessibilitySystemPrefDeactivated => 'Off';

  @override
  String get accessibilitySystemPrefReduced => 'Reduced';

  @override
  String get accessibilitySystemPrefEnabled => 'Enabled';

  @override
  String get accessibilitySystemPrefFootnote =>
      'These settings are read from the operating system. Change them in your device settings for the app to respond.';

  @override
  String get operatorAdminMissingOperator =>
      'No operator found for your account. Please contact support.';

  @override
  String get adminUsersLoadError =>
      'Could not load the user list. Please try again.';

  @override
  String get offlineRegionDemoLimitation =>
      'Demo version: only the Jerez de la Frontera region can be downloaded. Free region selection available in upcoming versions.';

  @override
  String get editorDraftSaved => 'Draft saved successfully';

  @override
  String get cardNfcTitle => 'NFC CARD';

  @override
  String get cardNfcUnavailable => 'NFC UNAVAILABLE';

  @override
  String get cardNfcExplanation =>
      'Reading transport cards requires a device with NFC. Hold the card near the back of the phone.';

  @override
  String get scheduleHideAll => 'Hide ▴';

  @override
  String get scheduleShowAll => 'Show all ▾';

  @override
  String get activateDriverCodeHint => 'XXX-XXXX-XX';

  @override
  String get routeFeedbackImproveInfo => 'IMPROVE INFORMATION';

  @override
  String get routeFeedbackLine => 'Line:';

  @override
  String get routeFeedbackStop => 'Stop:';

  @override
  String get routeFeedbackImproveType => 'Improvement type';

  @override
  String get offlineDataReloadButton => 'Reload from assets';

  @override
  String get offlineDataExplanation =>
      'This app uses a local JSON bundle with COMUJESA (Jerez) demo data.';

  @override
  String get aiScheduleImportPrototypeBanner => 'PROTOTYPE';

  @override
  String get appExitConfirmMessage => 'Press again to exit';

  @override
  String get profileGuestLabel => 'GUEST';

  @override
  String get profileGuestCta => 'Sign in to see your profile';

  @override
  String get profileGuestSignIn => 'SIGN IN';

  @override
  String get profileSignOutConfirmTitle => 'Sign out?';

  @override
  String get profileSignOutConfirmMessage =>
      'You will return to the sign in screen.';

  @override
  String get profileBecomeDriver => 'Become a driver';

  @override
  String get actionSignIn => 'Sign in';

  @override
  String get profileAdminSectionTitle => 'ADMINISTRATION';
}
