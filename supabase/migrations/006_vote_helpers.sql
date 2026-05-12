-- =============================================================
-- 006_vote_helpers.sql — RPC simétrica para FeatureRequest votes
-- =============================================================
-- Completa F2.5: la función `cast_suggestion_vote` existe desde
-- 005_functions.sql pero su equivalente para feature_requests faltaba.
-- Mismo patrón: idempotente por usuario, recalcula y persiste el
-- total, devuelve el nuevo conteo.

CREATE OR REPLACE FUNCTION public.cast_feature_request_vote(p_request_id UUID)
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

  IF NOT EXISTS (SELECT 1 FROM feature_requests WHERE id = p_request_id) THEN
    RAISE EXCEPTION 'Feature request not found: %', p_request_id
      USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO feature_request_votes (request_id, voter_id)
    VALUES (p_request_id, v_user_id)
    ON CONFLICT (request_id, voter_id) DO NOTHING;

  SELECT count(*)::INT INTO v_total
    FROM feature_request_votes
    WHERE request_id = p_request_id;

  UPDATE feature_requests SET votes = v_total WHERE id = p_request_id;

  RETURN v_total;
END;
$$;
COMMENT ON FUNCTION public.cast_feature_request_vote(UUID) IS
  'Vota un feature request (idempotente por usuario). Recalcula total y devuelve el nuevo conteo.';
GRANT EXECUTE ON FUNCTION public.cast_feature_request_vote(UUID) TO authenticated;
