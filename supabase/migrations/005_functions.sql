-- =============================================================
-- 005_functions.sql — Funciones SQL útiles
-- =============================================================
-- F2.5 del plan v2. Empaqueta operaciones que requieren atomicidad
-- entre varias tablas o queries geoespaciales reusables. Las que
-- modifican varias filas con reglas de negocio van como
-- SECURITY DEFINER; las consultas espaciales puras quedan
-- SECURITY INVOKER (respetan la RLS del caller).

-- =============================================================
-- 1. claim_invitation_code(p_code)
-- =============================================================
-- Canjea un código de invitación. Valida existencia, fecha de
-- expiración y conteo de usos. Si el código es de tipo
-- 'operator_admin' además promociona el rol del usuario.
-- Crea/reactiva la driver_assignment, incrementa uses, y deja
-- traza en audit_log. Devuelve el operator_id resuelto.

CREATE OR REPLACE FUNCTION public.claim_invitation_code(p_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_code invitation_codes%ROWTYPE;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to claim an invitation'
      USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_code FROM invitation_codes WHERE code = p_code;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invitation code not found: %', p_code
      USING ERRCODE = 'P0002';
  END IF;

  IF v_code.expires_at IS NOT NULL AND v_code.expires_at < NOW() THEN
    RAISE EXCEPTION 'Invitation code expired'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_code.uses >= v_code.max_uses THEN
    RAISE EXCEPTION 'Invitation code already exhausted'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE invitation_codes SET uses = uses + 1 WHERE code = p_code;

  -- operator_admin codes promote the caller's role.
  IF v_code.kind = 'operator_admin' THEN
    UPDATE profiles SET role = 'operator_admin' WHERE id = v_user_id;
  END IF;

  -- Bind the user to the operator (or reactivate if previously revoked).
  INSERT INTO driver_assignments (driver_id, operator_id, granted_by)
    VALUES (v_user_id, v_code.operator_id, v_code.created_by)
    ON CONFLICT (driver_id, operator_id) DO UPDATE
      SET revoked_at = NULL, granted_by = v_code.created_by;

  INSERT INTO audit_log (actor_id, action, target_kind, target_id, payload)
    VALUES (
      v_user_id,
      'invitation.claimed',
      'invitation_code',
      NULL,
      jsonb_build_object(
        'code', p_code,
        'kind', v_code.kind,
        'operator_id', v_code.operator_id
      )
    );

  RETURN v_code.operator_id;
END;
$$;
COMMENT ON FUNCTION public.claim_invitation_code(TEXT) IS
  'Canjea un código de invitación. Crea driver_assignment y, si kind=operator_admin, promociona el rol. Devuelve operator_id.';
GRANT EXECUTE ON FUNCTION public.claim_invitation_code(TEXT) TO authenticated;

-- =============================================================
-- 2. promote_route_to_official(p_route_id)
-- =============================================================
-- Promociona una ruta comunitaria a oficial. Solo admin. Mantiene
-- operator_id (que debe estar set para satisfacer el CHECK de
-- routes), borra owner_id, cambia source y status a 'official'.

CREATE OR REPLACE FUNCTION public.promote_route_to_official(p_route_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_route routes%ROWTYPE;
BEGIN
  v_user_id := auth.uid();
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only admin can promote routes'
      USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_route FROM routes WHERE id = p_route_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Route not found: %', p_route_id
      USING ERRCODE = 'P0002';
  END IF;

  IF v_route.operator_id IS NULL THEN
    RAISE EXCEPTION 'Route has no operator_id; assign one before promoting'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE routes
    SET source = 'official', status = 'official', owner_id = NULL
    WHERE id = p_route_id;

  INSERT INTO audit_log (actor_id, action, target_kind, target_id, payload)
    VALUES (
      v_user_id,
      'route.promoted',
      'route',
      p_route_id,
      jsonb_build_object(
        'previous_owner', v_route.owner_id,
        'previous_source', v_route.source,
        'previous_status', v_route.status
      )
    );
END;
$$;
COMMENT ON FUNCTION public.promote_route_to_official(UUID) IS
  'Promociona una ruta a oficial (solo admin). Requiere operator_id ya asignado.';
GRANT EXECUTE ON FUNCTION public.promote_route_to_official(UUID) TO authenticated;

-- =============================================================
-- 3. submit_official_request(p_route_id, p_justification)
-- =============================================================
-- El owner de una ruta comunitaria solicita su oficialización.
-- Cambia status a 'pendingVerification' y crea un feature_request
-- kind='routeOfficial' con la justificación en payload.

CREATE OR REPLACE FUNCTION public.submit_official_request(
  p_route_id UUID,
  p_justification TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_route routes%ROWTYPE;
  v_request_id UUID;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required'
      USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_route FROM routes WHERE id = p_route_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Route not found: %', p_route_id
      USING ERRCODE = 'P0002';
  END IF;

  IF v_route.owner_id IS DISTINCT FROM v_user_id THEN
    RAISE EXCEPTION 'You are not the owner of this route'
      USING ERRCODE = '42501';
  END IF;

  IF v_route.source <> 'community' THEN
    RAISE EXCEPTION 'Only community routes can request officialization'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_route.status IN ('pendingVerification', 'official') THEN
    RAISE EXCEPTION 'Route status % does not allow a new request', v_route.status
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE routes SET status = 'pendingVerification' WHERE id = p_route_id;

  INSERT INTO feature_requests (kind, status, title, description, payload, author_id)
    VALUES (
      'routeOfficial',
      'open',
      format('Oficializar ruta: %s', v_route.name),
      p_justification,
      jsonb_build_object('route_id', p_route_id, 'justification', p_justification),
      v_user_id
    )
    RETURNING id INTO v_request_id;

  RETURN v_request_id;
END;
$$;
COMMENT ON FUNCTION public.submit_official_request(UUID, TEXT) IS
  'Owner de ruta comunitaria solicita oficialización. Cambia status a pendingVerification y crea feature_request.';
GRANT EXECUTE ON FUNCTION public.submit_official_request(UUID, TEXT) TO authenticated;

-- =============================================================
-- 4. nearby_operators(p_lat, p_lng, p_radius_m DEFAULT 50000)
-- =============================================================
-- Devuelve operadores cuya bbox intersecta un círculo de radio
-- p_radius_m alrededor del punto. Usa GIST sobre bbox vía
-- ST_DWithin geográfico (metros, no grados).

CREATE OR REPLACE FUNCTION public.nearby_operators(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m INT DEFAULT 50000
)
RETURNS SETOF operators
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT *
  FROM operators
  WHERE bbox IS NOT NULL
    AND ST_DWithin(
      bbox::geography,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_m
    );
$$;
COMMENT ON FUNCTION public.nearby_operators(DOUBLE PRECISION, DOUBLE PRECISION, INT) IS
  'Operadores cuya bbox cae en un radio (m) alrededor de (lat,lng). Default 50km.';
GRANT EXECUTE ON FUNCTION public.nearby_operators(DOUBLE PRECISION, DOUBLE PRECISION, INT) TO anon, authenticated;

-- =============================================================
-- 5. nearby_stops(p_lat, p_lng, p_radius_m DEFAULT 1000, p_limit DEFAULT 50)
-- =============================================================
-- Paradas dentro de un radio, ordenadas por distancia ascendente.

CREATE OR REPLACE FUNCTION public.nearby_stops(
  p_lat DOUBLE PRECISION,
  p_lng DOUBLE PRECISION,
  p_radius_m INT DEFAULT 1000,
  p_limit INT DEFAULT 50
)
RETURNS SETOF stops
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT *
  FROM stops
  WHERE ST_DWithin(
    geom::geography,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    p_radius_m
  )
  ORDER BY ST_Distance(
    geom::geography,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
  )
  LIMIT p_limit;
$$;
COMMENT ON FUNCTION public.nearby_stops(DOUBLE PRECISION, DOUBLE PRECISION, INT, INT) IS
  'Paradas en radio (m) ordenadas por distancia. Default 1km / 50 paradas.';
GRANT EXECUTE ON FUNCTION public.nearby_stops(DOUBLE PRECISION, DOUBLE PRECISION, INT, INT) TO anon, authenticated;

-- =============================================================
-- 6. routes_intersecting_bbox(p_bbox)
-- =============================================================
-- Rutas cuya geometría intersecta el bounding box dado. Pensado
-- para alimentar el viewport del mapa al hacer pan/zoom.

CREATE OR REPLACE FUNCTION public.routes_intersecting_bbox(p_bbox geometry)
RETURNS SETOF routes
LANGUAGE sql
STABLE
SET search_path = public
AS $$
  SELECT *
  FROM routes
  WHERE geom IS NOT NULL
    AND ST_Intersects(geom, p_bbox);
$$;
COMMENT ON FUNCTION public.routes_intersecting_bbox(geometry) IS
  'Rutas cuya geometría intersecta el bbox. RLS del caller filtra qué rutas son visibles.';
GRANT EXECUTE ON FUNCTION public.routes_intersecting_bbox(geometry) TO anon, authenticated;

-- =============================================================
-- 7. cast_suggestion_vote(p_suggestion_id)
-- =============================================================
-- Inserta el voto del caller en route_suggestion_votes (si aún no
-- existe), recalcula el total y lo persiste en
-- route_suggestions.votes. Devuelve el nuevo total.

CREATE OR REPLACE FUNCTION public.cast_suggestion_vote(p_suggestion_id UUID)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID;
  v_total INT;
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Authentication required to vote'
      USING ERRCODE = '28000';
  END IF;

  IF NOT EXISTS (SELECT 1 FROM route_suggestions WHERE id = p_suggestion_id) THEN
    RAISE EXCEPTION 'Suggestion not found: %', p_suggestion_id
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO route_suggestion_votes (suggestion_id, voter_id)
    VALUES (p_suggestion_id, v_user_id)
    ON CONFLICT (suggestion_id, voter_id) DO NOTHING;

  SELECT count(*)::INT INTO v_total
    FROM route_suggestion_votes
    WHERE suggestion_id = p_suggestion_id;

  UPDATE route_suggestions SET votes = v_total WHERE id = p_suggestion_id;

  RETURN v_total;
END;
$$;
COMMENT ON FUNCTION public.cast_suggestion_vote(UUID) IS
  'Vota una sugerencia (idempotente por usuario). Recalcula total y devuelve el nuevo conteo.';
GRANT EXECUTE ON FUNCTION public.cast_suggestion_vote(UUID) TO authenticated;

-- =============================================================
-- Fin de 005_functions.sql
-- =============================================================
