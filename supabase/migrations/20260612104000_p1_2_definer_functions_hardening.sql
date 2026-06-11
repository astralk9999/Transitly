-- P1.2 (plan post-TFG): endurecimiento de las funciones SECURITY DEFINER
-- expuestas a anon/authenticated (lint *_security_definer_function_executable).
-- NOTA: aplicada al remoto el 2026-06-12 vía MCP (`p1_2_definer_functions_hardening`).
-- Ver el detalle completo de la justificación en docs/PLAN_ACCION_POST_TFG.md §P1.2.
--
-- (A) add_xp no validaba rol: cualquier usuario autenticado podía regalarse
--     XP por RPC. Se crea admin_add_xp (con check is_admin) para el panel y
--     se revoca add_xp a los roles de cliente. Los triggers de XP que la
--     llaman anidada pasan a SECURITY DEFINER.
-- (B) Las funciones de trigger no necesitan EXECUTE del invocador.
-- (C) RPCs de cliente que requieren sesión: se revoca anon. Se conservan
--     para anon las RPCs read-only de datos públicos y los helpers de policies.

CREATE OR REPLACE FUNCTION public.admin_add_xp(p_user_id uuid, p_xp integer)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT is_admin() THEN
    RAISE EXCEPTION 'forbidden: solo admin puede ajustar XP'
      USING ERRCODE = '42501';
  END IF;
  PERFORM add_xp(p_user_id, p_xp);
END $$;
REVOKE EXECUTE ON FUNCTION public.admin_add_xp(uuid,integer) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_add_xp(uuid,integer) TO authenticated, service_role;

ALTER FUNCTION public.trg_duplicate_report_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_feedback_accepted_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_feedback_submitted_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_incident_created_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_incident_rejected_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_route_published_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_suggestion_created_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_suggestion_verified_xp() SECURITY DEFINER;
ALTER FUNCTION public.trg_suggestion_vote_xp() SECURITY DEFINER;

REVOKE EXECUTE ON FUNCTION public.add_xp(uuid,integer) FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public._notify_admins_on_route_report() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_user_route_view_count() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_duplicate_report_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_feedback_accepted_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_feedback_submitted_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_incident_created_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_incident_rejected_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_route_published_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_suggestion_created_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_suggestion_verified_xp() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.trg_suggestion_vote_xp() FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public._can_manage_operator(uuid) FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.process_account_deletions() FROM PUBLIC, anon, authenticated;

REVOKE EXECUTE ON FUNCTION public.admin_broadcast_alert(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_delete_user_route(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_route_stops(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_stops(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_list_trips(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_delete(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_set_operator(uuid,uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_set_polyline(uuid,jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_stop_add(uuid,uuid,integer,smallint) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_stop_remove(uuid,uuid,smallint) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_stops_reorder(uuid,smallint,jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_route_upsert(uuid,uuid,text,text,text,text,text,text,boolean,uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_schedule_delete(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_schedule_upsert(uuid,uuid,text,smallint,text,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_schedules_clear(uuid,text,smallint) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_schedules_generate_frequency(uuid,text,smallint,text,text,integer) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_set_ban(uuid,boolean,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_stop_delete(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_stop_move(uuid,double precision,double precision) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_stop_upsert(uuid,uuid,text,text,double precision,double precision,boolean,boolean,boolean,uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_trip_delete(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.admin_trip_upsert(uuid,uuid,text,smallint,jsonb) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.cast_feature_request_vote(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.cast_suggestion_vote(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.claim_invitation_code(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_invitation_code(uuid,integer,integer,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.end_my_live_trip() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.import_community_route(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.log_route_change(uuid,text,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.mark_all_notifications_read() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.moderation_counts() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.moderation_list(boolean) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.moderation_resolve(text,uuid,text,integer,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.officialize_user_route(uuid,uuid,uuid,text,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.promote_route_to_official(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_driver(uuid,uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.revoke_invitation_code(text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.submit_official_request(uuid,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zone_delete(uuid) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zone_recommend(text,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zone_set_status(uuid,text) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.zone_upsert(uuid,text,text,uuid,uuid,double precision,double precision,integer) FROM PUBLIC, anon;
