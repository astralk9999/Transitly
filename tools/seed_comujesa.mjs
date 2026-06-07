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
  return `${h.slice(0, 8)}-${h.slice(8, 12)}-${h.slice(12, 16)}-${h.slice(16, 20)}-${h.slice(20)}`;
}

function slug(s) {
  return (s || '')
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/(^-|-$)/g, '');
}

// Clave de parada FÍSICA = coordenada exacta del JSON. Verificado: las paradas
// compartidas entre líneas tienen lat/lng idénticos y ningún nombre apunta a
// >1 coordenada, así que deduplicar por coordenada es seguro y fusiona las
// ~292 ocurrencias duplicadas en 306 paradas físicas reales. Esto arregla en
// origen el que en una parada solo se viera una línea (ahora todas comparten
// la misma fila de parada) y los marcadores solapados.
function stopKey(st) {
  return `${st.lat},${st.lng}`;
}

const sqlEsc = (s) => (s == null ? 'NULL' : `'${String(s).replace(/'/g, "''")}'`);
const jsonLit = (o) => `'${JSON.stringify(o).replace(/'/g, "''")}'::jsonb`;

function lodCoords(line) {
  const p = line.polyline;
  if (!p || !p.coordinates) return null;
  const c = p.coordinates;
  if (Array.isArray(c)) return { lod4: c, rest: {} };
  const rest = {};
  for (const k of ['lod0', 'lod1', 'lod2', 'lod3']) if (c[k]) rest[k] = c[k];
  const lod4 = c.lod4 || c.lod3 || c.lod2 || c.lod1 || c.lod0 || null;
  return { lod4, rest };
}

function lineStringSQL(coords) {
  if (!coords || coords.length < 2) return 'NULL';
  const pts = coords.map((p) => `${Number(p[0])} ${Number(p[1])}`).join(', ');
  return `ST_GeomFromText('LINESTRING(${pts})', 4326)`;
}

const DAY_MAP = {
  weekday: 'weekday',
  saturday: 'saturday',
  sunday_holiday: 'sunday_holiday',
};

const data = JSON.parse(readFileSync('assets/mock/comujesa_data.json', 'utf8'));
const lines = data.lines;

// Dedup de paradas por key (una parada puede aparecer en varias líneas)
const stopsByKey = new Map();
for (const line of lines) {
  for (const st of line.stops || []) {
    const k = stopKey(st);
    if (!stopsByKey.has(k)) stopsByKey.set(k, st);
  }
}

let scheduleCount = 0;
let routeStopCount = 0;
for (const line of lines) {
  routeStopCount += (line.stops || []).length;
  for (const day of Object.keys(line.schedules || {})) {
    scheduleCount += (line.schedules[day] || []).length;
  }
}

if (process.argv.includes('--counts')) {
  console.log(
    JSON.stringify({
      routes: lines.length,
      stops: stopsByKey.size,
      route_stops: routeStopCount,
      schedules: scheduleCount,
    }),
  );
  process.exit(0);
}

const out = [];
out.push('-- COMUJESA seed (idempotente). Generado por tools/seed_comujesa.mjs');
out.push('BEGIN;');

// 1) Stops (antes de route_stops por la FK)
for (const [key, st] of stopsByKey) {
  const id = uuidv5(`comujesa:stop:${key}`);
  const acc = {
    wheelchair: !!st.isAccessible,
    shelter: !!st.hasShelter,
    bench: !!st.hasBench,
  };
  const meta = { municipality: st.municipality || null };
  out.push(
    `INSERT INTO stops (id, operator_id, code, name, geom, accessibility, gtfs_stop_id, metadata, source, owner_id) VALUES (` +
      `'${id}', '${OPERATOR_ID}', ${sqlEsc(st.officialCode || null)}, ${sqlEsc(st.name)}, ` +
      `ST_SetSRID(ST_MakePoint(${Number(st.lng)}, ${Number(st.lat)}), 4326), ${jsonLit(acc)}, ${sqlEsc(key)}, ${jsonLit(meta)}, 'official', NULL) ` +
      `ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, geom=EXCLUDED.geom, accessibility=EXCLUDED.accessibility, code=EXCLUDED.code, metadata=EXCLUDED.metadata;`,
  );
}

// 2) Routes
for (const line of lines) {
  const id = uuidv5(`comujesa:route:${line.code}`);
  const lod = lodCoords(line);
  const geom = lineStringSQL(lod && lod.lod4);
  const meta = {
    active: true,
    serviceType: line.serviceType || null,
    polyline_lod: (lod && lod.rest) || {},
  };
  const color = line.color
    ? line.color.startsWith('#')
      ? line.color
      : `#${line.color}`
    : null;
  out.push(
    `INSERT INTO routes (id, operator_id, source, status, code, name, color, owner_id, gtfs_route_id, geom, metadata) VALUES (` +
      `'${id}', '${OPERATOR_ID}', 'official', 'official', ${sqlEsc(line.code)}, ${sqlEsc(line.name)}, ${sqlEsc(color)}, NULL, ${sqlEsc(line.code)}, ${geom}, ${jsonLit(meta)}) ` +
      `ON CONFLICT (id) DO UPDATE SET name=EXCLUDED.name, color=EXCLUDED.color, geom=EXCLUDED.geom, metadata=EXCLUDED.metadata, status=EXCLUDED.status, gtfs_route_id=EXCLUDED.gtfs_route_id, updated_at=now();`,
  );
}

// 3) Route stops (delete + insert idempotente)
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
      `INSERT INTO route_stops (route_id, stop_id, sequence, direction) VALUES ('${routeId}', '${stopId}', ${seq}, 0) ON CONFLICT DO NOTHING;`,
    );
  });
}

// 4) Schedules (cabecera por tipo de día)
for (const line of lines) {
  const routeId = uuidv5(`comujesa:route:${line.code}`);
  const sch = line.schedules || {};
  for (const day of Object.keys(sch)) {
    const dayType = DAY_MAP[day];
    if (!dayType) continue;
    for (const t of sch[day] || []) {
      const id = uuidv5(`comujesa:sched:${line.code}:${dayType}:0:${t}`);
      out.push(
        `INSERT INTO schedules (id, route_id, day_type, direction, departure_time, arrival_offsets) VALUES (` +
          `'${id}', '${routeId}', '${dayType}', 0, '${t}', NULL) ` +
          `ON CONFLICT (id) DO UPDATE SET departure_time=EXCLUDED.departure_time;`,
      );
    }
  }
}

out.push('COMMIT;');
mkdirSync('tools/seed_out', { recursive: true });
writeFileSync('tools/seed_out/comujesa_seed.sql', out.join('\n') + '\n', 'utf8');
console.log(`SQL escrito: tools/seed_out/comujesa_seed.sql (${out.length} líneas)`);
