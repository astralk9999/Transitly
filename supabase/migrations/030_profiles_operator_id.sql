-- 030_profiles_operator_id.sql — asignación operadora ↔ usuario
--
-- driver y operatorAdmin necesitan ir asociados a una operadora.
-- Añadimos operator_id a profiles para la asociación directa.
-- driver_assignments sigue existiendo para histórico/auditoría.

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS operator_id UUID REFERENCES operators(id);

CREATE INDEX IF NOT EXISTS profiles_operator_idx ON profiles(operator_id)
  WHERE operator_id IS NOT NULL;
