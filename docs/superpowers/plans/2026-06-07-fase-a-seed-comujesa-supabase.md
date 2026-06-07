# Fase A — Seed COMUJESA → Supabase (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Importar las 20 líneas de COMUJESA del asset `comujesa_data.json` a las tablas oficiales de Supabase (`routes`, `stops`, `route_stops`, `schedules`) de forma idempotente, para que dejen de "desaparecer" al iniciar sesión como admin y aparezcan en Gestión de líneas y en el mapa.

**Architecture:** Un generador Node (`tools/seed_comujesa.mjs`) lee el JSON y emite **un único archivo SQL idempotente** con UUIDs deterministas (v5). El SQL se aplica a Supabase (vía MCP `apply_migration` o el SQL Editor). Se verifica con consultas de conteo e idempotencia. Adicionalmente se corrige `tools/migrate_comujesa.dart` como vía re-ejecutable con service key.

**Tech Stack:** Node 20+ (ESM, `crypto` para UUID v5), PostgreSQL + PostGIS (Supabase), Dart (tool de migración).

**Spec:** `docs/superpowers/specs/2026-06-07-lineas-comujesa-supabase-horarios-offline-design.md` (Fase A).

---

## Hechos de la BD (verificados)

- `routes(id uuid PK, operator_id uuid, source route_source, status route_status, code text, name text NOT NULL, description text, color text, owner_id uuid, gtfs_route_id text, geom geometry, metadata jsonb NOT NULL, ...)`.
  - Único: `(operator_id, gtfs_route_id)`. Check: `source='official' ⇒ owner_id IS NULL AND operator_id IS NOT NULL`.
- `stops(id uuid PK, operator_id uuid, code text, name text NOT NULL, geom geometry NOT NULL, accessibility jsonb NOT NULL, gtfs_stop_id text, metadata jsonb NOT NULL, source stop_source, owner_id uuid)`.
  - Único: `(operator_id, gtfs_stop_id)`.
- `route_stops(route_id, stop_id, sequence int, direction smallint)` — **PK `(route_id, stop_id, direction, sequence)`**. FK route_id ON DELETE CASCADE.
- `schedules(id uuid PK, route_id uuid, day_type day_type, direction smallint, departure_time time, arrival_offsets jsonb, notes text)`.
- Enums: `route_source` {official, community}; `route_status` {official, draft, pendingVerification, verified, suspended}; `day_type` {weekday, saturday, sunday_holiday}.
- Operador COMUJESA: `id=00000000-0000-0000-0000-000000000001`, `slug=comujesa`.

## Mapeo JSON → BD

- **Identidad idempotente (UUID v5, namespace fijo `6ba7b810-9dad-11d1-80b4-00c04fd430c8`):**
  - route.id = `uuidv5("comujesa:route:" + code)`, `gtfs_route_id = code`.
  - stop.id = `uuidv5("comujesa:stop:" + key)` donde `key = officialCode` (si vacío: `slug(name)+":"+lat.toFixed(5)+","+lng.toFixed(5)`), `gtfs_stop_id = key`.
  - schedule.id = `uuidv5("comujesa:sched:" + code + ":" + dayType + ":0:" + departure)`.
- **routes:** `source='official'`, `status='official'`, `owner_id=NULL`, `color = line.color` (con `#`), `geom = ST_GeomFromText('LINESTRING(...)',4326)` con los puntos de `polyline.coordinates.lod4` (pares `[lng,lat]`); si no hay lod4 usar el LOD más alto disponible; si no hay polyline, `geom=NULL`. `metadata = {"active": true, "serviceType": line.serviceType, "polyline_lod": {lod0..lod3}}` (lod4 se reconstruye desde geom; se guardan solo lod0-3 para no duplicar).
- **stops (dedup por key):** `geom = ST_SetSRID(ST_MakePoint(lng,lat),4326)`, `accessibility = {"wheelchair": isAccessible, "shelter": hasShelter, "bench": hasBench}`, `code = officialCode`, `metadata = {"municipality": municipality}`, `source='official'`, `owner_id=NULL`.
- **route_stops:** por línea, `direction=0`, `sequence = order-1` (0-based, según `stop.order` del JSON). Idempotencia: `DELETE FROM route_stops WHERE route_id = <id>` y reinsertar.
- **schedules:** cabecera; una fila por hora de cada `day_type`, `direction=0`, `departure_time = "HH:MM"`, `arrival_offsets = NULL` (se rellena en Fase E).

