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

  // GDPR: default-deny. Solo se devuelve el servicio real cuando hay un
  // consentimiento EXPLÍCITO y positivo de analítica. Invitados (consents
  // == {}) o ausencia de la clave → Noop. El SDK además arranca con
  // optOut=true y sin autocapture (ver main.dart), de modo que nada se
  // envía hasta que este provider construya PostHogAnalyticsService.
  final consents = ref.watch(privacyConsentsProvider).valueOrNull;
  if (consents == null || consents['analytics'] != true) {
    AppLogger.info('Analytics',
        'provider returning NoopAnalyticsService (no explicit consent)');
    return NoopAnalyticsService();
  }

  AppLogger.info('Analytics', 'provider returning PostHogAnalyticsService');
  return PostHogAnalyticsService();
});
