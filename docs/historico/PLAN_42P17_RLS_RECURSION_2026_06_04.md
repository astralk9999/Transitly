# Plan de acción — Error 42P17 "infinite recursion" en RLS de `route_shares`

**Fecha:** 2026-06-04
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Goal:** Eliminar la recursión infinita en una RLS policy de `route_shares` que está bloqueando `getMyStats()` en el perfil del usuario tras hacer login.
**Severidad:** Alta — bloquea la sección de contribuciones del perfil para todos los usuarios autenticados.
**Stack:** PostgreSQL 15 (Supabase), Row Level Security (RLS).

---

## 1. Diagnóstico (qué dice el error)

Log capturado tras login con Google:
```
[WARN][Contributions] getMyStats failed
PostgrestException(
  message: infinite recursion detected in policy for relation "route_shares",
  code: 42P17,
  details: Internal Server Error,
  hint: null
)
```

**Código `42P17`** es el código estándar de PostgreSQL para `infinite_recursion`. PostgreSQL lo lanza cuando:
- Una política RLS de la tabla A consulta la tabla B, y
- La política RLS de la tabla B consulta de vuelta a la tabla A (directa o indirectamente).

PostgreSQL detecta el ciclo y aborta la query.

### Quién dispara la query

`lib/data/contributions/my_contributions_repository.dart` método `getMyStats()`. Hace 5 counts en paralelo:
- `incidents`
- `route_suggestions`
- `route_feedback`
- `feature_requests`
- `route_shares` ← **esta es la que recursa**

---

## 2. Hipótesis sobre la causa

Sin acceso al SQL actual de las policies, lo más probable es uno de estos patrones:

### Hipótesis A: policy de `route_shares` consulta `user_routes`

```sql
-- Hipotética policy actual con BUG:
CREATE POLICY "users see own shares" ON route_shares
FOR SELECT USING (
  shared_by_id = auth.uid()
  OR EXISTS (
    SELECT 1 FROM user_routes
    WHERE user_routes.id = route_shares.route_id
      AND user_routes.owner_id = auth.uid()
  )
);
```

Si la policy de `user_routes` también referencia `route_shares` (ej. "puedes ver una ruta si te la han compartido"), **ciclo cerrado** → recursión.

### Hipótesis B: policy se llama a sí misma

```sql
-- Hipotética policy actual con BUG:
CREATE POLICY "complex visibility" ON route_shares
FOR SELECT USING (
  EXISTS (SELECT 1 FROM route_shares rs2 WHERE rs2.route_id = route_shares.route_id)
);
```

Self-reference directa → recursión inmediata.

### Hipótesis C: cascada via `user_route_stops` → `user_routes` → `route_shares`

Si las 3 tablas se referencian entre sí en policies, PostgreSQL detecta el ciclo aunque no sea directo.

---

## 3. Plan de tareas

### Tarea A — Auditar policies actuales (5 min)

**Goal:** ver el SQL exacto antes de tocar nada.

**Acción manual en Supabase Dashboard → SQL Editor:**

```sql
SELECT
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE tablename IN ('route_shares', 'user_routes', 'user_route_stops')
ORDER BY tablename, policyname;
```

Esto devuelve todas las policies activas en las 3 tablas relacionadas.

**Output esperado:** filas con `qual` (la cláusula `USING (...)` ) y `with_check` (`WITH CHECK (...)`). Identificar cuál hace `SELECT FROM` a otra tabla.

---

### Tarea B — Identificar el ciclo (5 min)

**Goal:** marcar qué policy es la culpable.

**Steps:**
1. Listar mentalmente: ¿`route_shares` policy → consulta `X`?
2. Si `X = user_routes`: ¿la policy de `user_routes` consulta `route_shares`? → ciclo.
3. Si `X = route_shares` (self-ref): bug claro.
4. Si `X = user_route_stops`: ¿esa consulta route_shares? → ciclo extendido.

Documentar el ciclo en una línea: `route_shares → user_routes → route_shares` (o el camino que sea).

---

### Tarea C — Reescribir la policy SIN recursión (15 min)

**Goal:** policy que NO consulta otras tablas que a su vez consultan `route_shares`.