---

## Task 1: Generador — esqueleto, lectura de JSON y conteos

**Files:**
- Create: `tools/seed_comujesa.mjs`
- Test: ejecución manual del script (sin framework; Node ESM)

- [ ] **Step 1: Escribir el generador con UUID v5 y conteos**

Crear `tools/seed_comujesa.mjs`:

```js
// tools/seed_comujesa.mjs
// Lee assets/mock/comujesa_data.json y emite un SQL idempotente para sembrar
// las líneas de COMUJESA en Supabase. UUIDs deterministas (v5) para re-ejecución.
//
// Uso:
//   node tools/seed_comujesa.mjs            -> escribe tools/seed_out/comujesa_seed.sql
//   node tools/seed_comujesa.mjs --counts   -> imprime conteos y sale (sin escribir)
import { createHash } from 'node:crypto';
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const OPERATOR_ID = '00000000-0000-0000-0000-000000000001';
const NS = '6ba7b810-9dad-11d1-80b4-00c04fd430c8'; // namespace v5 fijo

function uuidv5(name, namespace = NS) {
  const nsBytes = Buffer.from(namespace.replace(/-/g, ''), 'hex');
  const hash = createHash('sha1')
    .update(nsBytes)
    .update(Buffer.from(name, 'utf8'))
    .digest();
  const b = Buffer.from(hash.subarray(0, 16));
  b[6] = (b[6] & 0x0f) | 0x50; // versión 5
  b[8] = (b[8] & 0x3f) | 0x80; // variante RFC4122
  const h = b.toString('hex');
  return `${h.slice(0,8)}-${h.slice(8,12)}-${h.slice(12,16)}-${h.slice(16,20)}-${h.slice(20)}`;
}

function slug(s) {
  return (s || '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
}
function stopKey(st) {
  const oc = (st.officialCode || '').trim();
  if (oc) return oc;
  return `${slug(st.name)}:${Number(st.lat).toFixed(5)},${Number(st.lng).toFixed(5)}`;
}

const data = JSON.parse(readFileSync('assets/mock/comujesa_data.json', 'utf8'));
const lines = data.lines;

// Dedup de paradas por key
const stopsByKey = new Map();
for (const line of lines) {
  for (const st of (line.stops || [])) {
    const k = stopKey(st);
    if (!stopsByKey.has(k)) stopsByKey.set(k, st);
  }
}
let scheduleCount = 0, routeStopCount = 0;
for (const line of lines) {
  routeStopCount += (line.stops || []).length;
  for (const day of Object.keys(line.schedules || {})) {
    scheduleCount += (line.schedules[day] || []).length;
  }
}

if (process.argv.includes('--counts')) {
  console.log(JSON.stringify({
    routes: lines.length,
    stops: stopsByKey.size,
    route_stops: routeStopCount,
    schedules: scheduleCount,
  }));
  process.exit(0);
}

// (las siguientes tareas completan la emisión de SQL)
export { uuidv5, stopKey, slug, OPERATOR_ID, NS };
```

- [ ] **Step 2: Ejecutar conteos y verificar contra el JSON**

Run: `node tools/seed_comujesa.mjs --counts`
Expected (exacto, ya verificado del JSON): `routes` = 20, `route_stops` = 598, `schedules` = suma de todas las salidas; `stops` = nº de paradas únicas (> 0). Anota los valores para usarlos como asserts en Task 6.

- [ ] **Step 3: Commit**

```bash
git add tools/seed_comujesa.mjs
git commit -m "feat(seed): generador comujesa - esqueleto y conteos"
```

---

## Task 2: Generador — emitir UPSERT de `routes`

**Files:**
- Modify: `tools/seed_comujesa.mjs`

- [ ] **Step 1: Añadir construcción del LINESTRING y emisión de routes**

Reemplazar el bloque final `// (las siguientes tareas...)` por la lógica de emisión. Añadir helpers y el bloque de routes:

