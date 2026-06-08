// Compila la app Flutter para web y la copia a `public/app/`, desde donde
// Astro la sirve en /app/ (la app usa hash-routing, así que toda su
// navegación vive bajo /app/#/...).
//
// Uso:  npm run build:app   (desde la carpeta astro/)
//
// Requisitos: Flutter en el PATH y, en la raíz del proyecto Flutter, el
// fichero dart_defines.json con las claves (Supabase, MapTiler, etc.).
import { execSync } from 'node:child_process';
import {
  cpSync, rmSync, existsSync, mkdirSync, readFileSync, writeFileSync,
} from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const astroRoot = resolve(here, '..');
const flutterRoot = resolve(astroRoot, '..');
const buildWeb = resolve(flutterRoot, 'build', 'web');
const dest = resolve(astroRoot, 'public', 'app');

const defines = resolve(flutterRoot, 'dart_defines.json');
const definesArg = existsSync(defines)
  ? `--dart-define-from-file="${defines}"`
  : '';

console.log('▶ flutter build web --base-href /app/ …');
execSync(
  `flutter build web --release --base-href /app/ ${definesArg}`,
  { cwd: flutterRoot, stdio: 'inherit' },
);

console.log(`▶ Copiando ${buildWeb} → ${dest}`);
if (existsSync(dest)) rmSync(dest, { recursive: true, force: true });
mkdirSync(dest, { recursive: true });
cpSync(buildWeb, dest, { recursive: true });

// Garantiza el base href /app/ (a veces --base-href no se refleja en el
// index.html generado). La app usa hash-routing, así que /app/ basta.
const indexPath = resolve(dest, 'index.html');
let html = readFileSync(indexPath, 'utf8');
html = html.replace(/<base href="[^"]*">/, '<base href="/app/">');
writeFileSync(indexPath, html);

console.log('✓ App Flutter Web lista en public/app/ (servida en /app/)');
