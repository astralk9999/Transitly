-- 031_geo_alerts_routes.sql — rutas afectadas en geo_alerts
--
-- El aviso geo ahora puede asociarse a una lista de rutas (códigos
-- del mock o UUID de user_routes). Vacío = aplica a todas.

ALTER TABLE geo_alerts
  ADD COLUMN IF NOT EXISTS affected_route_ids text[] NOT NULL DEFAULT '{}';

CREATE INDEX IF NOT EXISTS geo_alerts_routes_gin_idx
  ON geo_alerts USING GIN (affected_route_ids);
