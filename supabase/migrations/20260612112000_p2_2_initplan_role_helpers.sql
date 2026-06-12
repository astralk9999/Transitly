-- P2.2 (plan post-TFG): lint multiple_permissive_policies (×54).
--
-- Decisión: NO se fusionan las policies por rol (admin / op_admin / owner)
-- en una sola con ORs — los nombres separados son autodocumentados y el
-- riesgo de deriva semántica al fusionar 28 combinaciones a mano supera la
-- ganancia. El coste real por fila era la llamada a is_admin() /
-- is_moderator_or_admin() (EXISTS sobre profiles); envueltas en (SELECT ...)
-- pasan a InitPlan y se evalúan una vez por consulta. is_route_owner(id) y
-- similares con argumento de fila no se pueden envolver (dependen de la fila).

DO $$
DECLARE
  pol record;
  stmt text;
  q text;
  wc text;
BEGIN
  FOR pol IN
    SELECT p.schemaname, p.tablename, p.policyname, p.cmd, p.qual, p.with_check
    FROM pg_policies p
    WHERE p.schemaname = 'public'
      AND (
        (coalesce(p.qual, '') ~ '(^|[^a-z_])is_admin\(\)'
          AND p.qual NOT LIKE '%SELECT is_admin()%')
        OR (coalesce(p.qual, '') ~ '(^|[^a-z_])is_moderator_or_admin\(\)'
          AND p.qual NOT LIKE '%SELECT is_moderator_or_admin()%')
        OR (coalesce(p.with_check, '') ~ '(^|[^a-z_])is_admin\(\)'
          AND p.with_check NOT LIKE '%SELECT is_admin()%')
        OR (coalesce(p.with_check, '') ~ '(^|[^a-z_])is_moderator_or_admin\(\)'
          AND p.with_check NOT LIKE '%SELECT is_moderator_or_admin()%')
      )
  LOOP
    q := pol.qual;
    wc := pol.with_check;
    IF q IS NOT NULL AND q NOT LIKE '%SELECT is_admin()%' THEN
      q := regexp_replace(q, '(^|[^a-z_])is_admin\(\)', '\1(SELECT is_admin())', 'g');
    END IF;
    IF q IS NOT NULL AND q NOT LIKE '%SELECT is_moderator_or_admin()%' THEN
      q := regexp_replace(q, '(^|[^a-z_])is_moderator_or_admin\(\)', '\1(SELECT is_moderator_or_admin())', 'g');
    END IF;
    IF wc IS NOT NULL AND wc NOT LIKE '%SELECT is_admin()%' THEN
      wc := regexp_replace(wc, '(^|[^a-z_])is_admin\(\)', '\1(SELECT is_admin())', 'g');
    END IF;
    IF wc IS NOT NULL AND wc NOT LIKE '%SELECT is_moderator_or_admin()%' THEN
      wc := regexp_replace(wc, '(^|[^a-z_])is_moderator_or_admin\(\)', '\1(SELECT is_moderator_or_admin())', 'g');
    END IF;

    stmt := format('ALTER POLICY %I ON %I.%I',
                   pol.policyname, pol.schemaname, pol.tablename);
    IF pol.cmd <> 'INSERT' AND q IS NOT NULL THEN
      stmt := stmt || format(' USING (%s)', q);
    END IF;
    IF wc IS NOT NULL THEN
      stmt := stmt || format(' WITH CHECK (%s)', wc);
    END IF;

    EXECUTE stmt;
    RAISE NOTICE 'role-helper initplan: %.% / %', pol.schemaname, pol.tablename, pol.policyname;
  END LOOP;
END $$;
