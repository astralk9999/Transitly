# Supabase Storage — buckets de Transitly

Todo el setup vive en `migrations/004_storage.sql`. Esta página
documenta los buckets, sus límites y los caminos esperados para que
quien escriba código de subida no tenga que leer SQL.

## Resumen de buckets

| Bucket | Visibilidad | Tamaño máx | MIME types |
|--------|-------------|-----------:|------------|
| `avatars` | público | 2 MB | image/png, image/jpeg, image/webp, image/gif |
| `report-attachments` | privado | 5 MB | image/png, image/jpeg, image/webp, image/heic, video/mp4 |
| `route-attachments` | privado | 5 MB | image/png, image/jpeg, image/webp, application/json, application/geo+json |
| `data-exports` | privado | 100 MB | application/zip, application/json |
| `operator-assets` | público | 5 MB | image/png, image/jpeg, image/webp, image/svg+xml |

**Bytes exactos:** 2 097 152 / 5 242 880 / 5 242 880 / 104 857 600 / 5 242 880.

## Convención de paths

Los buckets privados usan el prefijo `<auth.uid()>` como **primer
segmento del path**. Las policies validan ownership con
`(storage.foldername(name))[1] = auth.uid()::text`, por lo que esa
convención **no es opcional**: una subida fuera de `<uid>/...` es
rechazada por RLS.

| Bucket | Patrón sugerido | Ejemplo |
|--------|-----------------|---------|
| `avatars` | `<uid>/<filename>` | `a1b2.../avatar.png` |
| `report-attachments` | `<uid>/incident-<id>/<filename>` | `a1b2.../incident-42/photo1.jpg` |
| `route-attachments` | `<uid>/route-<id>/<filename>` | `a1b2.../route-L1/trace.json` |
| `data-exports` | `<uid>/<export_id>.zip` | `a1b2.../export-2026-05-06.zip` |
| `operator-assets` | `<operator_id_uuid>/<filename>` | `<uuid>/logo.svg` |

## Matriz de permisos

### Buckets privados — `report-attachments`, `route-attachments`

| Operación | Anon | Authenticated (dueño) | Mod/Admin |
|-----------|:----:|:---------------------:|:---------:|
| SELECT | ❌ | ✅ (su path) | ✅ |
| INSERT | ❌ | ✅ (su path) | — |
| UPDATE | ❌ | ❌ | ❌ |
| DELETE | ❌ | ✅ (su path) | ✅ admin |

### Bucket `data-exports`

| Operación | Anon | Authenticated (dueño) | Admin | Service role |
|-----------|:----:|:---------------------:|:-----:|:------------:|
| SELECT | ❌ | ✅ | ✅ | ✅ |
| INSERT | ❌ | ❌ | ❌ | ✅ (Edge Functions) |
| UPDATE | ❌ | ❌ | ❌ | ✅ |
| DELETE | ❌ | ✅ | ❌ | ✅ |

### Bucket público `avatars`

| Operación | Anon | Authenticated (dueño) | Admin |
|-----------|:----:|:---------------------:|:-----:|
| SELECT | ✅ | ✅ | ✅ |
| INSERT/UPDATE/DELETE | ❌ | ✅ (su path) | ✅ todo |

### Bucket público `operator-assets`

| Operación | Anon | Authenticated | operator_admin (de su operador) | Admin |
|-----------|:----:|:-------------:|:-------------------------------:|:-----:|
| SELECT | ✅ | ✅ | ✅ | ✅ |
| INSERT/UPDATE/DELETE | ❌ | ❌ | ✅ (su operador) | ✅ todo |

`operator_admin` está validado cruzando el primer segmento del path
(UUID del operador) con `is_operator_admin_of()`.

## Aplicar la migración

### Opción A — MCP / SQL Editor

```sql
\i migrations/004_storage.sql
```

O pega el contenido entero en
<https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/sql/new>
y pulsa **Run**.

### Opción B — Supabase CLI

```bash
supabase db push
```

Aplica todas las migraciones pendientes en `supabase/migrations/` que
no estén en `supabase_migrations.schema_migrations`.

## Verificar tras aplicar

```sql
-- Debe devolver 5 filas con los specs de la tabla anterior.
SELECT id, public, file_size_limit, allowed_mime_types
FROM storage.buckets ORDER BY id;

-- Debe devolver 22 (5 + 5 + 5 + 3 + 4 policies).
SELECT count(*) FROM pg_policies
WHERE schemaname = 'storage' AND tablename = 'objects';
```

## Subida desde el cliente Flutter

```dart
final supabase = ref.read(supabaseClientProvider);
final user = supabase.auth.currentUser;
if (user == null) throw StateError('No session');

final path = '${user.id}/incident-$incidentId/photo1.jpg';
await supabase.storage
    .from('report-attachments')
    .uploadBinary(path, bytes, fileOptions: const FileOptions(
      contentType: 'image/jpeg',
      upsert: false,
    ));
```

Para buckets públicos (`avatars`, `operator-assets`) usar
`getPublicUrl(path)` para obtener la URL servible. Para buckets
privados usar `createSignedUrl(path, expiresIn: 3600)`.
