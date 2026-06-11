-- P1.3 (plan post-TFG): fija search_path en las funciones de public que lo
-- tenían mutable (lint function_search_path_mutable). Se fija a `public`
-- porque los cuerpos usan nombres sin cualificar de tablas de public:
-- mismo comportamiento, sin posibilidad de shadowing por el caller.
--
-- NOTA: aplicada al remoto el 2026-06-12 vía MCP (`p1_3_pin_search_path_functions`).

ALTER FUNCTION public._daytype_label(text) SET search_path = public;
ALTER FUNCTION public._touch_route_updated_at() SET search_path = public;
ALTER FUNCTION public.add_xp(uuid,integer) SET search_path = public;
ALTER FUNCTION public.admin_broadcast_alert(uuid) SET search_path = public;
ALTER FUNCTION public.admin_set_ban(uuid,boolean,text) SET search_path = public;
ALTER FUNCTION public.check_user_routes_quota() SET search_path = public;
ALTER FUNCTION public.create_invitation_code(uuid,integer,integer,text) SET search_path = public;
ALTER FUNCTION public.generate_invitation_code_string() SET search_path = public;
ALTER FUNCTION public.generate_public_slug() SET search_path = public;
ALTER FUNCTION public.generate_share_code() SET search_path = public;
ALTER FUNCTION public.inc_routes_created_count() SET search_path = public;
ALTER FUNCTION public.is_admin() SET search_path = public;
ALTER FUNCTION public.is_operator_admin_of(uuid) SET search_path = public;
ALTER FUNCTION public.revoke_invitation_code(text) SET search_path = public;
ALTER FUNCTION public.set_updated_at() SET search_path = public;
ALTER FUNCTION public.snapshot_lines(uuid) SET search_path = public;
ALTER FUNCTION public.stop_timetable_by_name(text) SET search_path = public;
ALTER FUNCTION public.stop_timetable(uuid) SET search_path = public;
ALTER FUNCTION public.trg_duplicate_report_xp() SET search_path = public;
ALTER FUNCTION public.trg_feedback_accepted_xp() SET search_path = public;
ALTER FUNCTION public.trg_feedback_submitted_xp() SET search_path = public;
ALTER FUNCTION public.trg_incident_created_xp() SET search_path = public;
ALTER FUNCTION public.trg_incident_rejected_xp() SET search_path = public;
ALTER FUNCTION public.trg_route_published_xp() SET search_path = public;
ALTER FUNCTION public.trg_suggestion_created_xp() SET search_path = public;
ALTER FUNCTION public.trg_suggestion_verified_xp() SET search_path = public;
ALTER FUNCTION public.trg_suggestion_vote_xp() SET search_path = public;
ALTER FUNCTION public.user_routes_quota(uuid) SET search_path = public;
ALTER FUNCTION public.user_routes_search_update() SET search_path = public;
