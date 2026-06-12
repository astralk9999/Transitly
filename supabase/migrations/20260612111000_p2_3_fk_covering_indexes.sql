-- P2.3 (plan post-TFG): lint unindexed_foreign_keys (×49). Crea un índice
-- btree para cada FK de una sola columna de public que no tenga ya un índice
-- cuyo primer término sea esa columna. Sin FK indexada, cada DELETE/UPDATE
-- en la tabla referenciada escanea secuencialmente la tabla hija (y los
-- joins por FK no pueden usar index scan).
--
-- Programático e idempotente; nombre: <tabla>_<columna>_fk_idx.

DO $$
DECLARE
  fk record;
BEGIN
  FOR fk IN
    SELECT c.conrelid::regclass AS tbl,
           a.attname AS col,
           c.conrelid::regclass::text || '_' || a.attname || '_fk_idx' AS idx_name
    FROM pg_constraint c
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
    WHERE c.contype = 'f'
      AND c.connamespace = 'public'::regnamespace
      AND array_length(c.conkey, 1) = 1
      AND NOT EXISTS (
        SELECT 1 FROM pg_index i
        WHERE i.indrelid = c.conrelid
          AND i.indkey[0] = c.conkey[1]
      )
  LOOP
    EXECUTE format('CREATE INDEX IF NOT EXISTS %I ON %s (%I)',
                   replace(fk.idx_name, '"', ''), fk.tbl, fk.col);
    RAISE NOTICE 'fk index: % (%)', fk.idx_name, fk.tbl;
  END LOOP;
END $$;
