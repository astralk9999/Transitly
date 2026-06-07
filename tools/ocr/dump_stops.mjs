// tools/ocr/dump_stops.mjs — vuelca TODAS las paradas del operador COMUJESA
// (id, name, code) a out/all_stops.json, para casar contra nombres del PDF.
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';

const mcp = JSON.parse(readFileSync('.mcp.json', 'utf8'));
const token = mcp?.mcpServers?.supabase?.env?.SUPABASE_ACCESS_TOKEN;
const ref = readFileSync('supabase/.temp/project-ref', 'utf8').trim();
const OP = '00000000-0000-0000-0000-000000000001';

const query = `select id, name, code, ST_Y(geom::geometry) as lat, ST_X(geom::geometry) as lng
  from stops where operator_id='${OP}' order by name;`;

const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
  method: 'POST',
  headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
  body: JSON.stringify({ query }),
});
if (!res.ok) { console.error('HTTP', res.status, await res.text()); process.exit(2); }
const rows = await res.json();
mkdirSync('tools/ocr/out', { recursive: true });
writeFileSync('tools/ocr/out/all_stops.json', JSON.stringify(rows), 'utf8');
console.log(`all_stops.json: ${rows.length} paradas`);