```js
const sqlEsc = (s) => s == null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`;
const jsonLit = (o) => `'${JSON.stringify(o).replace(/'/g, "''")}'::jsonb`;

function lodCoords(line) {
  const p = line.polyline;
  if (!p || !p.coordinates) return null;
  const c = p.coordinates;
  if (Array.isArray(c)) return { lod4: c, rest: {} };
  const rest = {};
  for (const k of ['lod0','lod1','lod2','lod3']) if (c[k]) rest[k] = c[k];
  const lod4 = c.lod4 || c.lod3 || c.lod2 || c.lod1 || c.lod0 || null;
  return { lod4, rest };
}
function lineStringSQL(coords) {
  if (!coords || coords.length < 2) return 'NULL';
  const pts = coords.map((p) => `${Number(p[0])} ${Number(p[1])}`).join(', ');
  return `ST_GeomFromText('LINESTRING(${pts})', 4326)`;
}

const out = [];
out.push('-- COMUJESA seed (idempotente). Generado por tools/seed_comujesa.mjs');
out.push('BEGIN;');

for (const line of lines) {
  const id = uuidv5(`comujesa:route:${line.code}`);
  const lod = lodCoords(line);
  const geom = lineStringSQL(lod && lod.lod4);
  const meta = { active: true, serviceType: line.serviceType || null, polyline_lod: (lod && lod.rest) || {} };
  const color = line.color ? (line.color.startsWith('#') ? line.color : `#${line.color}`) : null;
  out.push(
    `INSERT INTO routes (id, operator_id, source, status, code, name, color, owner_id, gtfs_route_id, geom, metadata) VALUES (` +
    `'${id}', '${OPERATOR_ID}', 'official', 'official', ${sqlEsc(line.code)}, ${sqlEsc(line.name)}, ${sqlEsc(color)}, NULL, ${sqlEsc(line.code)}, ${geom}, ${jsonLit(meta)}) ` +
    `ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, color=EXCLUDED.color, geom=EXCLUDED.geom, metadata=EXCLUDED.metadata, status=EXCLUDED.status, gtfs_route_id=EXCLUDED.gtfs_route_id, updated_at=now();`
  );
}
```

- [ ] **Step 2: Cerrar la transacción y escribir el archivo (provisional)**

Al final del script añadir:

```js
out.push('COMMIT;');
mkdirSync('tools/seed_out', { recursive: true });
writeFileSync('tools/seed_out/comujesa_seed.sql', out.join('\n') + '\n', 'utf8');
console.log(`SQL escrito: tools/seed_out/comujesa_seed.sql (${out.length} líneas)`);
```

- [ ] **Step 3: Generar y verificar routes**

Run: `node tools/seed_comujesa.mjs`
Run: `grep -c "INSERT INTO routes" tools/seed_out/comujesa_seed.sql`
Expected: `20`. Verifica a ojo que un `LINESTRING(...)` tiene pares `lng lat` plausibles para Jerez (~ `-6.1 36.6`).

- [ ] **Step 4: Commit**

```bash
git add tools/seed_comujesa.mjs tools/seed_out/comujesa_seed.sql
git commit -m "feat(seed): emitir upsert de routes con geom y metadata LOD"
```

---

## Task 3: Generador — emitir UPSERT de `stops`

**Files:**
- Modify: `tools/seed_comujesa.mjs`

- [ ] **Step 1: Emitir stops (dedup por key) antes del bloque de routes**

Las paradas deben insertarse **antes** que `route_stops` (FK). Insertar el bloque de stops **justo después de `out.push('BEGIN;')` y antes del bucle de routes** (orden: stops → routes → route_stops → schedules). Añadir:

```js
for (const [key, st] of stopsByKey) {
  const id = uuidv5(`comujesa:stop:${key}`);
  const acc = { wheelchair: !!st.isAccessible, shelter: !!st.hasShelter, bench: !!st.hasBench };
  const meta = { municipality: st.municipality || null };
  out.push(
    `INSERT INTO stops (id, operator_id, code, name, geom, accessibility, gtfs_stop_id, metadata, source, owner_id) VALUES (` +
    `'${id}', '${OPERATOR_ID}', ${sqlEsc(st.officialCode || null)}, ${sqlEsc(st.name)}, ` +
    `ST_SetSRID(ST_MakePoint(${Number(st.lng)}, ${Number(st.lat)}), 4326), ${jsonLit(acc)}, ${sqlEsc(key)}, ${jsonLit(meta)}, 'official', NULL) ` +
    `ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, geom=EXCLUDED.geom, accessibility=EXCLUDED.accessibility, code=EXCLUDED.code, metadata=EXCLUDED.metadata;`
  );
}
```

> Nota: si `stop_source` no incluye el valor `'official'`, sustituir por el valor por defecto de la columna (comprobar con `select enum_range(null::stop_source);`). Si la columna tiene default, omitir `source` del INSERT.

- [ ] **Step 2: Generar y verificar stops**

Run: `node tools/seed_comujesa.mjs`
Run: `grep -c "INSERT INTO stops" tools/seed_out/comujesa_seed.sql`
Expected: igual al conteo `stops` de Task 1 Step 2.

- [ ] **Step 3: Commit**

```bash
git add tools/seed_comujesa.mjs tools/seed_out/comujesa_seed.sql
git commit -m "feat(seed): emitir upsert de stops con geom point y accesibilidad"
```

---

## Task 4: Generador — emitir `route_stops` (delete+insert idempotente)

**Files:**
- Modify: `tools/seed_comujesa.mjs`

- [ ] **Step 1: Emitir route_stops tras el bloque de routes**

Añadir después del bucle de routes (las paradas y rutas ya existen):

```js
for (const line of lines) {
  const routeId = uuidv5(`comujesa:route:${line.code}`);
  out.push(`DELETE FROM route_stops WHERE route_id = '${routeId}' AND direction = 0;`);
  const seen = new Set();
  (line.stops || []).forEach((st, i) => {
    const stopId = uuidv5(`comujesa:stop:${stopKey(st)}`);
    const seq = Number.isInteger(st.order) ? st.order - 1 : i;
    const pk = `${stopId}:${seq}`;
    if (seen.has(pk)) return; // evita violar PK (route_id, stop_id, direction, sequence)
    seen.add(pk);
    out.push(
      `INSERT INTO route_stops (route_id, stop_id, sequence, direction) VALUES ('${routeId}', '${stopId}', ${seq}, 0) ON CONFLICT DO NOTHING;`
    );
  });
}
```

- [ ] **Step 2: Generar y verificar route_stops**

Run: `node tools/seed_comujesa.mjs`
Run: `grep -c "INSERT INTO route_stops" tools/seed_out/comujesa_seed.sql`
Expected: igual al conteo `route_stops` (598) de Task 1 (salvo duplicados dedup; si difiere, anota el delta y confírmalo en la verificación de BD de Task 6).

- [ ] **Step 3: Commit**

```bash
git add tools/seed_comujesa.mjs tools/seed_out/comujesa_seed.sql
git commit -m "feat(seed): emitir route_stops idempotentes (delete+insert)"
```

---

## Task 5: Generador — emitir `schedules` de cabecera

**Files:**
- Modify: `tools/seed_comujesa.mjs`

- [ ] **Step 1: Emitir schedules tras route_stops**

```js
const DAY_MAP = { weekday: 'weekday', saturday: 'saturday', sunday_holiday: 'sunday_holiday' };
for (const line of lines) {
  const routeId = uuidv5(`comujesa:route:${line.code}`);
  const sch = line.schedules || {};
  for (const day of Object.keys(sch)) {
    const dayType = DAY_MAP[day];
    if (!dayType) continue; // ignora claves no esperadas
    for (const t of (sch[day] || [])) {
      const id = uuidv5(`comujesa:sched:${line.code}:${dayType}:0:${t}`);
      out.push(
        `INSERT INTO schedules (id, route_id, day_type, direction, departure_time, arrival_offsets) VALUES (` +
        `'${id}', '${routeId}', '${dayType}', 0, '${t}', NULL) ` +
        `ON CONFLICT (id) DO UPDATE SET departure_time=EXCLUDED.departure_time;`
      );
    }
  }
}
```

- [ ] **Step 2: Generar y verificar schedules**

Run: `node tools/seed_comujesa.mjs`
Run: `grep -c "INSERT INTO schedules" tools/seed_out/comujesa_seed.sql`
Expected: igual al conteo `schedules` de Task 1.

- [ ] **Step 3: Commit**

```bash
git add tools/seed_comujesa.mjs tools/seed_out/comujesa_seed.sql
git commit -m "feat(seed): emitir schedules de cabecera por tipo de dia"
```

---

## Task 6: Aplicar el seed a Supabase y verificar (test de integración)

**Files:**
- Use: `tools/seed_out/comujesa_seed.sql`

> Aplicación: vía MCP `apply_migration` (nombre `seed_comujesa_official`) con el contenido del SQL, **o** pegándolo en el SQL Editor de Supabase, **o** `psql "$DATABASE_URL" -f tools/seed_out/comujesa_seed.sql`.
> **Requiere confirmación explícita del usuario antes de escribir en la BD en vivo (Fase A del spec).**

- [ ] **Step 1: Verificar estado previo (debe fallar = 0 filas)**

Run (SQL): `select count(*) routes, (select count(*) from stops) stops, (select count(*) from schedules) sch from routes;`
Expected: `routes=0, stops=0, sch=0` (estado de partida).

- [ ] **Step 2: Aplicar el SQL generado**

Aplicar `tools/seed_out/comujesa_seed.sql` por el método elegido. Debe terminar sin errores (la transacción `BEGIN…COMMIT` es atómica).

- [ ] **Step 3: Verificar conteos (test PASA)**

Run (SQL):
```sql
select
  (select count(*) from routes where operator_id='00000000-0000-0000-0000-000000000001' and source='official') as routes,
  (select count(*) from stops where operator_id='00000000-0000-0000-0000-000000000001') as stops,
  (select count(*) from route_stops) as route_stops,
  (select count(*) from schedules) as schedules,
  (select count(*) from routes where geom is not null) as routes_with_geom;
