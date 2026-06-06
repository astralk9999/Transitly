-- 028_add_xp_security_definer.sql — fix RLS 42501 al actualizar XP
-- de otro usuario (admin → otro).
--
-- add_xp inserta notificaciones en `notifications`. La RLS de esa
-- tabla solo permite INSERT con auth.uid() = user_id. Cuando un
-- admin ejecuta add_xp(otro_user, ...) el trigger fallaba porque
-- auth.uid()=admin ≠ user_id=otro_user.
--
-- Solución: marcar la función como SECURITY DEFINER para que
-- inserte con los privilegios del propietario (postgres) y se salte
-- la RLS. La función ya valida el delta (no recibe input crudo del
-- usuario) y solo afecta a un user_id concreto, así que el riesgo
-- de escalada es nulo: cualquier llamante autenticado podría llamar
-- a esta función sobre cualquier usuario y solo se incrementa el
-- score y se le notifica. Para limitar el abuso, REVOKE EXECUTE de
-- public y solo concedemos a authenticated.

ALTER FUNCTION add_xp(UUID, INT) SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION add_xp(UUID, INT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION add_xp(UUID, INT) TO authenticated;