#### Opción 1 — Policy simple (recomendada, sin joins)

Si la lógica original era "ver mis shares + shares de rutas que poseo", separar en 2 policies independientes:

```sql
DROP POLICY IF EXISTS "users see own shares" ON route_shares;

-- Policy 1: ver shares que YO creé.
CREATE POLICY "users see shares they created"
ON route_shares
FOR SELECT
USING (shared_by_id = auth.uid());

-- Policy 2: ver shares de rutas que yo poseo, usando un campo
-- desnormalizado para evitar JOIN.
-- (Requiere añadir columna `owner_id` cacheada en route_shares,
-- ver Opción 2 si no quieres desnormalizar.)
```

**Pros**: zero joins, performance óptima.
**Contras**: requiere mantener `owner_id` sincronizado (trigger en INSERT/UPDATE).

#### Opción 2 — SECURITY DEFINER function (sin tocar schema)

```sql
DROP POLICY IF EXISTS "users see own shares" ON route_shares;

-- Función auxiliar que bypassa RLS para hacer el join.
CREATE OR REPLACE FUNCTION public.is_route_owner(p_route_id uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM user_routes
    WHERE id = p_route_id AND owner_id = auth.uid()
  );
$$;

GRANT EXECUTE ON FUNCTION public.is_route_owner TO authenticated;

-- Policy que usa la función. SECURITY DEFINER bypassa RLS,
-- por tanto NO recursa.
CREATE POLICY "users see own shares"
ON route_shares
FOR SELECT
USING (
  shared_by_id = auth.uid()
  OR public.is_route_owner(route_id)
);
```

**Pros**: mantiene la lógica original, no tocas el schema.
**Contras**: `SECURITY DEFINER` ejecuta con permisos de owner — auditar que solo lea, nunca escriba.

**Recomendación:** **Opción 2** si la lógica de visibilidad es compleja; **Opción 1** si solo necesitas `shared_by_id = auth.uid()`.

---

### Tarea D — Verificar con query directa (5 min)

**Goal:** confirmar que ya no recursa.

**SQL Editor de Supabase:**

```sql
-- Simular el count que hace getMyStats. Reemplazar con tu user_id real.
SELECT count(*)
FROM route_shares
WHERE shared_by_id = '<tu-user-id>';
```

**Esperado:** un número (0 o más). Si vuelve a salir `42P17`, hay otra policy recursiva.

Si pasa OK, también probar el `count(*) FROM route_shares` general (admin view) para asegurar.

---

### Tarea E — Re-test en la app (2 min)

**Goal:** verificar que `getMyStats()` ya no falla.

**Steps:**
1. Build / reinstalar **NO necesario** — el fix es server-side.
2. Pull-to-refresh en la app o reabrir sesión.
3. Ir a Perfil → sección "Mis contribuciones".
4. Verificar que se ven los counts (0 o más, no spinner permanente).
5. Capturar `adb logcat` y confirmar NO más `[WARN][Contributions] getMyStats failed`.

---

### Tarea F — Documentar el cambio (5 min)

**Goal:** registro para el equipo / futuros agents.

**Archivos:**
- New section en `docs/SUPABASE_SETUP.md`

**Steps:**
- [ ] Añadir al final de `SUPABASE_SETUP.md`:

```markdown
## RLS Policies — gotchas conocidos

### route_shares — recursión 42P17 (2026-06-04)

Síntoma: `PostgrestException: infinite recursion detected in policy for relation "route_shares"`.

Causa: policy de `route_shares` consultaba `user_routes`, cuya policy consultaba de vuelta a `route_shares` → ciclo.

Fix aplicado: <Opción 1 / Opción 2> — ver migrations `20260604_fix_route_shares_rls.sql`.

Si vuelve a aparecer:
1. `SELECT * FROM pg_policies WHERE tablename = 'route_shares';`
2. Buscar JOINs con tablas cuyas policies también consulten `route_shares`.
3. Aislar con `SECURITY DEFINER` function o separar en policies independientes.
```

---

## 4. Estimación de tiempo

