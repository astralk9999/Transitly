// Genera el PDF combinado de la memoria del TFG a partir de docs/tfg/*.md.
// Pipeline: markdown -> HTML (marked) -> PDF (Chrome vía puppeteer-core).
// El Gantt (```mermaid del doc 03) se renderiza como diagrama en la página
// antes de imprimir. Salida: docs/tfg/Memoria_Transitly_TFG.pdf
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { marked } from 'marked';
import puppeteer from 'puppeteer-core';

const here = dirname(fileURLToPath(import.meta.url));
const repo = resolve(here, '..', '..');
const tfgDir = resolve(repo, 'docs', 'tfg');
// Salida en la carpeta public de la web para servirla en GitHub Pages.
const out = resolve(repo, 'presentation', 'public', 'Memoria_Transitly_TFG.pdf');

const CHROME = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
].find((p) => existsSync(p));
if (!CHROME) { console.error('Chrome no encontrado'); process.exit(1); }

// Contexto desde metrics.json
let ctx = {}, rel = {};
try {
  const m = JSON.parse(readFileSync(resolve(repo, 'presentation/src/data/metrics.json'), 'utf8'));
  ctx = m.context || {}; rel = m.release || {};
} catch {}

// Logo como data URI
let logoData = '';
try {
  const b = readFileSync(resolve(repo, 'presentation/public/transitly_logo.png'));
  logoData = `data:image/png;base64,${b.toString('base64')}`;
} catch {}

marked.setOptions({ gfm: true, breaks: false });

const files = readdirSync(tfgDir)
  .filter((f) => /^\d\d_.*\.md$/.test(f))
  .sort();

const TITLES = {
  '01': 'Análisis del Contexto y Detección de Necesidades',
  '02': 'Diseño del Proyecto',
  '03': 'Planificación de la Ejecución',
  '04': 'Desarrollo e Implementación',
  '05': 'Seguimiento, Evaluación y Documentación',
  '06': 'Manual Técnico',
  '07': 'Manual de Usuario',
  '08': 'Presentación Final',
};

const mermaidCodes = []; // códigos crudos; se renderizan por string en la página
const sections = [];
for (const f of files) {
  const num = f.slice(0, 2);
  let md = readFileSync(resolve(tfgDir, f), 'utf8');
  // Extraer bloques mermaid; se reinyectan como contenedor vacío que se
  // rellena con el SVG renderizado vía mermaid.render(id, code).
  md = md.replace(/```mermaid\n([\s\S]*?)```/g, (_, code) => {
    const gi = mermaidCodes.push(code.replace(/\s+$/, '')) - 1;
    return `\n\nMERMAIDPLACEHOLDER${gi}MERMAIDEND\n\n`;
  });
  let html = marked.parse(md);
  html = html
    .replace(/<p>MERMAIDPLACEHOLDER(\d+)MERMAIDEND<\/p>/g, (_, gi) => `<div class="mermaid-target" id="mm${gi}"></div>`)
    .replace(/MERMAIDPLACEHOLDER(\d+)MERMAIDEND/g, (_, gi) => `<div class="mermaid-target" id="mm${gi}"></div>`);
  sections.push({ num, title: TITLES[num] || f, html });
}

const toc = sections.map((s) => `<li><span class="tn">${s.num}</span><a href="#doc${s.num}">${s.title}</a></li>`).join('\n');
const body = sections.map((s) => `<section class="doc" id="doc${s.num}"><div class="doctag">Documento ${s.num}</div>${s.html}</section>`).join('\n');