```
Expected: `routes=20`, `stops`/`route_stops`/`schedules` = los conteos de Task 1, `routes_with_geom` ≥ 19 (LEI u otras sin trazado pueden quedar NULL — anótalo).

- [ ] **Step 4: Verificar el check de oficiales y FKs**

Run (SQL): `select count(*) from routes where source='official' and (owner_id is not null or operator_id is null);`
Expected: `0` (cumple `routes_check`).

- [ ] **Step 5: Commit (artefacto ya commiteado; registrar verificación)**

```bash
git commit --allow-empty -m "chore(seed): aplicar y verificar seed COMUJESA en Supabase (20 lineas)"
```

---

## Task 7: Test de idempotencia

**Files:** ninguno (solo verificación)

- [ ] **Step 1: Re-aplicar el mismo SQL**

Aplicar de nuevo `tools/seed_out/comujesa_seed.sql`.

- [ ] **Step 2: Verificar que los conteos NO cambian**

Run (SQL): la misma consulta de Task 6 Step 3.
Expected: idénticos conteos (sin duplicados). Si `route_stops` creciera, revisar el `DELETE … direction=0` de Task 4.

---

## Task 8: Corregir `tools/migrate_comujesa.dart` (vía re-ejecutable con service key)

**Files:**
- Modify: `tools/migrate_comujesa.dart`

> El tool actual está roto: lee `schedules` como `List` (el JSON es objeto por día) y no migra el trazado ni la accesibilidad. Esta tarea lo deja consistente con el mapeo del seed para quien prefiera ejecutarlo con `SUPABASE_SERVICE_ROLE_KEY` en vez del SQL.

- [ ] **Step 1: Arreglar el parseo de schedules (objeto por día)**

Reemplazar el bloque `// ── Schedules ──` (`tools/migrate_comujesa.dart:205-241`) por:

