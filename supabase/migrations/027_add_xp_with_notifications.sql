-- 027_add_xp_with_notifications.sql — add_xp() ahora notifica
-- Reescribe add_xp para que tras actualizar el score:
--   1) Inserte una notificación 'xp_earned' (solo si delta > 0).
--   2) Si el nivel sube, inserte 'rank_up'.
-- Se hace en una migración separada porque ALTER TYPE ADD VALUE
-- (026) no puede usarse en la misma transacción que un INSERT con
-- ese nuevo enum value.

CREATE OR REPLACE FUNCTION add_xp(p_user_id UUID, p_xp INT) RETURNS VOID AS $$
DECLARE
  new_score INT;
  new_level INT;
  old_level INT;
BEGIN
  SELECT reputation_level INTO old_level
    FROM profiles WHERE id = p_user_id;

  UPDATE profiles SET reputation_score = reputation_score + p_xp
    WHERE id = p_user_id
    RETURNING reputation_score INTO new_score;

  new_level := CASE
    WHEN new_score >= 5000 THEN 6
    WHEN new_score >= 1500 THEN 5
    WHEN new_score >= 500  THEN 4
    WHEN new_score >= 200  THEN 3
    WHEN new_score >= 50   THEN 2
    WHEN new_score >= 10   THEN 1
    ELSE 0
  END;

  UPDATE profiles SET reputation_level = new_level WHERE id = p_user_id;

  -- Notificación in-app por XP ganado (solo subidas, no bajadas).
  IF p_xp > 0 THEN
    INSERT INTO notifications (user_id, type, payload)
    VALUES (
      p_user_id,
      'xp_earned',
      jsonb_build_object(
        'delta', p_xp,
        'new_score', new_score
      )
    );
  END IF;

  -- Notificación in-app si el rango sube.
  IF new_level > COALESCE(old_level, 0) THEN
    INSERT INTO notifications (user_id, type, payload)
    VALUES (
      p_user_id,
      'rank_up',
      jsonb_build_object(
        'old_level', COALESCE(old_level, 0),
        'new_level', new_level,
        'score', new_score
      )
    );
  END IF;
END;
$$ LANGUAGE plpgsql;