| Tarea | Tiempo | Tipo |
|-------|--------|------|
| A — Auditar policies | 5 min | SQL read-only |
| B — Identificar ciclo | 5 min | Análisis |
| C — Reescribir policy | 15 min | SQL DDL |
| D — Verificar query | 5 min | SQL read-only |
| E — Re-test app | 2 min | Manual |
| F — Documentar | 5 min | Doc |
| **Total** | **~40 min** | Todo manual |

---

## 5. Orden de ejecución

1. **A** primero (audit). Sin esto, las hipótesis son ciegas.
2. **B** inmediato tras ver el output.
3. **C** una vez identificado el ciclo. **Hacer backup del policy SQL viejo** antes de DROP (copiar `qual` y `with_check` a un comentario).
4. **D** confirmar fix sin tocar la app.
5. **E** verificar usuario final.
6. **F** registro.

---

## 6. Decisiones tomadas

| # | Decisión | Razón |
|---|----------|-------|
| D1 | **Opción 2 (SECURITY DEFINER)** recomendada como default | Mantiene lógica original, no requiere migración de datos |
| D2 | Auditar las 3 tablas relacionadas, no solo `route_shares` | El ciclo puede ir por `user_routes` o `user_route_stops` |
| D3 | NO tocar la app, fix 100% server-side | El código Dart ya está OK |
| D4 | Backup del SQL viejo en comentario antes de DROP | Para rollback rápido si la nueva policy es muy restrictiva |
| D5 | Documentar en `SUPABASE_SETUP.md` | Próximo agente sabrá qué buscar si vuelve a pasar |

---

## 7. Riesgos

- **R1: La nueva policy puede ser MÁS restrictiva** que la vieja → algún usuario pierde acceso a shares que sí debía ver. **Mitigación:** test con 2+ cuentas (creador del share + receptor).
- **R2: `SECURITY DEFINER` ejecuta con permisos de owner** — si la función hace algo más que SELECT, expone superprivilegio. **Mitigación:** la función propuesta es SOLO `SELECT EXISTS (...)`, sin INSERT/UPDATE/DELETE.
- **R3: Si hay otras policies recursivas en `user_routes` o `user_route_stops`**, el fix de `route_shares` no las arregla. **Mitigación:** la query de Tarea D simula el flujo real, si falla ahí entonces hay otra policy que arreglar.
- **R4: El ciclo puede estar en INSERT/UPDATE policies, no SELECT.** Mientras la app no haga writes a `route_shares` el bug no se nota, pero al escribir reaparece. **Mitigación:** mirar también `cmd != 'r'` en el output de Tarea A.

---

## 8. Criterios de aceptación

1. Query `SELECT count(*) FROM route_shares WHERE shared_by_id = '<uid>'` en SQL Editor: devuelve número sin error.
2. Perfil de la app: sección "Mis contribuciones" muestra los 5 counts (incidents, suggestions, feedback, features, shares).
3. `adb logcat`: cero líneas `[WARN][Contributions] getMyStats failed`.
4. Crear un nuevo share (manual o via app) → se inserta correctamente, sigue siendo visible para el creador.

---

## 9. Próximos pasos

Cuando arranques:
1. Abre https://supabase.com/dashboard/project/mmzahxtiaurkgtmtehxk/sql/new
2. Pega la query de Tarea A.
3. Comparte conmigo el output (las policies de las 3 tablas).
4. Yo te genero el SQL exacto para Tarea C según lo que vea.

Alternativamente, si prefieres atajar:
- **Aplicar Opción 1 ciegamente** (~5 min): policy mínima que solo muestra shares creados por uno mismo. Si la app no necesita "ver shares de tus rutas", esto resuelve YA.
- **Aplicar Opción 2 ciegamente** (~10 min): si necesitas la lógica completa, con `SECURITY DEFINER`.

Recomiendo **auditar primero (Tarea A)** porque toca políticas críticas de seguridad y prefiero ver el SQL antes que ir a ciegas.

---

## Changelog

- **2026-06-04** — Plan creado tras descubrir el error 42P17 en logs post-login. Causa: recursión en RLS de `route_shares`. Fix 100% server-side (Supabase Dashboard SQL). 2 opciones de fix con trade-offs documentados.
