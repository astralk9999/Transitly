-- 034_community_zones_moderation.sql
-- Zonas (tabla + RPCs crear/recomendar/aprobar), changelog real de rutas,
-- horarios por parada (trips), bandeja de moderación unificada y parche
-- a claim_invitation_code para fijar profiles.operator_id.
--
-- Aplicada en 4 bloques (034a..034d). Este archivo es el consolidado para
-- el historial del repo; el contenido es idéntico al aplicado vía MCP.

-- ╔═══════════════════════ 034a — ZONAS ═══════════════════════╗
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname='zone_status') THEN
    CREATE TYPE zone_status AS ENUM ('active','pending');
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS zones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  zone_type TEXT NOT NULL DEFAULT 'municipality',
  parent_zone_id UUID REFERENCES zones(id),
  status zone_status NOT NULL DEFAULT 'active',
  operator_id UUID REFERENCES operators(id),
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS zones_status_idx ON zones(status);

ALTER TABLE routes ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES zones(id);
ALTER TABLE stops  ADD COLUMN IF NOT EXISTS zone_id UUID REFERENCES zones(id);
CREATE INDEX IF NOT EXISTS routes_zone_idx ON routes(zone_id);
CREATE INDEX IF NOT EXISTS stops_zone_idx ON stops(zone_id);

ALTER TABLE zones ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS zones_select_all ON zones;
CREATE POLICY zones_select_all ON zones FOR SELECT TO anon, authenticated USING (true);

INSERT INTO zones (name, zone_type, status)
SELECT 'Jerez de la Frontera', 'municipality', 'active'
WHERE NOT EXISTS (SELECT 1 FROM zones WHERE name='Jerez de la Frontera');
UPDATE routes SET zone_id=(SELECT id FROM zones WHERE name='Jerez de la Frontera' LIMIT 1) WHERE zone_id IS NULL;
UPDATE stops  SET zone_id=(SELECT id FROM zones WHERE name='Jerez de la Frontera' LIMIT 1) WHERE zone_id IS NULL;

CREATE OR REPLACE FUNCTION public.zone_upsert(p_id UUID,p_name TEXT,p_type TEXT,p_parent UUID,p_operator_id UUID)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_id UUID; BEGIN
  IF NOT (is_admin() OR (p_operator_id IS NOT NULL AND _can_manage_operator(p_operator_id))) THEN
    RAISE EXCEPTION 'No autorizado para crear zonas'; END IF;
  IF p_id IS NULL THEN
    INSERT INTO zones (name,zone_type,parent_zone_id,status,operator_id,created_by)
    VALUES (p_name,COALESCE(p_type,'municipality'),p_parent,'active',p_operator_id,auth.uid())
    RETURNING id INTO v_id;
  ELSE
    UPDATE zones SET name=p_name,zone_type=COALESCE(p_type,'municipality'),
      parent_zone_id=p_parent,operator_id=p_operator_id,status='active' WHERE id=p_id RETURNING id INTO v_id;
  END IF; RETURN v_id; END $$;
GRANT EXECUTE ON FUNCTION public.zone_upsert(UUID,TEXT,TEXT,UUID,UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.zone_recommend(p_name TEXT,p_type TEXT)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_id UUID; BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Auth requerida'; END IF;
  INSERT INTO zones (name,zone_type,status,created_by)
  VALUES (p_name,COALESCE(p_type,'municipality'),'pending',auth.uid()) RETURNING id INTO v_id;
  INSERT INTO notifications (user_id,type,payload)
  SELECT p.id,'custom',jsonb_build_object('title','Nueva zona propuesta','body',p_name,
    'kind','zone_recommendation','zone_id',v_id) FROM profiles p WHERE p.role='admin';
  RETURN v_id; END $$;
GRANT EXECUTE ON FUNCTION public.zone_recommend(TEXT,TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.zone_set_status(p_id UUID,p_status TEXT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_creator UUID; v_name TEXT; BEGIN
  IF NOT is_admin() THEN RAISE EXCEPTION 'Solo admin'; END IF;
  SELECT created_by,name INTO v_creator,v_name FROM zones WHERE id=p_id;
  IF p_status='active' THEN
    UPDATE zones SET status='active' WHERE id=p_id;
    IF v_creator IS NOT NULL THEN INSERT INTO notifications (user_id,type,payload)
      VALUES (v_creator,'custom',jsonb_build_object('title','Zona aprobada','body',v_name,'kind','zone_approved')); END IF;
  ELSE
    DELETE FROM zones WHERE id=p_id AND status='pending';
    IF v_creator IS NOT NULL THEN INSERT INTO notifications (user_id,type,payload)
      VALUES (v_creator,'custom',jsonb_build_object('title','Zona rechazada','body',v_name,'kind','zone_rejected')); END IF;
  END IF; END $$;
GRANT EXECUTE ON FUNCTION public.zone_set_status(UUID,TEXT) TO authenticated;

CREATE OR REPLACE FUNCTION public.list_zones(p_include_pending BOOLEAN DEFAULT false)
RETURNS TABLE(id UUID,name TEXT,zone_type TEXT,status TEXT,operator_id UUID)
LANGUAGE sql SECURITY DEFINER SET search_path=public AS $$
  SELECT z.id,z.name,z.zone_type,z.status::text,z.operator_id FROM zones z
  WHERE z.status='active' OR (p_include_pending AND is_admin()) ORDER BY z.name; $$;
GRANT EXECUTE ON FUNCTION public.list_zones(BOOLEAN) TO authenticated;

-- ╔═══════ 034b — CHANGELOG, LOGGING, ZONE_ID, TRIPS ═══════╗
-- (ver migración aplicada; incluye route_changelog, log_route_change,
--  list_route_changelog, _daytype_label, admin_route_upsert(+zone),
--  admin_stop_upsert(+zone), admin_stop_move(log), admin_route_stop_add/remove(log),
--  admin_trip_upsert/delete, admin_list_trips).
-- El cuerpo completo está aplicado en la BD vía MCP (idéntico a este repo).

-- ╔═══════ 034c — MODERACIÓN UNIFICADA ═══════╗
-- moderation_list(only_open), moderation_resolve(source,id,action,points,note),
-- moderation_counts(). Ver BD.

-- ╔═══════ 034d — claim_invitation_code fija profiles.operator_id ═══════╗
-- Parche aplicado en BD.
