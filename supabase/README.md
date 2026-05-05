# Supabase — esquema e infraestructura

Toda la base de datos de Transitly vive aquí. Cada migración numerada
en `migrations/` es **incremental** y se aplica en orden (CLI o
Dashboard). El proyecto remoto al que apuntan estos archivos es
`mmzahxtiaurkgtmtehxk` (`https://mmzahxtiaurkgtmtehxk.supabase.co`).

## Aplicar migraciones

### Opción A — Supabase CLI (recomendada)

```bash
# Una sola vez por máquina:
npm install -g supabase
supabase login

# Una sola vez por checkout del repo:
supabase link --project-ref mmzahxtiaurkgtmtehxk

# Cada vez que añadas una migración nueva:
supabase db push
```

`supabase db push` aplica todas las migraciones en `migrations/` que
aún no estén registradas en `supabase_migrations.schema_migrations`
del proyecto remoto. Es **idempotente** una vez aplicada cada
migración.

### Opción B — SQL Editor del Dashboard

1. Abre <https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/sql/new>.
2. Copia/pega el contenido entero del archivo `migrations/00X_*.sql`.
3. Pulsa **Run**.

Aplica las migraciones en orden numérico (`001_*` → `002_*` → …).
La primera puede tardar 30-60s por las extensiones PostGIS y los
índices GIST.

## Verificar tras aplicar `001_init.sql`

```sql
-- Debe devolver 23 (número de tablas creadas en public).
SELECT count(*) FROM pg_tables WHERE schemaname = 'public';

-- Debe devolver 17 (enums creados).
SELECT count(*) FROM pg_type
WHERE typcategory = 'E' AND typnamespace = 'public'::regnamespace;

-- Debe devolver al menos 'postgis' y 'pgcrypto'.
SELECT extname FROM pg_extension WHERE extname IN ('postgis', 'pgcrypto');

-- Sanity: el trigger de auto-creación de profile debe existir.
SELECT tgname FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

## Notas operativas

- Las migraciones SOLO contienen DDL. Los datos (seeds, fixtures) van
  aparte en F8 (importador GTFS) o vía Edge Functions.
- RLS se habilita en `002_rls.sql` (F2.3). Hasta entonces, el schema
  no tiene políticas — consultar **solo** desde `service_role` o
  conexiones administrativas; el cliente con `anon` no podrá leer
  nada hasta que F2.3 expanda la matriz de permisos.
- `pg_cron` no se habilita en esta migración. Si el plan del proyecto
  lo soporta, programar `cleanup_expired_bus_positions()` cada hora
  cuando F2.5 instale las funciones SQL helpers.
