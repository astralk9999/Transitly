import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/theme/transit_colors.dart';
import 'core/utils/app_logger.dart';
import 'core/utils/error_boundary.dart';
import 'core/utils/sentry_setup.dart';
import 'core/utils/transit_provider_observer.dart';
import 'data/cache/hive_init.dart';
import 'data/fmtc/fmtc_service.dart';
import 'data/mock/mock_data_service.dart';
import 'data/mock/mock_realtime_service.dart';
import 'data/privacy_consent/privacy_consent_repository.dart';
import 'data/push/firebase_setup.dart';
import 'data/push/push_service.dart';
import 'features/error/env_error_screen.dart';
import 'shared/providers/active_palette_provider.dart';

/// F26 switch point: cuando las fuentes se empaqueten como assets locales,
/// poner `true` (y seguir `docs/FONTS_F26.md`). Mientras es `false`,
/// `google_fonts` resuelve por red (comportamiento actual).
const bool _fontsBundled = true;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorBoundary.setup();

  // F26: con fuentes empaquetadas se desactiva el fetch por red (privacidad
  // + offline). Sin empaquetar, se precargan en segundo plano sin bloquear
  // el arranque. Pasos exactos para cerrar F26: docs/FONTS_F26.md.
  if (_fontsBundled) {
    GoogleFonts.config.allowRuntimeFetching = false;
  } else {
    unawaited(GoogleFonts.pendingFonts([
      GoogleFonts.ibmPlexMono(),
    ]));
  }

  // Valida las variables de entorno compiladas vía --dart-define.
  // Si falta una clave crítica, la app se monta con una pantalla de
  // error explicativa en lugar de crashear silenciosamente.
  try {
    Env.supabaseUrl; // dispara _required validation
    await HiveInit.bootstrap();
    AppLogger.info('HiveCache', 'bootstrap complete');
    await _initFmtc();
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    AppLogger.info('Supabase', 'initialized url=${Env.supabaseUrl}');
    try {
      await FirebaseSetup.init();
      AppLogger.info('Firebase', 'initialized');
      final pushService = await PushService.init();
      if (pushService != null) {
        pushService.setupBackgroundOpenedHandler((deeplink) {
          AppLogger.info('PushService', 'background deeplink: $deeplink');
        });
        await pushService.handleColdStartMessage((deeplink) {
          AppLogger.info('PushService', 'cold start deeplink: $deeplink');
        });
      }
    } catch (e) {
      AppLogger.warn('Firebase', 'init failed — push unavailable', e);
    }
    try {
      final postHogKey = Env.postHogApiKey;
      if (postHogKey != null && postHogKey.isNotEmpty) {
        final config = PostHogConfig(postHogKey);
        config.host = Env.postHogHost;
        // GDPR: arrancar SIN autocapture y en opt-out. El SDK no envía
        // nada (ni "Application Opened") hasta que haya consentimiento
        // explícito; entonces PostHogAnalyticsService llama a enable().
        config.captureApplicationLifecycleEvents = false;
        config.optOut = true;
        await Posthog().setup(config);
        AppLogger.info('Analytics',
            'PostHog initialized (opt-out until consent) host=${Env.postHogHost}');
      } else {
        AppLogger.info('Analytics', 'PostHog skipped — no API key');
      }
    } catch (e) {
      AppLogger.warn('Analytics', 'PostHog init failed — analytics unavailable', e);
    }

    final sentryDsn = Env.sentryDsn;
    if (sentryDsn != null && sentryDsn.isNotEmpty) {
      final consentRepo = PrivacyConsentRepository(Supabase.instance.client);
      // GDPR: default-deny. Sin sesión (invitado) NO se inicializa Sentry;
      // se activa más abajo en onAuthStateChange tras leer el consentimiento.
      // Si la lectura de consentimiento falla, se mantiene desactivado.
      bool crashReportingOk = false;

      final session = Supabase.instance.client.auth.currentSession;
      if (session?.user != null) {
        try {
          final consents = await consentRepo.getConsents(session!.user.id);
          crashReportingOk = consents['crash_reporting'] != false;
        } catch (e) {
          AppLogger.warn('Sentry',
              'consent read failed — keeping crash reporting OFF', e);
        }
      }

      await SentrySetup.init(dsn: sentryDsn, enabled: crashReportingOk);
      AppLogger.info('Sentry', 'init enabled=$crashReportingOk');

      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn &&
            data.session?.user != null) {
          try {
            final c = await consentRepo.getConsents(data.session!.user.id);
            if (c['crash_reporting'] != false) {
              await SentrySetup.init(dsn: sentryDsn, enabled: true);
            }
          } catch (e) {
            AppLogger.warn('Sentry',
                'consent read on sign-in failed — keeping crash reporting OFF',
                e);
          }
        }
      });
    }
  } on EnvException catch (e, st) {
    // ignore: avoid_print
    print('[Env] failed to load critical key: $e\n$st');
    AppLogger.error('Env', 'failed to load critical key', e, st);
    runApp(EnvErrorApp(exception: e));
    return;
  } catch (e, st) {
    // ignore: avoid_print
    print('[Startup] init failed (will show EnvErrorApp as malformed): $e\n$st');
    AppLogger.error('Supabase', 'initialize failed', e, st);
    runApp(EnvErrorApp(
      exception: EnvException(
        error: EnvError.malformed,
        key: 'SUPABASE_URL/ANON_KEY',
        message: e.toString(),
      ),
    ));
    return;
  }

  final mockData = await MockDataService.init();

  final container = ProviderContainer(
    observers: const [TransitProviderObserver()],
    overrides: [
      mockDataServiceProvider.overrideWithValue(mockData),
    ],
  );
  registerAppContainer(container);
  TransitColorScheme.registerResolver(
    (isDark) => resolveActiveScheme(isDark),
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _TransitlyAppWithLifecycle(),
    ),
  );
}

class _TransitlyAppWithLifecycle extends StatefulWidget {
  const _TransitlyAppWithLifecycle();

  @override
  State<_TransitlyAppWithLifecycle> createState() =>
      _TransitlyAppWithLifecycleState();
}

class _TransitlyAppWithLifecycleState
    extends State<_TransitlyAppWithLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final container = ProviderScope.containerOf(context);
    final service = container.read(mockRealtimeServiceProvider);
    if (state == AppLifecycleState.paused) {
      service.pause();
    } else if (state == AppLifecycleState.resumed) {
      service.resume();
    }
  }

  @override
  Widget build(BuildContext context) => const TransitlyApp();
}

Future<void> _initFmtc() async {
  try {
    await FmtcService.initialise(
      maxDatabaseSize: 50 * 1024 * 1024,
      maxTileCount: 50000,
    );
  } catch (e) {
    AppLogger.warn('FMTC', 'init failed — map caching unavailable', e);
  }
}
