import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/auth/auth_repository.dart';
import '../../shared/providers/auth_provider.dart';

/// Pantalla de retorno del login OAuth (deep link `transitly://login-callback`).
/// Sin esta ruta, go_router mostraba 404 al volver del navegador. Muestra un
/// spinner mientras Supabase termina de procesar el código del deep link y, en
/// cuanto `authStateProvider` emite la sesión, navega al inicio. Si pasa
/// demasiado tiempo (p.ej. el usuario canceló), vuelve a /sign-in.
class AuthCallbackScreen extends ConsumerStatefulWidget {
  const AuthCallbackScreen({super.key});

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  Timer? _timeout;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Si ya hay sesión al entrar (Supabase la procesó muy rápido), navega ya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = ref.read(authStateProvider).valueOrNull;
      if (auth is AuthAuthenticated) _go('/home/inicio');
    });
    // Red de seguridad: si en 12 s no llega sesión, vuelve a sign-in.
    _timeout = Timer(const Duration(seconds: 12), () => _go('/sign-in'));
  }

  void _go(String path) {
    if (_navigated || !mounted) return;
    _navigated = true;
    _timeout?.cancel();
    context.go(path);
  }

  @override
  void dispose() {
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    // Navega en cuanto la sesión esté lista.
    ref.listen<AsyncValue<AuthSessionState>>(authStateProvider, (_, next) {
      if (next.valueOrNull is AuthAuthenticated) _go('/home/inicio');
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.accent),
            const SizedBox(height: 20),
            Text('Completando inicio de sesión…',
                style: TransitTypography.bodyPrimary(c.textHi)),
          ],
        ),
      ),
    );
  }
}