```dart
  // ── Schedules ──
  print('Migrando horarios...');
  int schedulesUpserted = 0;
  const dayMap = {
    'weekday': 'weekday',
    'saturday': 'saturday',
    'sunday_holiday': 'sunday_holiday',
  };
  for (final line in lines) {
    final routeCode = line['code'] as String;
    final routeId = routeIdMap[routeCode];
    if (routeId == null || routeId.startsWith('dry-run')) continue;
    final sched = (line['schedules'] as Map<String, dynamic>?) ?? const {};
    for (final entry in sched.entries) {
      final dayType = dayMap[entry.key];
      if (dayType == null) continue;
      for (final t in (entry.value as List<dynamic>)) {
        if (dryRun) { schedulesUpserted++; continue; }
        try {
          await client.from('schedules').upsert({
            'route_id': routeId,
            'day_type': dayType,
            'direction': 0,
            'departure_time': t as String,
          });
          schedulesUpserted++;
        } catch (e) {
          print('  WARN schedule $routeCode-$t: $e');
        }
      }
    }
  }
  print('  Schedules: $schedulesUpserted upserted');
```

- [ ] **Step 2: Añadir trazado (geom) y accesibilidad al insert de routes/stops**

En el insert de `routes` (`tools/migrate_comujesa.dart:153-160`) añadir el campo `geom` a partir de `line['polyline']` (lod4 → `SRID=4326;LINESTRING(lng lat, ...)`), y en el insert de `stops` (`:114-119`) añadir `accessibility` (`{'wheelchair': isAccessible, 'shelter': hasShelter, 'bench': hasBench}`). Construir el LINESTRING con un helper local:

