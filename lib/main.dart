import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
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
import 'data/widgets_native/widget_data_writer.dart';
import 'data/fmtc/fmtc_service.dart';
import 'data/mock/mock_data_service.dart';
import 'data/mock/mock_realtime_service.dart';
import 'data/privacy_consent/privacy_consent_repository.dart';
import 'data/push/firebase_setup.dart';
import 'data/push/push_service.dart';
import 'features/error/env_error_screen.dart';
import 'core/router/app_router.dart';
import 'shared/services/widget_deep_link_service.dart';
import 'shared/providers/active_palette_provider.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/home_habitual_config_provider.dart';
import 'shared/providers/theme_notifier.dart';
import 'shared/providers/user_location_provider.dart';

/// F26 switch point: cuando las fuentes se empaqueten como assets locales,
/// poner `true` (y seguir `docs/FONTS_F26.md`). Mientras es `false`,
/// `google_fonts` resuelve por red (comportamiento actual).
///
/// NOTA 2026-06-02: dejado en `false` porque falta el peso w600 (SemiBold)
/// en assets/fonts/ibm_plex_mono/ y eso producía spam de errores en logs
/// cada vez que un widget pedía GoogleFonts.ibmPlexMono(weight: w600).
/// El resto de fuentes (Regular, Medium, Bold, Atkinson, DM Sans variable)
/// sí están empaquetadas y se sirven local sin red.
const bool _fontsBundled = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Permitir todas las orientaciones (portrait + landscape). El usuario
  // puede querer ver mapa, formularios o fondos animados en horizontal,
  // y en tablet/web es lo esperable.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
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
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        autoRefreshToken: true,
      ),
    );
    final restoredSession = Supabase.instance.client.auth.currentSession;
    final hasUser = restoredSession?.user != null;
    final uidShort = restoredSession?.user.id.substring(0, 8) ?? 'none';
    AppLogger.info('Supabase',
        'initialized url=${Env.supabaseUrl} session=$hasUser uid=$uidShort expiresAt=${restoredSession?.expiresAt}');
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

  // FIX bug 7 (sesión se cierra al reabrir):
  // En algunos dispositivos `Supabase.initialize` devuelve `currentSession`
  // como null inmediatamente aunque la sesión SÍ exista en storage
  // (FlutterSecureStorage tarda en hidratar). Damos un pequeño margen
  // y reintentamos antes de declarar al usuario como invitado.
  var session = Supabase.instance.client.auth.currentSession;
  if (session?.user == null) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    session = Supabase.instance.client.auth.currentSession;
  }
  AppLogger.info('Startup',
      'post-init session userId=${session?.user.id.substring(0, 8) ?? "guest"}');
  if (session?.user == null) {
    await container.read(themeNotifierProvider).loadGuest();
  }

  registerAppContainer(container);
  TransitColorScheme.registerResolver(
    resolveActiveScheme,
  );

  final launchUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
  if (launchUri != null) {
    // Reconstruimos el path uniendo host + pathSegments. El host de URIs
    // tipo transitly://home/tarjeta es "home" y path "/tarjeta"; concatenar
    // crudo produciría "//tarjeta" si host viniera vacío en algún OEM.
    final segments = <String>[
      if ((launchUri.host).isNotEmpty) launchUri.host,
      ...launchUri.pathSegments,
    ];
    final deepPath = '/${segments.join('/')}';
    setWidgetLaunchPath(deepPath);
    AppLogger.info('Startup',
        'widget deep link raw=$launchUri host=${launchUri.host} path=${launchUri.path} → resolved=$deepPath');
  }

  HomeWidget.registerBackgroundCallback(_widgetBackgroundCallback);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const _TransitlyAppWithLifecycle(),
    ),
  );

  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final event = data.event;
    if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.tokenRefreshed) {
      container.invalidate(authStateProvider);
      AppLogger.info('Startup', 'auth event=$event → invalidated providers');
    }
  });
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
  WidgetDeepLinkService? _deepLinkService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDeepLinks();
    });
  }

  void _setupDeepLinks() {
    final container = ProviderScope.containerOf(context);
    final router = container.read(routerProvider);
    _deepLinkService = WidgetDeepLinkService(router);
    _deepLinkService!.handleColdStart();
    _deepLinkService!.startListening();
  }

  @override
  void dispose() {
    _deepLinkService?.dispose();
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
      container.invalidate(userLocationPermissionProvider);
      container.invalidate(userLocationStreamProvider);
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

@pragma('vm:entry-point')
void _widgetBackgroundCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await HiveInit.bootstrap();
  } catch (_) {}

  final container = ProviderContainer();
  try {
    final mockData = container.read(mockDataServiceProvider);
    final cfg = container.read(homeHabitualConfigProvider);
    if (cfg.isConfigured) {
      final route = mockData.getRouteById(cfg.routeId!);
      if (route != null) {
        final deps = mockData.getNextDepartures(cfg.routeId!, cfg.stopId!, 4);
        if (deps.isNotEmpty) {
          final first = deps.first;
          final now = DateTime.now();
          final parts = first.departureTime.split(':');
          final depHour = int.tryParse(parts[0]) ?? 0;
          final depMin = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
          final depMinutes = depHour * 60 + depMin;
          final nowMinutes = now.hour * 60 + now.minute;
          var eta = depMinutes - nowMinutes;
          if (eta < 0) eta += 24 * 60;
          final stop = mockData.getStopById(cfg.stopId!);
          await WidgetDataWriter.writeNextBus(
            stopName: stop?.name ?? cfg.stopId!,
            routeCode: route.code,
            etaMinutes: eta,
            source: 'background',
            updatedAt: now,
          );
          await WidgetDataWriter.writeMyLineStatus(
            routeCode: route.code,
            upcoming: deps.map((d) => {'time': d.departureTime}).toList(),
          );
        }
      }
    }
  } catch (_) {}
  container.dispose();
}
