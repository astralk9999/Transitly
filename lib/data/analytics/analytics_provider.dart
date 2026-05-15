import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/utils/app_logger.dart';
import 'analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final apiKey = Env.postHogApiKey;

  if (apiKey == null || apiKey.isEmpty) {
    AppLogger.info('Analytics', 'provider returning NoopAnalyticsService');
    return NoopAnalyticsService();
  }

  AppLogger.info('Analytics', 'provider returning PostHogAnalyticsService');
  return PostHogAnalyticsService();
});
