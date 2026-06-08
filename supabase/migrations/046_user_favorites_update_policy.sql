-- 046_user_favorites_update_policy.sql
-- user_favorites tenía políticas INSERT/SELECT/DELETE pero NO UPDATE. El
-- cliente usa .upsert(onConflict:'user_id,kind,entity_id'), que genera
-- INSERT ... ON CONFLICT DO UPDATE; sin política UPDATE, RLS rechaza ese
-- UPDATE con "new row violates row-level security policy" y la sincronización
-- de favoritos (líneas y paradas, oficiales y de comunidad) fallaba en silencio
-- (solo persistían en Hive local).
--
-- Aplicada vía MCP (apply_migration); este archivo es el consolidado del repo.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname='public' AND tablename='user_favorites'
      AND policyname='Owner updates own favorites'
  ) THEN
    CREATE POLICY "Owner updates own favorites"
      ON public.user_favorites
      FOR UPDATE
      USING (auth.uid() = user_id)
      WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;
