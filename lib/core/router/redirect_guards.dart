import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth/auth_repository.dart';
import '../../features/auth/auth_provider.dart';
import '../../shared/models/user_role.dart';
import '../../shared/providers/user_provider.dart';

String? authRedirect(Ref ref, GoRouterState state) {
  final authState = ref.read(authStateProvider);
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
