import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_logger.dart';
import 'sentry_setup.dart';

class TransitProviderObserver extends ProviderObserver {
  const TransitProviderObserver();

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    AppLogger.error(
      'Provider:${provider.name ?? provider.runtimeType}',
      error.toString(),
      error,
      stackTrace,
    );
    SentrySetup.captureException(error, stackTrace);
  }

  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Reserved for provider lifecycle monitoring
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    // Reserved for provider lifecycle monitoring
  }

  @override
  void didDisposeProvider(
    ProviderBase<Object?> provider,
    ProviderContainer container,
  ) {
    // Reserved for provider lifecycle monitoring
  }
}
