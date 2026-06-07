-- 035_user_routes_code.sql — código de línea opcional en rutas de comunidad.
-- Paridad con el editor de admin: el wizard de comunidad ahora permite
-- fijar un código de línea (p.ej. "L1") y una zona (columna region).
ALTER TABLE user_routes ADD COLUMN IF NOT EXISTS code TEXT;