```dart
String? lineStringFromPolyline(Map<String, dynamic>? poly) {
  if (poly == null) return null;
  final c = poly['coordinates'];
  List<dynamic>? pts;
  if (c is List) { pts = c; }
  else if (c is Map) { pts = (c['lod4'] ?? c['lod3'] ?? c['lod2'] ?? c['lod1'] ?? c['lod0']) as List<dynamic>?; }
  if (pts == null || pts.length < 2) return null;
  final body = pts.map((p) => '${(p as List)[0]} ${p[1]}').join(', ');
  return 'SRID=4326;LINESTRING($body)';
}
```

- [ ] **Step 3: Verificar que compila**

Run: `dart analyze tools/migrate_comujesa.dart`
Expected: sin errores (warnings de `print` aceptables en un tool).

- [ ] **Step 4: Commit**

```bash
git add tools/migrate_comujesa.dart
git commit -m "fix(tools): migrate_comujesa - horarios como objeto, geom y accesibilidad"
```

---

## Task 9: Verificación funcional en la app

**Files:** ninguno (verificación manual)

- [ ] **Step 1: Arrancar la app e iniciar sesión como admin**

Run: `flutter run` (o el flujo habitual). Iniciar sesión con una cuenta `role=admin`.

- [ ] **Step 2: Verificar Gestión de líneas**

Navegar a Gestión de líneas. Expected: aparecen **20 líneas** de COMUJESA (antes: "Sin líneas").

- [ ] **Step 3: Verificar el mapa**

Abrir el mapa. Expected: se renderizan los trazados de las líneas (polylines) y las paradas.

- [ ] **Step 4: Commit (registro)**

```bash
git commit --allow-empty -m "test(seed): verificacion funcional - 20 lineas COMUJESA visibles logueado"
```

---

## Self-Review (cobertura del spec — Fase A)

- **Seed idempotente de routes/stops/route_stops/schedules** → Tasks 2-7. ✓
- **geom LINESTRING + LOD en metadata** → Task 2 (geom desde lod4; lod0-3 en `metadata.polyline_lod`). ✓
- **accessibility jsonb** → Task 3. ✓
- **source/status official, owner_id NULL (routes_check)** → Task 2 + verificación Task 6 Step 4. ✓
- **Mapeo code→gtfs_route_id, officialCode→gtfs_stop_id** → Tasks 2-3. ✓
- **Confirmación previa antes de escribir en BD en vivo** → Task 6 (nota explícita). ✓
- **Reversibilidad por operator_id+source** → garantizada por el filtro de los inserts; documentado en spec.
- **Tool migrate_comujesa.dart corregido** → Task 8. ✓
- **Resultado: líneas visibles en Gestión y mapa** → Task 9. ✓

**Puntos abiertos heredados del spec (no bloquean Fase A):** `scheduled_departures` huérfanas (revisar en Fase E), `arrival_offsets` se rellena en Fase E, horario de verano y UI de horarios son Fase E.

**Próximos planes (un subsistema por plan):** Fase E (horarios exactos OCR + UI), Fase B (offline snapshot), Fase D (mejoras Gestión), Fase C (wizard admin).
