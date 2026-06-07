// tools/ocr/fetch_route.mjs <CODE> [outdir]
// Vuelca route_id + paradas en orden de una línea a out/route_<CODE>.json,
// consultando Supabase via Management API (token de .mcp.json). Imprime solo
// un resumen (el detalle va al archivo, no al contexto del agente).
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const code = process.argv[2];
const outdir = process.argv[3] || 'tools/ocr/out';
if (!code) {
  console.error('Uso: node tools/ocr/fetch_route.mjs <CODE> [outdir]');
  process.exit(1);
}

const mcp = JSON.parse(readFileSync('.mcp.json', 'utf8'));
const token = mcp?.mcpServers?.supabase?.env?.SUPABASE_ACCESS_TOKEN;
const ref = readFileSync('supabase/.temp/project-ref', 'utf8').trim();

const query = `select r.id as route_id,
  coalesce(json_agg(json_build_object('seq', rs.sequence, 'stop_id', s.id, 'name', s.name) order by rs.sequence)
    filter (where rs.stop_id is not null), '[]') as stops
from routes r
left join route_stops rs on rs.route_id = r.id and rs.direction = 0
left join stops s on s.id = rs.stop_id
where r.operator_id='00000000-0000-0000-0000-000000000001' and r.code = '${code}'
group by r.id;`;

const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ query }),
});
if (!res.ok) {
  console.error('HTTP', res.status, await res.text());
  process.exit(2);
}
const rows = await res.json();
if (!rows.length) {
  console.error(`Línea ${code} no encontrada`);
  process.exit(3);
}
mkdirSync(outdir, { recursive: true });
const out = { code, route_id: rows[0].route_id, stops: rows[0].stops };
writeFileSync(`${outdir}/route_${code}.json`, JSON.stringify(out), 'utf8');
console.log(`route_${code}.json: ${out.stops.length} paradas, route_id=${out.route_id}`);
