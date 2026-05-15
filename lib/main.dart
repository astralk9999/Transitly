import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/utils/app_logger.dart';
import 'data/cache/hive_init.dart';
import 'data/mock/mock_data_service.dart';
import 'data/push/firebase_setup.dart';
import 'features/error/env_error_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preload fonts in the background; we don't block app start on this.
  unawaited(GoogleFonts.pendingFonts([
    GoogleFonts.ibmPlexMono(),
    GoogleFonts.dmSans(),
  ]));

  // Cargar .env e inicializar Supabase ANTES de cualquier ProviderScope.
  // Si esto falla, la app se monta con una pantalla de error explicativa
  // en lugar de crashear silenciosamente; el resto del bootstrap (mock
  // data + go_router) se omite.
  try {
    await Env.load();
    await HiveInit.bootstrap();
    AppLogger.info('HiveCache', 'bootstrap complete');
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    AppLogger.info('Supabase', 'initialized url=${Env.supabaseUrl}');
    try {
      await FirebaseSetup.init();
      AppLogger.info('Firebase', 'initialized');
    } catch (e) {
      AppLogger.warn('Firebase', 'init failed — push unavailable', e);
    }
    try {
      final postHogKey = Env.postHogApiKey;
      if (postHogKey != null && postHogKey.isNotEmpty) {
        final config = PostHogConfig(postHogKey);
        config.host = Env.postHogHost;
        await Posthog().setup(config);
        AppLogger.info('Analytics', 'PostHog initialized host=${Env.postHogHost}');
      } else {
        AppLogger.info('Analytics', 'PostHog skipped — no API key');
      }
    } catch (e) {
      AppLogger.warn('Analytics', 'PostHog init failed — analytics unavailable', e);
    }
  } on EnvException catch (e, st) {
    AppLogger.error('Env', 'failed to load critical key', e, st);
    runApp(EnvErrorApp(exception: e));
    return;
  } catch (e, st) {
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

  runApp(
    ProviderScope(
      overrides: [
        mockDataServiceProvider.overrideWithValue(mockData),
      ],
      child: const TransitlyApp(),
    ),
  );
}
