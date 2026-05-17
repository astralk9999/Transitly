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
-- Debe devolver 26 (25 tablas de la migración + `spatial_ref_sys`
-- que PostGIS instala automáticamente en public).
SELECT count(*) FROM pg_tables WHERE schemaname = 'public';

-- Debe devolver 17 (enums creados).
SELECT count(*) FROM pg_type
WHERE typcategory = 'E' AND typnamespace = 'public'::regnamespace;

-- Debe devolver 'postgis' y 'pgcrypto'.
SELECT extname FROM pg_extension WHERE extname IN ('postgis', 'pgcrypto');

-- Sanity: el trigger de auto-creación de profile debe existir.
SELECT tgname FROM pg_trigger WHERE tgname = 'on_auth_user_created';

-- Helper functions (handle_new_user, touch_updated_at, cleanup_expired_bus_positions).
SELECT count(*) FROM pg_proc
WHERE proname IN ('handle_new_user','touch_updated_at','cleanup_expired_bus_positions')
  AND pronamespace = 'public'::regnamespace;  -- esperado: 3
```

## Configuración de Edge Functions y triggers (endurecimiento P1)

Tras el endurecimiento de seguridad, hay configuración **obligatoria** sin
la cual algunas funciones degradan a propósito (no fallan ruidosamente):

- **`functions_url`** (Vault `functions_url` o `app.settings.functions_url`):
  base URL de las Edge Functions, p. ej.
  `https://<project-ref>.supabase.co/functions/v1`. Sin esto,
  `invoke_send_notification` (migración `015`) **no envía push** y registra
  un `WARNING` (ya no hay project-ref hardcodeada). Ejemplo:
  ```sql
  ALTER DATABASE postgres SET app.settings.functions_url =
    'https://<project-ref>.supabase.co/functions/v1';
  ```
- **`service_role_key`** (Vault o `app.settings.service_role_key`): ya
  requerido previamente por `invoke_send_notification`.
- **Edge `send_notification`** exige `Authorization: Bearer <service_role>`
  (lo aporta el trigger). Llamadas externas con `anon` → `403`. Aplica
  rate-limit de 20 notificaciones/usuario/min.
- **Edge `import_gtfs`**: CORS por allowlist en la env var
  `ALLOWED_ORIGINS` (lista separada por comas, **sin wildcard**). Origen no
  listado → sin cabecera CORS (el navegador lo bloquea). Opcional:
  `GTFS_ALLOWED_HOSTS` restringe los hosts de `gtfsUrl` (anti-SSRF; además
  se bloquean loopback/rangos privados y se exige https).

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
