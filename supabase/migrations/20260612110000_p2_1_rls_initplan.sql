-- P2.1 (plan post-TFG): lint auth_rls_initplan (×86). Las policies usaban
-- auth.uid()/auth.role()/auth.jwt() desnudos y PostgreSQL los re-evalúa por
-- fila; envueltos en (SELECT ...) se evalúan una vez por consulta (InitPlan).
--
-- Reescritura programática: misma semántica, solo cambia el coste. Se
-- excluyen los campos ya envueltos (idempotente). Cubre public y storage.

DO $$
DECLARE
  pol record;
  stmt text;
BEGIN
  FOR pol IN
    SELECT p.schemaname, p.tablename, p.policyname, p.cmd, p.qual, p.with_check,
      (coalesce(p.qual, '') LIKE '%auth.uid()%'
        AND p.qual NOT LIKE '%( SELECT auth.uid() AS uid)%') AS rewrite_qual,
      (coalesce(p.with_check, '') LIKE '%auth.uid()%'
        AND p.with_check NOT LIKE '%( SELECT auth.uid() AS uid)%') AS rewrite_check
    FROM pg_policies p
    WHERE p.schemaname IN ('public', 'storage')
  LOOP
    IF NOT (pol.rewrite_qual OR pol.rewrite_check) THEN
      CONTINUE;
    END IF;

    stmt := format('ALTER POLICY %I ON %I.%I',
                   pol.policyname, pol.schemaname, pol.tablename);
    IF pol.cmd <> 'INSERT' AND pol.qual IS NOT NULL THEN
      stmt := stmt || format(' USING (%s)',
        CASE WHEN pol.rewrite_qual
          THEN replace(pol.qual, 'auth.uid()', '(SELECT auth.uid())')
          ELSE pol.qual END);
    END IF;
    IF pol.with_check IS NOT NULL THEN
      stmt := stmt || format(' WITH CHECK (%s)',
        CASE WHEN pol.rewrite_check
          THEN replace(pol.with_check, 'auth.uid()', '(SELECT auth.uid())')
          ELSE pol.with_check END);
    END IF;

    EXECUTE stmt;
    RAISE NOTICE 'initplan fix: %.% / %', pol.schemaname, pol.tablename, pol.policyname;
  END LOOP;
END $$;
