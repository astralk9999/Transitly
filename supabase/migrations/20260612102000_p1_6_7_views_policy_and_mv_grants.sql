-- P1.6 (plan post-TFG): la policy de INSERT en user_route_views era
-- WITH CHECK (true) — cualquiera podía registrar vistas suplantando a otro
-- usuario o inflar contadores con viewer_id arbitrario. Las vistas anónimas
-- (viewer_id NULL) son legítimas: la app las registra en modo invitado.
--
-- NOTA: aplicada al remoto el 2026-06-12 vía MCP (`p1_6_7_views_policy_and_mv_grants`).
DROP POLICY IF EXISTS "Any user can register view" ON public.user_route_views;
CREATE POLICY "Register view as self or anonymous" ON public.user_route_views
  FOR INSERT WITH CHECK (viewer_id IS NULL OR viewer_id = auth.uid());

-- P1.7: la materialized view next_scheduled_arrivals estaba expuesta vía
-- PostgREST pero ningún cliente la consume (la app usa los RPC
-- stop_timetable*); solo el refresh de pg_cron la toca (como owner).
REVOKE SELECT ON public.next_scheduled_arrivals FROM anon, authenticated;
