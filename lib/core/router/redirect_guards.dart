import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_repository.dart';
import '../../data/mock/mock_data_service.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/models/user_role.dart';
import '../../shared/providers/user_provider.dart';

String? authRedirect(Ref ref, GoRouterState state) {
  // authStateProvider es StreamProvider; ref.read devuelve un
  // AsyncValue<AuthSessionState>, NUNCA un AuthSessionState directo.
  // Sin .valueOrNull la comparación 'is AuthAuthenticated' era
  // siempre false y /admin redirigía a /home/inicio para admins
  // logueados (B8).
  final authState = ref.read(authStateProvider).valueOrNull;
  final isAuth = authState is AuthAuthenticated;
  final loc = state.matchedLocation;

  // Retorno del login OAuth por deep link `transitly://login-callback`. Según
  // el dispositivo, go_router lo recibe con el HOST 'login-callback' y path
  // vacío, por lo que no casaba con la ruta '/login-callback' y mostraba un
  // 404 (sacando la pantalla que escuchaba el authState). Lo interceptamos
  // aquí, antes del errorBuilder: si ya hay sesión vamos a inicio; si aún se
  // está procesando, a la pantalla de "completando…" que espera la sesión.
  final full = state.uri.toString();
  if (state.uri.host == 'login-callback' || full.contains('login-callback')) {
    return isAuth ? '/home/inicio' : '/login-callback';
  }

  final isAuthRoute = loc.startsWith('/sign-in') ||
      loc.startsWith('/sign-up') ||
      loc.startsWith('/magic-link') ||
      loc.startsWith('/recover-password') ||
      loc.startsWith('/verify-email');
  final isHomeRoute = loc.startsWith('/home') ||
      loc.startsWith('/route') ||
      loc.startsWith('/stop');
  final isPublicRoute = loc == '/splash' || loc == '/onboarding';
  final isAdminRoute = loc.startsWith('/admin');
  final isManagementRoute = loc.startsWith('/management');
  final isOperatorAdminRoute = loc.startsWith('/operator-admin');

  if (isAuthRoute && isAuth) return '/home/inicio';

  if (isAdminRoute || isManagementRoute || isOperatorAdminRoute) {
    if (!isAuth) return '/home/inicio';
    // Si el perfil aún no ha resuelto (p.ej. ProfileTab lo invalida al
    // entrar), el rol colapsa al mock 'passenger' y sacaría a un admin /
    // operator_admin de su propio panel. No bloqueamos hasta saber el rol.
    final profileAsync = ref.read(userProfileFromSupabaseProvider);
    if (!profileAsync.hasValue && !profileAsync.hasError) return null;
    final role = ref.read(currentUserRoleProvider);
    if (isAdminRoute && role != UserRole.admin) return '/home/inicio';
    // Gestión: admin global, moderador, y admin de operadora (este último
    // solo ve/edita lo de su operadora, filtrado por las propias pantallas).
    if (isManagementRoute &&
        role != UserRole.admin &&
        role != UserRole.moderator &&
        role != UserRole.operatorAdmin) {
      return '/home/inicio';
    }
    if (isOperatorAdminRoute &&
        role != UserRole.admin &&
        role != UserRole.operatorAdmin) {
      return '/home/inicio';
    }
  }

  if (isHomeRoute || isPublicRoute || isAuthRoute) return null;

  return null;
}

String? routeDetailRedirect(Ref ref, GoRouterState state) {
  final id = state.pathParameters['routeId'];
  if (id == null) return '/home/inicio';
  // Aceptamos tanto rutas oficiales (mockData) como user_routes
  // (UUID v4). Si la id no parece de mock y tiene formato UUID,
  // dejamos que la pantalla de detalle la cargue desde Supabase.
  final mock = ref.read(mockDataServiceProvider);
  if (mock.getRouteById(id) != null) return null;
  final isUuid = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
      .hasMatch(id);
  if (isUuid) return null;
  return '/home/inicio';
}

String? stopDetailRedirect(Ref ref, GoRouterState state) {
  final id = state.pathParameters['stopId'];
  final mock = ref.read(mockDataServiceProvider);
  if (id == null || mock.getStopById(id) == null) {
    return '/home/inicio';
  }
  return null;
}
