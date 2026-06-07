// tools/apply_sql.mjs
// Aplica un archivo SQL al proyecto Supabase usando la Management API.
// El contenido del SQL NO se imprime (evita volcarlo al contexto del agente).
//
// Uso: node tools/apply_sql.mjs <ruta.sql>
//
// Lee el PAT de .mcp.json (mcpServers.supabase.env.SUPABASE_ACCESS_TOKEN) y el
// project ref de supabase/.temp/project-ref. Nunca imprime el token.
import { readFileSync } from 'node:fs';

const file = process.argv[2];
if (!file) {
  console.error('Uso: node tools/apply_sql.mjs <ruta.sql>');
  process.exit(1);
}

const mcp = JSON.parse(readFileSync('.mcp.json', 'utf8'));
const token = mcp?.mcpServers?.supabase?.env?.SUPABASE_ACCESS_TOKEN;
if (!token) {
  console.error('No SUPABASE_ACCESS_TOKEN en .mcp.json');
  process.exit(1);
}
const ref = readFileSync('supabase/.temp/project-ref', 'utf8').trim();
const sql = readFileSync(file, 'utf8');

const res = await fetch(`https://api.supabase.com/v1/projects/${ref}/database/query`, {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${token}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ query: sql }),
});

const text = await res.text();
console.log('HTTP', res.status, res.statusText);
// Solo imprime la respuesta (no el SQL enviado). Trunca por seguridad.
console.log(text.slice(0, 2000));
process.exitCode = res.ok ? 0 : 2;
