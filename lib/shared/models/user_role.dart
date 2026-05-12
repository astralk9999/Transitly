/// Roles de usuario alineados con el schema de Supabase
/// (`profiles.role`) y la matriz RLS de `002_rls.sql`.
enum UserRole {
  passenger,
  driver,
  operatorAdmin,
  moderator,
  admin,
}