const css = `
  :root { --accent:#6C4FD8; --accent-soft:#EDE7FB; --ink:#1b1b2e; --mid:#4a4a63; --line:#e3e0ee; }
  * { box-sizing: border-box; }
  html { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { font-family: "Source Serif 4", Georgia, serif; color: var(--ink); font-size: 10.5pt; line-height: 1.55; margin: 0; }
  h1,h2,h3,h4 { font-family: "DM Sans", system-ui, sans-serif; color: var(--ink); line-height: 1.2; }
  /* Portada */
  .cover { height: 247mm; display: flex; flex-direction: column; justify-content: center; page-break-after: always; }
  .cover .logo { width: 86px; height: 86px; border-radius: 24%; background: linear-gradient(140deg,#6C4FD8,#3a2c70); display:flex; align-items:center; justify-content:center; margin-bottom: 26mm; }
  .cover .logo img { width: 56%; }
  .cover .ey { font-family:"DM Sans",sans-serif; text-transform:uppercase; letter-spacing:.28em; font-size:9pt; color:var(--accent); font-weight:600; }
  .cover h1 { font-size: 46pt; font-weight: 800; letter-spacing:-.02em; margin: 6px 0 4px; }
  .cover .sub { font-size: 14pt; color: var(--mid); max-width: 130mm; }
  .cover .meta { margin-top: 24mm; font-family:"DM Sans",sans-serif; font-size: 10.5pt; color: var(--ink); }
  .cover .meta div { margin: 3px 0; }
  .cover .meta b { color: var(--mid); font-weight: 500; display:inline-block; width: 34mm; }
  .cover .rule { width: 60px; height: 4px; background: var(--accent); border-radius: 4px; margin: 10mm 0; }
  /* Índice */
  .toc { page-break-after: always; }
  .toc h2 { font-size: 20pt; border-bottom: 2px solid var(--accent); padding-bottom: 6px; margin: 0 0 10mm; }
  .toc ol { list-style: none; padding: 0; margin: 0; }
  .toc li { display: flex; align-items: baseline; gap: 12px; padding: 7px 0; border-bottom: 1px dotted var(--line); font-family:"DM Sans",sans-serif; }
  .toc .tn { font-weight: 700; color: var(--accent); width: 26px; }
  .toc a { color: var(--ink); text-decoration: none; font-size: 11.5pt; }
  /* Documentos */
  .doc { page-break-before: always; }
  .doctag { font-family:"DM Sans",sans-serif; text-transform:uppercase; letter-spacing:.2em; font-size:8pt; color:var(--accent); font-weight:600; margin-bottom: 2mm; }
  .doc h1 { font-size: 24pt; font-weight: 800; letter-spacing:-.01em; margin: 0 0 6mm; padding-bottom: 4mm; border-bottom: 3px solid var(--accent); break-after: avoid; }
  .doc h2 { font-size: 15pt; margin: 8mm 0 3mm; padding-top: 3mm; border-top: 1px solid var(--line); break-after: avoid; }
  .doc h3 { font-size: 12pt; margin: 6mm 0 2mm; break-after: avoid; }
  .doc h4 { font-size: 11pt; margin: 4mm 0 2mm; color: var(--mid); }
  p { margin: 0 0 2.6mm; }
  a { color: var(--accent); }
  strong { font-weight: 700; }
  ul, ol { margin: 0 0 3mm; padding-left: 6mm; }
  li { margin: 1mm 0; }
  blockquote { margin: 3mm 0; padding: 2mm 4mm; border-left: 3px solid var(--accent); background: var(--accent-soft); color: var(--mid); border-radius: 0 4px 4px 0; }
  code { font-family: "IBM Plex Mono", monospace; font-size: 8.6pt; background: #f1eefb; color: #4a2fa0; padding: 0.5px 4px; border-radius: 3px; }
  pre { background: #f6f5fb; border: 1px solid var(--line); border-radius: 6px; padding: 3mm 4mm; overflow: hidden; white-space: pre-wrap; word-break: break-word; break-inside: avoid; font-size: 8.4pt; line-height: 1.45; margin: 0 0 3mm; }
  pre code { background: none; color: #333; padding: 0; }
  table { width: 100%; border-collapse: collapse; margin: 0 0 4mm; font-size: 9pt; break-inside: auto; }
  thead { background: var(--accent-soft); }
  th, td { border: 1px solid var(--line); padding: 1.6mm 2.4mm; text-align: left; vertical-align: top; }
  th { font-family:"DM Sans",sans-serif; font-weight: 600; }
  tr { break-inside: avoid; }
  hr { border: none; border-top: 1px solid var(--line); margin: 5mm 0; }
  .mermaid-target { text-align: center; margin: 4mm 0 5mm; break-inside: avoid; }
  .mermaid-target svg { max-width: 100%; height: auto; }
  h2, h3 { break-inside: avoid; }
`;

