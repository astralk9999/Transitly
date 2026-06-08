-- 042_route_path_zone_notif.sql
-- - user_routes.path: guarda el trazado (segmentos con puntos) de las rutas
--   de comunidad, que antes no se persistía (el wizard lo dibujaba pero no lo
--   guardaba en ninguna tabla).
-- - zone_recommend: la notificación a admins ahora incluye quién propone la
--   zona y un texto con contexto (antes solo el nombre de la zona, y el cliente
--   mostraba "Aviso" genérico).
ALTER TABLE user_routes ADD COLUMN IF NOT EXISTS path JSONB;

CREATE OR REPLACE FUNCTION public.zone_recommend(p_name TEXT,p_type TEXT)
RETURNS UUID LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_id UUID; v_who TEXT;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Auth requerida'; END IF;
  INSERT INTO zones (name,zone_type,status,created_by)
  VALUES (p_name,COALESCE(p_type,'municipality'),'pending',auth.uid()) RETURNING id INTO v_id;
  SELECT display_name INTO v_who FROM profiles WHERE id = auth.uid();
  INSERT INTO notifications (user_id,type,payload)
  SELECT p.id,'custom',jsonb_build_object(
    'title','Nueva zona propuesta',
    'body', COALESCE(v_who,'Un usuario')||' propone la zona "'||p_name||'". Revísala en la bandeja.',
    'kind','zone_recommendation','zone_id',v_id) FROM profiles p WHERE p.role='admin';
  RETURN v_id;
END $$;
GRANT EXECUTE ON FUNCTION public.zone_recommend(TEXT,TEXT) TO authenticated;
