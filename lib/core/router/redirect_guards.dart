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
    final role = ref.read(currentUserRoleProvider);
    if (isAdminRoute && role != UserRole.admin) return '/home/inicio';
    if (isManagementRoute &&
        role != UserRole.admin &&
        role != UserRole.moderator) {
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
