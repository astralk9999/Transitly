import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/utils/app_logger.dart';
import '../../shared/providers/privacy_consent_provider.dart';
import 'analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiKey = Env.postHogApiKey;

  if (apiKey == null || apiKey.isEmpty) {
    AppLogger.info('Analytics', 'provider returning NoopAnalyticsService (no api key)');
    return NoopAnalyticsService();
  }

  final consents = ref.watch(privacyConsentsProvider).valueOrNull;
  if (consents != null && consents['analytics'] == false) {
    AppLogger.info('Analytics', 'provider returning NoopAnalyticsService (consent denied)');
    return NoopAnalyticsService();
  }

  AppLogger.info('Analytics', 'provider returning PostHogAnalyticsService');
  return PostHogAnalyticsService();
});
