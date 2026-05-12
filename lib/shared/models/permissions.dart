import 'user_role.dart';

/// Matriz de permisos por rol. La fuente de verdad es RLS en Supabase;
/// esta extensión es solo UX — oculta botones y muestra mensajes antes
/// de que el servidor rechace la operación.
extension UserRolePermissions on UserRole {
  bool get canReportIncident => true;

  bool get canCreateCommunityRoute => true;

  bool get canShareRoute => true;

  bool get canVote => true;

  bool get canPublishBusPositionAsDriver =>
      this == UserRole.driver ||
      this == UserRole.operatorAdmin ||
      this == UserRole.admin;

  bool get canModerateContent =>
      this == UserRole.moderator || this == UserRole.admin;

  bool get canPromoteToOfficial => this == UserRole.admin;

  bool get canManageUsers => this == UserRole.admin;

  bool get canImportGtfs =>
      this == UserRole.admin || this == UserRole.operatorAdmin;

  bool get canManageOperator =>
      this == UserRole.operatorAdmin || this == UserRole.admin;

  bool get canViewAuditLog => this == UserRole.admin;

  /// Nombre legible para la UI.
  String get displayName => switch (this) {
        UserRole.passenger => 'Pasajero',
        UserRole.driver => 'Conductor',
        UserRole.operatorAdmin => 'Admin. de operador',
        UserRole.moderator => 'Moderador',
        UserRole.admin => 'Administrador',
      };
}