const cover = `
<div class="cover">
  <div class="logo">${logoData ? `<img src="${logoData}" alt="">` : ''}</div>
  <div class="ey">Trabajo de Fin de Grado · DAM</div>
  <h1>Transitly</h1>
  <div class="sub">Aplicación multiplataforma de transporte público en tiempo real para ciudades medias.</div>
  <div class="rule"></div>
  <div class="meta">
    <div><b>Autor</b> ${ctx.author || 'Koldo Uruburu'}</div>
    <div><b>Ciclo</b> Desarrollo de Aplicaciones Multiplataforma</div>
    <div><b>Centro</b> ${ctx.school || 'Victoria FP'} · ${ctx.course || '2025/2026'}</div>
    <div><b>Operador piloto</b> COMUJESA · ${ctx.city || 'Jerez de la Frontera'}</div>
    <div><b>Versión</b> v${rel.version || '1.12.1'}</div>
    <div><b>Defensa</b> ${ctx.defenseDate || '2026-06-09'}</div>
    <div><b>Repositorio</b> github.com/astralk9999/Transitly</div>
  </div>
</div>`;

const tocHtml = `<div class="toc"><h2>Índice de la memoria</h2><ol>${toc}</ol></div>`;

const doc = `<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<link rel="preconnect" href="https://fonts.googleapis.com"><link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700;800&family=Source+Serif+4:opsz,wght@8..60,400;8..60,600;8..60,700&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet">
<style>${css}</style></head><body>${cover}${tocHtml}${body}</body></html>`;

console.log(`▶ ${sections.length} documentos · generando PDF…`);

const browser = await puppeteer.launch({ executablePath: CHROME, headless: 'new', args: ['--no-sandbox', '--font-render-hinting=none'] });
const page = await browser.newPage();
await page.setContent(doc, { waitUntil: 'networkidle0', timeout: 60000 });

// Renderizar mermaid (Gantt) pasando el código CRUDO a mermaid.render(id, code)
// (evita perder saltos de línea al leer textContent del DOM).
if (mermaidCodes.length) {
  const themeVars = {
    fontFamily: 'DM Sans, sans-serif', primaryColor: '#EDE7FB', primaryBorderColor: '#6C4FD8',
    primaryTextColor: '#1b1b2e', lineColor: '#6C4FD8', textColor: '#1b1b2e',
    taskBkgColor: '#6C4FD8', taskBorderColor: '#3a2c70', taskTextColor: '#ffffff', taskTextDarkColor: '#1b1b2e',
    activeTaskBkgColor: '#00A0FF', activeTaskBorderColor: '#0077c0', doneTaskBkgColor: '#3ECF8E',
    sectionBkgColor: '#f3effb', altSectionBkgColor: '#e9e2f7', sectionBkgColor2: '#eef6ff', gridColor: '#cfc9e6',
  };
  page.on('pageerror', (e) => console.warn('  [pageerror]', e.message));
  try {
    await page.addScriptTag({
      type: 'module',
      content: `
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs';
        mermaid.initialize({ startOnLoad: false, theme: 'base', securityLevel: 'loose', themeVariables: ${JSON.stringify(themeVars)} });
        window.__mm = mermaid;
      `,
    });
    await page.waitForFunction(() => !!window.__mm, { timeout: 25000 });
    const results = await page.evaluate(async (codes) => {
      const out = [];
      for (let i = 0; i < codes.length; i++) {
        const el = document.getElementById('mm' + i);
        if (!el) { out.push('sin destino'); continue; }
        try {
          const { svg } = await window.__mm.render('mmsvg' + i, codes[i]);
          el.innerHTML = svg;
          out.push('ok');
        } catch (e) { out.push((e && e.message) ? e.message.split('\n')[0] : String(e)); }
      }
      return out;
    }, mermaidCodes);
    const okCount = results.filter((r) => r === 'ok').length;
    console.log(`  ✓ Diagramas renderizados: ${okCount}/${mermaidCodes.length}`);
    results.forEach((r, i) => { if (r !== 'ok') console.warn(`    diagrama ${i}: ${r}`); });
  } catch (e) {
    console.warn('  (aviso) error cargando mermaid:', e.message);
  }
}

await page.pdf({
  path: out,
  format: 'A4',
  printBackground: true,
  displayHeaderFooter: true,
  margin: { top: '18mm', bottom: '18mm', left: '16mm', right: '16mm' },
  headerTemplate: '<div></div>',
  footerTemplate: `<div style="font-size:7.5pt;width:100%;padding:0 16mm;color:#9a96ad;font-family:sans-serif;display:flex;justify-content:space-between;"><span>Transitly · Memoria del TFG</span><span>Página <span class="pageNumber"></span> / <span class="totalPages"></span></span></div>`,
});

await browser.close();
console.log(`✓ PDF generado: ${out}`);
