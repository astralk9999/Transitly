import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/permissions.dart';
import '../models/user_role.dart';
import '../providers/user_provider.dart';

/// Muestra [child] solo si el usuario actual tiene uno de los roles
/// en [allow]. Opcionalmente muestra [fallback] si no tiene permiso.
class RoleGate extends ConsumerWidget {
  const RoleGate({
    super.key,
    required this.allow,
    required this.child,
    this.fallback,
  });

  final List<UserRole> allow;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (allow.contains(user.role)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}

/// Variante de [RoleGate] que comprueba un permiso booleano de
/// [UserRolePermissions] en lugar de una lista de roles.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  final bool Function(UserRole) permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (permission(user.role)) return child;
    return fallback ?? const SizedBox.shrink();
  }
}
