import 'package:posthog_flutter/posthog_flutter.dart';

import '../../core/utils/app_logger.dart';

class PostHogAnalyticsService {
  PostHogAnalyticsService._();

  static bool _consentGranted = false;

  static void enable() {
    _consentGranted = true;
    Posthog().enable();
    AppLogger.info('Analytics', 'PostHog enabled (consent granted)');
  }

  static void disable() {
    _consentGranted = false;
    Posthog().disable();
    AppLogger.info('Analytics', 'PostHog disabled (consent revoked)');
  }

  static void track(String event, {Map<String, Object>? properties}) {
    if (!_consentGranted) return;
    try {
      Posthog().capture(eventName: event, properties: properties);
    } catch (e) {
      AppLogger.warn('Analytics', 'track $event failed', e);
    }
  }

  static void signup(String method) =>
      track('signup', properties: {'method': method});

  static void signin(String method) =>
      track('signin', properties: {'method': method});

  static void signout() => track('signout');

  static void accountDeleted(int retentionDays) =>
      track('account_deleted', properties: {'retention_days': retentionDays});

  static void routeViewed(String routeId, String operatorId) =>
      track('route_viewed',
          properties: {'route_id': routeId, 'operator_id': operatorId});

  static void stopViewed(String stopId, List<String> routeIds) =>
      track('stop_viewed',
          properties: {'stop_id': stopId, 'route_ids': routeIds});

  static void mapInteraction(
          double zoomLevel, double centerLat, double centerLng) =>
      track('map_interaction', properties: {
        'zoom_level': zoomLevel.toStringAsFixed(1),
        'center_lat': centerLat.toStringAsFixed(2),
        'center_lng': centerLng.toStringAsFixed(2),
      });

  static void searchPerformed(String query, int resultCount) =>
      track('search_performed',
          properties: {'query': query, 'result_count': resultCount});

  static void nfcReadSuccess(String cardType, double balanceEur) =>
      track('nfc_read_success', properties: {
        'card_type': cardType,
        'balance_eur': balanceEur.toStringAsFixed(2),
      });

  static void nfcReadError(String errorType) =>
      track('nfc_read_error', properties: {'error_type': errorType});

  static void incidentReported(
    String incidentType, {
    String? routeId,
    String? stopId,
  }) {
    final properties = <String, Object>{'incident_type': incidentType};
    if (routeId != null) properties['route_id'] = routeId;
    if (stopId != null) properties['stop_id'] = stopId;
    track('incident_reported', properties: properties);
  }

  static void suggestionCreated(String origin, String destination) =>
      track('suggestion_created',
          properties: {'origin': origin, 'destination': destination});

  static void feedbackSubmitted(String feedbackType, String routeId) =>
      track('feedback_submitted',
          properties: {'feedback_type': feedbackType, 'route_id': routeId});

  static void voteCast(String targetType, String targetId) =>
      track('vote_cast',
          properties: {'target_type': targetType, 'target_id': targetId});

  static void driverRouteStarted(String routeId, String operatorId) =>
      track('driver_route_started',
          properties: {'route_id': routeId, 'operator_id': operatorId});

  static void driverRouteCompleted(
    String routeId,
    int durationSeconds,
    int stopCount,
  ) =>
      track('driver_route_completed', properties: {
        'route_id': routeId,
        'duration_seconds': durationSeconds,
        'stop_count': stopCount,
      });

  static void invitationClaimed(String operatorId) =>
      track('invitation_claimed', properties: {'operator_id': operatorId});
}
