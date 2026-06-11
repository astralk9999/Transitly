-- P1.1 (plan post-TFG): route_vote_xp_awarded sin RLS (ERROR del linter).
--
-- La tabla es contabilidad interna del trigger de votos; el cliente nunca
-- la toca. Antes de activar RLS hay que hacer SECURITY DEFINER los triggers
-- que la escriben: corren como el votante autenticado y, bajo el RLS de
-- user_routes ("Owner updates own"), el UPDATE de vote_count en rutas
-- ajenas se filtraba en silencio (0 filas). Como DEFINER (owner) el
-- trigger bypassa RLS y el contador es fiable.
--
-- NOTA: aplicada al proyecto remoto el 2026-06-12 vía MCP con el nombre
-- `p1_1_rls_route_vote_xp_awarded`. El SQL es idempotente.

ALTER FUNCTION public.trg_route_vote_xp() SECURITY DEFINER SET search_path = public;
ALTER FUNCTION public.trg_route_unvote() SECURITY DEFINER SET search_path = public;

-- Las funciones de trigger no necesitan EXECUTE del invocador.
REVOKE EXECUTE ON FUNCTION public.trg_route_vote_xp() FROM anon, authenticated, public;
REVOKE EXECUTE ON FUNCTION public.trg_route_unvote() FROM anon, authenticated, public;

-- RLS sin policies: solo owner/service_role acceden; PostgREST deja de
-- exponer filas a anon/authenticated.
ALTER TABLE public.route_vote_xp_awarded ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.route_vote_xp_awarded FROM anon, authenticated;
