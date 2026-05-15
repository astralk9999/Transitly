import 'package:posthog_flutter/posthog_flutter.dart';

import '../../core/utils/app_logger.dart';

enum AnalyticsEvent {
  appOpen,
  signInSuccess,
  signInFailure,
  signUpSuccess,
  searchPerformed,
  routeViewed,
  incidentCreated,
  feedbackCreated,
  shareRoute,
  officialRequestSubmitted,
  paletteChanged,
  backgroundToggled,
  colorblindModeChanged,
  offlineRegionDownloaded,
  driverTripStarted,
  driverTripEnded,
  adminActionTaken,
}

abstract class AnalyticsService {
  void track(AnalyticsEvent event, {Map<String, String>? properties});
  void identify(String userId, {Map<String, dynamic>? props});
  void reset();
}

class PostHogAnalyticsService implements AnalyticsService {
  @override
  void track(AnalyticsEvent event, {Map<String, String>? properties}) {
    AppLogger.debug('Analytics', 'track ${event.name}');
    Posthog().capture(
      eventName: event.name,
      properties: properties ?? <String, Object>{},
    );
  }

  @override
  void identify(String userId, {Map<String, dynamic>? props}) {
    AppLogger.debug('Analytics', 'identify $userId');
    Posthog().identify(
      userId: userId,
      userProperties: props?.map((k, v) => MapEntry(k, v as Object)),
    );
  }

  @override
  void reset() {
    AppLogger.debug('Analytics', 'reset');
    Posthog().reset();
  }
}

class NoopAnalyticsService implements AnalyticsService {
  @override
  void track(AnalyticsEvent event, {Map<String, String>? properties}) {}

  @override
  void identify(String userId, {Map<String, dynamic>? props}) {}

  @override
  void reset() {}
}
