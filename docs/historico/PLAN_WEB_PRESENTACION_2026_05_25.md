# PLAN DE WEB DE PRESENTACIÓN TFG — Transitly en GitHub Pages

**Fecha:** 2026-05-25
**HEAD base:** `master @ 7150bf5`
**Defensa final:** 2026-06-09 (15 días vista)
**Scope:** web estática Astro alojada en GitHub Pages que sustituye al PDF de presentación TFG.
**Audiencia:** dev (humano o IA) que ejecutará los pasos.
**Tiempo total estimado:** ~6-8 horas activas distribuidas en 15 días.
**Coste:** €0 (GitHub Pages + Releases son gratis).

---

## Reglas transversales

1. **Cada paso PR-able:** un cambio significativo = un commit atómico en español con prefijo Conventional Commits.
2. **NO commitear secretos** ni `node_modules/` ni `dist/` (ya en `.gitignore`).
3. **Validar antes de cada commit** con `git status` para no incluir archivos no deseados.
4. **El build Astro debe quedar verde tras cada cambio:** `cd presentation && npm run build` sin errores.
5. **El workflow GH Pages debe pasar** tras cada push a `master` que toque `presentation/`.
6. **Cifras canónicas a usar en toda la web (no inventar):**
   - 619 tests + 6 skipped
   - 14 migraciones SQL
   - 27 features
   - 4 Edge Functions
   - 628 claves ARB (ES) + 14 nuevas = 642
   - 6 jobs CI verde
   - Cobertura 24,04 %
   - Scorecard TFG 9,0/10
   - APK release 73,5 MiB

---

## Índice

- [A. Setup Astro estático en `presentation/` (~1 h)](#a-setup)
- [B. Diseño de la landing — 14 secciones (~2 h)](#b-diseño)
- [C. Mapping contenido docs/tfg → secciones web (~1 h)](#c-mapping)
- [D. APK descargable desde GitHub Releases (~30 min)](#d-apk)
- [E. Redirección a web Astro híbrida (~15 min)](#e-redirección)
- [F. Workflow GitHub Pages para `presentation/` (~30 min)](#f-workflow)
- [G. Mover dartdoc a `/api/` subpath (~20 min)](#g-dartdoc)
- [H. Configurar GitHub Pages settings (~5 min)](#h-pages-settings)
- [I. Verificación end-to-end (~30 min)](#i-verificación)
- [J. Cumplimiento guía TFG (mapping fases)](#j-cumplimiento)
- [K. Cronograma sugerido 15 días](#k-cronograma)
- [L. Resumen ejecutivo](#l-resumen)

---

<a id="a-setup"></a>
## A. Setup Astro estático en `presentation/`

**Objetivo:** crear proyecto Astro nuevo en `presentation/` configurado para output estático compatible con GitHub Pages.

**Esfuerzo:** ~1 h

---

### A.1 — Scaffold Astro en carpeta nueva

**Pre-requisito:** Node.js 20+ instalado.

```powershell
# Desde la raíz del repo
npm create astro@latest presentation -- --template minimal --typescript strict --no-install --no-git
```

Esto crea:
```
presentation/
├── astro.config.mjs
├── package.json
├── tsconfig.json
├── src/
│   ├── pages/index.astro
│   └── env.d.ts
└── public/
```

Si el comando interactivo pregunta, responder:
- Template: **Empty / Minimal**
- TypeScript: **Strict**
- Install dependencies: **No** (lo haremos después)
- Initialize git: **No** (el repo ya está bajo git)

---

### A.2 — Configurar `astro.config.mjs` para GH Pages estático

**Archivo:** `presentation/astro.config.mjs`

```javascript
import { defineConfig } from 'astro/config';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';

export default defineConfig({
  // Output estático (HTML/CSS/JS planos, sin servidor)
  output: 'static',

  // Subpath para GitHub Pages: https://astralk9999.github.io/Transitly/
  site: 'https://astralk9999.github.io',
  base: '/Transitly',

  integrations: [
    tailwind(),
    sitemap(),
  ],

  build: {
    // Inline pequeños CSS para evitar FOUC
    inlineStylesheets: 'auto',
  },

  // No usar formato 'directory' para que GH Pages sirva /index.html directo
  trailingSlash: 'never',
});
```

**Importante:** `base: '/Transitly'` significa que todas las URLs relativas dentro de la web tendrán prefijo `/Transitly/`. En Astro, usar siempre `<a href={`${import.meta.env.BASE_URL}/path`}>` o el helper `<Link>`.

---

### A.3 — Instalar dependencias y TailwindCSS

```powershell
cd presentation
npm install
npx astro add tailwind --yes
npx astro add sitemap --yes
```

Esto añade a `package.json`:
- `astro` ^5.x
- `@astrojs/tailwind` ^5.x
- `@astrojs/sitemap` ^3.x
- `tailwindcss` ^3.4.x
- `typescript` ^5.x

**Verificar `package.json`:**

```json
{
  "name": "transitly-presentation",
  "type": "module",
  "version": "1.0.0",
  "scripts": {
    "dev": "astro dev",
    "start": "astro dev",
    "build": "astro build",
    "preview": "astro preview"
  },
  "dependencies": {
    "@astrojs/sitemap": "^3.4.0",
    "@astrojs/tailwind": "^5.1.5",
    "astro": "^5.10.0",
    "tailwindcss": "^3.4.17"
  }
}
```

---

### A.4 — Configurar Tailwind con paleta Transitly

**Archivo:** `presentation/tailwind.config.mjs`

```javascript
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./src/**/*.{astro,html,js,jsx,md,mdx,svelte,ts,tsx,vue}'],
  theme: {
    extend: {
      colors: {
        'transit': {
          'bg-root': '#08081A',
          'bg-surface': '#10102A',
          'bg-raised': '#1A1A35',
          'text-hi': '#F0F0FA',
          'text-mid': '#8888A8',
          'text-lo': '#7A7A98',
          'accent': '#977DDF',
          'accent-bg': '#977DDF1A',
          'state-success': '#B0FF00',
          'state-info': '#00A0FF',
          'state-warning': '#FFB000',
          'state-cancelled': '#FF4D6D',
        },
      },
      fontFamily: {
        'sans': ['"DM Sans"', 'system-ui', 'sans-serif'],
        'mono': ['"IBM Plex Mono"', 'ui-monospace', 'monospace'],
      },
      animation: {
        'fade-in': 'fadeIn 0.6s ease-out',
        'slide-up': 'slideUp 0.6s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideUp: {
          '0%': { opacity: '0', transform: 'translateY(20px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
      },
    },
  },
};
```

---

### A.5 — Estructura de carpetas

Crear estructura final:

```
presentation/
├── astro.config.mjs
├── package.json
├── tailwind.config.mjs
├── tsconfig.json
├── README.md
├── .gitignore
├── src/
│   ├── pages/
│   │   └── index.astro              # Landing single-page
│   ├── layouts/
│   │   └── Layout.astro             # Layout principal con head + nav
│   ├── components/
│   │   ├── Section01Hero.astro
│   │   ├── Section02Problem.astro
│   │   ├── Section03Solution.astro
│   │   ├── Section04Demo.astro
│   │   ├── Section05Architecture.astro
│   │   ├── Section06Accessibility.astro
│   │   ├── Section07Security.astro
│   │   ├── Section08Quality.astro
│   │   ├── Section09Methodology.astro
│   │   ├── Section10Lessons.astro
│   │   ├── Section11FutureWork.astro
│   │   ├── Section12Team.astro
│   │   ├── Section13Download.astro
│   │   └── Footer.astro
│   ├── data/
│   │   └── metrics.json             # Cifras canónicas reusables
│   └── styles/
│       └── global.css               # Reset + fuentes externas
└── public/
    ├── favicon.svg
    ├── og-image.png                 # 1200x630 para social cards
    ├── demo.mp4                     # Video demo opcional
    ├── screenshots/                 # Capturas app
    │   ├── home.png
    │   ├── map.png
    │   ├── route-detail.png
    │   └── ...
    └── fonts/                       # Si bundleamos fuentes
        ├── DMSans.ttf
        └── IBMPlexMono.ttf
```

---

### A.6 — Configurar `.gitignore`

**Archivo:** `presentation/.gitignore`

```
node_modules/
dist/
.astro/
.DS_Store
*.log
.env
.env.local
```

---

### A.7 — Verificación setup

```powershell
cd presentation
npm run build
```

**Resultado esperado:**
- `presentation/dist/` con `index.html`, `_astro/`, etc.
- Sin errores en consola.
- Tamaño total `<1 MB` (Astro inlinea CSS y es muy ligero).

```powershell
npm run preview
```

Abrir `http://localhost:4321/Transitly/` en el navegador. Debería ver la página por defecto de Astro.

---

### A.8 — Commit inicial

```powershell
cd ..
git add presentation/.gitignore presentation/package.json presentation/astro.config.mjs presentation/tailwind.config.mjs presentation/tsconfig.json presentation/src/ presentation/public/
git commit -m "feat(presentation): scaffold Astro estatico en presentation/ para GH Pages (A)"
```

---

<a id="b-diseño"></a>
## B. Diseño de la landing — 14 secciones

**Objetivo:** página única `src/pages/index.astro` con 14 secciones navegables por scroll.

**Esfuerzo:** ~2 h

---

### B.1 — Layout principal

**Archivo:** `presentation/src/layouts/Layout.astro`

```astro
---
interface Props {
  title?: string;
  description?: string;
}
const {
  title = 'Transitly — Transporte público en tiempo real',
  description = 'Aplicacion Android multiplataforma para transporte público en ciudades medias españolas. TFG DAM.',
} = Astro.props;

const baseUrl = import.meta.env.BASE_URL;
---

<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <meta name="description" content={description} />
  <title>{title}</title>

  <!-- Open Graph / Social cards -->
  <meta property="og:title" content={title} />
  <meta property="og:description" content={description} />
  <meta property="og:image" content={`${baseUrl}/og-image.png`} />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="https://astralk9999.github.io/Transitly/" />

  <!-- Twitter Cards -->
  <meta name="twitter:card" content="summary_large_image" />

  <!-- Favicon -->
  <link rel="icon" type="image/svg+xml" href={`${baseUrl}/favicon.svg`} />

  <!-- Fuentes Google (cargas asíncronas) -->
  <link rel="preconnect" href="https://fonts.googleapis.com" />
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;700&family=IBM+Plex+Mono:wght@400;500&display=swap" rel="stylesheet" />
</head>
<body class="bg-transit-bg-root text-transit-text-hi font-sans antialiased">
  <nav class="fixed top-0 left-0 right-0 z-50 bg-transit-bg-root/80 backdrop-blur-md border-b border-transit-bg-surface">
    <div class="max-w-6xl mx-auto px-6 py-4 flex items-center justify-between">
      <a href={baseUrl} class="font-bold text-xl text-transit-accent">Transitly</a>
      <div class="hidden md:flex gap-6 text-sm">
        <a href="#problema" class="hover:text-transit-accent transition">Problema</a>
        <a href="#solucion" class="hover:text-transit-accent transition">Solución</a>
        <a href="#arquitectura" class="hover:text-transit-accent transition">Arquitectura</a>
        <a href="#calidad" class="hover:text-transit-accent transition">Calidad</a>
        <a href="#descargar" class="px-4 py-1.5 bg-transit-accent text-white rounded-full text-xs font-medium hover:bg-transit-accent/90 transition">Descargar APK</a>
      </div>
    </div>
  </nav>

  <main class="pt-16">
    <slot />
  </main>
</body>
</html>
```

---

### B.2 — Página principal

**Archivo:** `presentation/src/pages/index.astro`

```astro
---
import Layout from '../layouts/Layout.astro';
import Section01Hero from '../components/Section01Hero.astro';
import Section02Problem from '../components/Section02Problem.astro';
import Section03Solution from '../components/Section03Solution.astro';
import Section04Demo from '../components/Section04Demo.astro';
import Section05Architecture from '../components/Section05Architecture.astro';
import Section06Accessibility from '../components/Section06Accessibility.astro';
import Section07Security from '../components/Section07Security.astro';
import Section08Quality from '../components/Section08Quality.astro';
import Section09Methodology from '../components/Section09Methodology.astro';
import Section10Lessons from '../components/Section10Lessons.astro';
import Section11FutureWork from '../components/Section11FutureWork.astro';
import Section12Team from '../components/Section12Team.astro';
import Section13Download from '../components/Section13Download.astro';
import Footer from '../components/Footer.astro';
---

<Layout>
  <Section01Hero />
  <Section02Problem />
  <Section03Solution />
  <Section04Demo />
  <Section05Architecture />
  <Section06Accessibility />
  <Section07Security />
  <Section08Quality />
  <Section09Methodology />
  <Section10Lessons />
  <Section11FutureWork />
  <Section12Team />
  <Section13Download />
  <Footer />
</Layout>
```

---

### B.3 — 14 secciones (contenido)

Cada componente sigue el patrón básico:

```astro
<section id="<id>" class="py-24 px-6 max-w-6xl mx-auto">
  <h2 class="text-4xl font-bold mb-4">Título</h2>
  <p class="text-transit-text-mid mb-12 text-lg">Subtítulo descriptivo</p>
  <!-- Contenido -->
</section>
```

#### 1. **Hero** (`Section01Hero.astro`)

Contenido:
- Título grande "Transitly" + tagline "Transporte público en tiempo real"
- Subtitulo: "Aplicación multiplataforma para ciudades medias españolas"
- 2 CTAs:
  - **Botón primario:** "Descargar APK" → link release GitHub (placeholder hasta D)
  - **Botón secundario:** "Ver web completa" → link a web Astro híbrida (placeholder hasta E)
- Imagen/gif: mockup móvil con screenshot home

#### 2. **Problema** (`Section02Problem.astro`, anchor `#problema`)

Contenido:
- Cifras INE 2024: ~1.500M viajeros urbanos, ~600M interurbanos
- 3 carencias detectadas (cards):
  - "Sin GPS tiempo real" en ciudades medias
  - "Fragmentación de apps" por operador
  - "Accesibilidad pobre"

#### 3. **Solución** (`Section03Solution.astro`, anchor `#solucion`)

Contenido:
- 5 features destacadas en cards 2-2-1:
  - Mapa con tiempo real
  - Lectura NFC tarjeta Consorcio Andalucía
  - Modo offline con regiones descargables
  - Comunidad: reportes + sugerencias + reputación
  - Accesibilidad WCAG 2.2 AA

#### 4. **Demo en vivo** (`Section04Demo.astro`)

Contenido:
- Video demo embebido (`/public/demo.mp4`) o galería de 5 screenshots
- Caption: "30 segundos de la app real funcionando"

#### 5. **Arquitectura** (`Section05Architecture.astro`, anchor `#arquitectura`)

Contenido:
- Diagrama Mermaid (renderizado vía mermaid.js CDN):
  ```mermaid
  graph TB
    UI[Features 27<br/>Flutter UI]
    State[Riverpod 2.6<br/>State Management]
    Data[Data Layer<br/>12 Repos SWR + 4 sin SWR]
    Cache[Hive 2.2<br/>17 boxes + 2 cifradas]
    Backend[Supabase<br/>PostgreSQL + RLS]
    Edge[4 Edge Functions<br/>Deno]
    UI --> State
    State --> Data
    Data --> Cache
    Data --> Backend
    Backend --> Edge
  ```
- Stack tecnológico (badges): Flutter 3.x, Dart 3, Riverpod 2.6, Supabase, Firebase, Sentry, PostHog, Hive

#### 6. **Accesibilidad e i18n** (`Section06Accessibility.astro`)

Contenido:
- 3 cards con métricas:
  - **WCAG 2.2 AA:** semantics, 48dp touch targets, textScaler, 8 matrices daltonismo
  - **3 idiomas:** ES (642), EN (628), AR (272) con soporte RTL
  - **Verificación:** acta TalkBack pendiente (pre-defensa)

#### 7. **Seguridad y privacidad** (`Section07Security.astro`)

Contenido:
- Tabla de cumplimiento GDPR:
  | Artículo | Implementación |
  |----------|----------------|
  | Art. 8 (menores) | Validación edad ≥16 en signup |
  | Art. 13 (información) | Privacy screen + consent granular |
  | Art. 17 (borrado) | Edge function `delete_user` + worker |
  | Art. 20 (portabilidad) | Edge function `generate_data_export` (pendiente) |
  | Art. 21 (oposición) | Revocación consent en caliente |
- RLS PostgreSQL DENY-by-default + cifrado HiveAesCipher

#### 8. **Calidad** (`Section08Quality.astro`, anchor `#calidad`)

Contenido:
- 6 métricas grandes (uno por columna):
  - **619** tests verde
  - **14** migraciones SQL
  - **4** Edge Functions
  - **27** features
  - **6** CI jobs
  - **9,0/10** scorecard TFG

Importar de `src/data/metrics.json` para reusar cifras canónicas.

#### 9. **Metodología** (`Section09Methodology.astro`)

Contenido:
- Diagrama Gantt Mermaid (11 semanas):
  ```mermaid
  gantt
    title Cronograma TFG Transitly
    dateFormat YYYY-MM-DD
    section Fase 1
    Análisis del contexto :2026-04-01, 14d
    section Fase 2
    Diseño del proyecto :2026-04-15, 14d
    section Fase 3
    Planificación :2026-04-29, 7d
    section Fase 4
    Desarrollo :2026-05-06, 28d
    section Fase 5
    Evaluación y manuales :2026-06-03, 7d
    section Defensa
    Preparación + defensa :2026-06-09, 7d
  ```
- Resumen: Scrum solo, sprints semanales, auditorías independientes (2026-05-22)

#### 10. **Lecciones aprendidas** (`Section10Lessons.astro`)

Contenido:
- 4 cards con reflexiones:
  - "La documentación como contrato verificable evita el drift"
  - "Una auditoría independiente vale más que 100 self-reviews"
  - "Las IAs como colaboradoras requieren governance estricta"
  - "Cierre real ≠ cierre documental"

#### 11. **Trabajo futuro** (`Section11FutureWork.astro`)

Contenido:
- 4 items:
  - **iOS:** preparado el código, requiere $99/año Apple Dev
  - **GTFS-Realtime:** integración cuando operadores expongan API
  - **Modelo ML:** predicción ETA basada en histórico
  - **Multi-ciudad:** expansión más allá de COMUJESA Jerez

#### 12. **Equipo y reconocimientos** (`Section12Team.astro`)

Contenido:
- Autor: nombre + foto + GitHub
- Tutor académico
- Herramientas: Flutter, Supabase, Firebase, Sentry, PostHog (logos)
- Agradecimientos: comunidad OSS

#### 13. **Descargar / Probar** (`Section13Download.astro`, anchor `#descargar`)

Contenido:
- 2 CTAs grandes:
  - **Descargar APK Android** → URL release (ver Sección D)
    - Subtítulo: "Versión 1.0.0-tfg · 73 MiB · Android 6.0+"
  - **Ver web completa** → URL web Astro híbrida (ver Sección E)
    - Subtítulo: "Marketing site en desarrollo"

#### 14. **Footer** (`Footer.astro`)

Contenido:
- Repositorio GitHub link
- Contacto: email
- Licencia: MIT
- Última actualización: dinámico desde `import.meta.env.BUILD_DATE`

---

### B.4 — Datos canónicos centralizados

**Archivo:** `presentation/src/data/metrics.json`

```json
{
  "tests": {
    "passed": 619,
    "skipped": 6,
    "failed": 0
  },
  "coverage": {
    "global": 24.04,
    "target": 60
  },
  "code": {
    "features": 27,
    "migrations": 14,
    "edgeFunctions": 4,
    "ciJobs": 6,
    "arbKeys": {
      "es": 642,
      "en": 628,
      "ar": 272
    },
    "hiveBoxes": 17,
    "encryptedBoxes": 2
  },
  "scorecard": {
    "tfg": 9.0,
    "production": 6.5
  },
  "release": {
    "apkSize": "73,5 MiB",
    "version": "1.0.0-tfg",
    "platforms": ["Android"]
  },
  "context": {
    "operator": "COMUJESA",
    "city": "Jerez de la Frontera",
    "users": {
      "urbanRiders2024": "1.500M",
      "interurbanRiders2024": "600M"
    }
  }
}
```

Importar en cualquier componente:

```astro
---
import metrics from '../data/metrics.json';
---
<p>{metrics.tests.passed} tests pasando</p>
```

---

### B.5 — Commit secciones

```powershell
git add presentation/src/
git commit -m "feat(presentation): añadir 14 secciones landing + datos canónicos (B)"
```

---

<a id="c-mapping"></a>
## C. Mapping contenido docs/tfg → secciones web

**Objetivo:** asegurar que cada doc TFG está reflejado en la web.

**Esfuerzo:** ~1 h (lectura + extracción)

---

### C.1 — Tabla de mapping

| Doc TFG | Sección(es) web destino | Contenido a extraer |
|---------|-------------------------|---------------------|
| `01_analisis_contexto.md` | Section02Problem, Section03Solution | Sector, problema, 3 carencias detectadas, oportunidades |
| `02_diseno_proyecto.md` | Section03Solution, Section05Architecture, Section08Quality | 12 objetivos funcionales, no funcionales, viabilidad técnica, indicadores |
| `03_planificacion.md` | Section09Methodology | Scrum solo, Gantt, recursos, riesgos R01-R13 |
| `04_desarrollo_implementacion.md` | Section05Architecture, Section08Quality | 4 capas datos, 14 migraciones, 4 Edge Functions, 619 tests, 5 ADRs |
| `05_evaluacion_documentacion.md` | Section08Quality, Section10Lessons | 12 incidencias, feedback SUS, lecciones aprendidas |
| `06_manual_tecnico.md` | Section11FutureWork | Roadmap iOS, GTFS-Realtime, ML |
| `07_manual_usuario.md` | Section04Demo, Section13Download | Flujos clave para demo + descarga app |
| `08_presentacion.md` | Section01Hero, Section10Lessons, Section11FutureWork | Pitch, conclusiones, trabajo futuro |

---

### C.2 — Procedimiento de extracción

Para cada sección web:

1. **Leer el(los) doc(s) origen** correspondientes.
2. **Extraer 3-5 puntos clave** (no copiar texto completo — la web es resumen visual).
3. **Adaptar al formato web:** cards, tablas, listas con iconos.
4. **Verificar cifras canónicas** contra `metrics.json` (no inventar).
5. **Citas literales** solo en bloques `<blockquote>` claramente marcados.

---

### C.3 — Ejemplo: Section02Problem

**Doc origen:** `docs/tfg/01_analisis_contexto.md` §1 "Sector y problema"

**Extracto literal del doc:**
> "El sector del transporte público colectivo en ciudades medias españolas presenta tres carencias estructurales: ausencia de GPS en tiempo real, fragmentación de aplicaciones por operador, y accesibilidad insuficiente."

**Versión web (Section02Problem.astro):**

```astro
<section id="problema" class="py-24 px-6 max-w-6xl mx-auto">
  <h2 class="text-4xl font-bold mb-4">El problema</h2>
  <p class="text-transit-text-mid mb-12 text-lg max-w-3xl">
    El transporte público de ciudades medias españolas presenta carencias estructurales que afectan a más de 2.000 millones de viajeros al año.
  </p>

  <div class="grid md:grid-cols-3 gap-6">
    <article class="bg-transit-bg-surface p-6 rounded-2xl border border-transit-bg-raised">
      <div class="text-transit-state-cancelled text-3xl font-mono mb-2">01</div>
      <h3 class="text-xl font-bold mb-2">Sin GPS en tiempo real</h3>
      <p class="text-transit-text-mid">Los usuarios no saben dónde está su bus. Los horarios estáticos rara vez reflejan la realidad operativa.</p>
    </article>

    <article class="bg-transit-bg-surface p-6 rounded-2xl border border-transit-bg-raised">
      <div class="text-transit-state-cancelled text-3xl font-mono mb-2">02</div>
      <h3 class="text-xl font-bold mb-2">Fragmentación por operador</h3>
      <p class="text-transit-text-mid">Cada ciudad tiene su propia app. Un viajero entre Jerez y Cádiz necesita tres apps con tres interfaces.</p>
    </article>

    <article class="bg-transit-bg-surface p-6 rounded-2xl border border-transit-bg-raised">
      <div class="text-transit-state-cancelled text-3xl font-mono mb-2">03</div>
      <h3 class="text-xl font-bold mb-2">Accesibilidad pobre</h3>
      <p class="text-transit-text-mid">Sin lector de pantalla, sin RTL para árabe, sin alto contraste o filtros de daltonismo en la mayoría de apps.</p>
    </article>
  </div>
</section>
```

Repetir el mismo procedimiento para las 14 secciones.

---

<a id="d-apk"></a>
## D. APK descargable desde GitHub Releases

**Objetivo:** crear una release etiquetada en GitHub con el APK como asset descargable.

**Esfuerzo:** ~30 min

---

### D.1 — Generar APK release firmado

**Pre-requisito:** `android/key.properties` configurado (ver `PLAN_RELEASE_ANDROID_2026_05_25.md §A.6-A.7`).

```powershell
cd C:\Users\k\Desktop\all\clase\nexto-stop-v2
flutter clean
flutter pub get
flutter build apk --release --obfuscate --split-debug-info=build/symbols
```

**Verificación:**
```powershell
ls build/app/outputs/flutter-apk/app-release.apk
# Esperado: ~73 MiB
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk
# Esperado: "jar verified"
```

---

### D.2 — Crear tag local

```powershell
git tag -a v1.0.0-tfg -m "Release v1.0.0-tfg — versión defensa TFG 2026-06-09"
```

Verificar:
```powershell
git tag -l
# Esperado: v1.0.0-tfg
```

---

### D.3 — Push tag a remote

```powershell
git push origin v1.0.0-tfg
```

---

### D.4 — Crear release en GitHub (CLI)

**Pre-requisito:** `gh` CLI instalado y autenticado (`gh auth login`).

```powershell
gh release create v1.0.0-tfg `
  build/app/outputs/flutter-apk/app-release.apk `
  --title "Transitly v1.0.0 — Defensa TFG" `
  --notes "Primera versión completa de Transitly para defensa TFG 2026-06-09.

## Características principales

- Transporte público COMUJESA Jerez en tiempo real
- Mapa interactivo con paradas y buses
- Lectura NFC de tarjetas del Consorcio Andalucía
- Modo offline con regiones descargables
- Sistema comunitario de reportes e incidencias
- 3 idiomas (ES/EN/AR) con soporte RTL
- Accesibilidad WCAG 2.2 AA estructural

## Métricas

- 619 tests pasando
- 14 migraciones SQL
- 4 Edge Functions
- 27 features
- 6 jobs CI verde
- Scorecard TFG 9,0/10

## Requisitos

- Android 6.0 (API 23) o superior
- ~73 MiB de espacio en disco
- Conexión a internet recomendada (modo offline disponible)

## Instalación

1. Descarga el APK
2. En tu Android: Ajustes → Seguridad → Permitir instalación desde fuentes desconocidas
3. Abre el APK descargado e instala

## Documentación

- Web de presentación: https://astralk9999.github.io/Transitly/
- Documentación técnica (dartdoc): https://astralk9999.github.io/Transitly/api/
- Repositorio: https://github.com/astralk9999/Transitly"
```

**Verificación:**
- Visitar `https://github.com/astralk9999/Transitly/releases/tag/v1.0.0-tfg`
- Comprobar que `app-release.apk` aparece como asset descargable.

---

### D.5 — URL canónica del APK

La URL directa al asset:

```
https://github.com/astralk9999/Transitly/releases/download/v1.0.0-tfg/app-release.apk
```

Esta URL se usa en la web (`Section13Download.astro`) y en el botón del Hero.

---

### D.6 — Actualizar el botón en la web

En `presentation/src/components/Section13Download.astro` y `Section01Hero.astro`:

```astro
<a
  href="https://github.com/astralk9999/Transitly/releases/download/v1.0.0-tfg/app-release.apk"
  class="inline-block px-8 py-4 bg-transit-accent text-white rounded-full font-bold hover:bg-transit-accent/90 transition"
  download
>
  Descargar APK Android · 73 MiB
</a>
```

---

<a id="e-redirección"></a>
## E. Redirección a web Astro híbrida

**Objetivo:** botón "Ver web completa" que redirige a la web Astro existente.

**Esfuerzo:** ~15 min

---

### E.1 — Decidir destino

**Opciones:**

| Opción | URL | Estado |
|--------|-----|--------|
| Astro deployado en Vercel | `https://transitly.vercel.app` | Requiere deploy previo |
| Astro deployado en Cloudflare Pages | `https://transitly.pages.dev` | Requiere deploy previo |
| Repositorio GitHub | `https://github.com/astralk9999/Transitly/tree/master/astro` | Sin deploy, sólo código |

**Recomendación:** si no hay tiempo de deployar la Astro híbrida antes de defensa, enlazar al repositorio con un disclaimer "en desarrollo".

---

### E.2 — Botón en Hero y Section13

En `Section01Hero.astro`:

```astro
<a
  href="https://transitly.pages.dev"
  class="inline-block px-8 py-4 border border-transit-accent text-transit-accent rounded-full font-bold hover:bg-transit-accent-bg transition"
  target="_blank"
  rel="noopener noreferrer"
>
  Ver web completa →
</a>
```

Si la web Astro híbrida no está deployada, usar URL del repo:

```astro
<a
  href="https://github.com/astralk9999/Transitly/tree/master/astro"
  class="inline-block px-8 py-4 border border-transit-text-mid text-transit-text-mid rounded-full font-bold cursor-not-allowed opacity-60"
  target="_blank"
  rel="noopener noreferrer"
  title="Web híbrida en desarrollo"
>
  Web completa (en desarrollo) →
</a>
```

---

<a id="f-workflow"></a>
## F. Workflow GitHub Pages para `presentation/`

**Objetivo:** deploy automático al hacer push a `master` si tocan `presentation/`.

**Esfuerzo:** ~30 min

---

### F.1 — Crear workflow

**Archivo nuevo:** `.github/workflows/deploy-presentation.yml`

```yaml
name: Deploy Presentation to GitHub Pages

on:
  push:
    branches: [master]
    paths:
      - 'presentation/**'
      - '.github/workflows/deploy-presentation.yml'
  workflow_dispatch:

permissions:
  contents: read
  pages: write
  id-token: write

# Permitir un solo deploy concurrente
concurrency:
  group: 'pages-presentation'
  cancel-in-progress: false

jobs:
  build:
    name: Build Astro
    runs-on: ubuntu-latest
    timeout-minutes: 10
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: presentation/package-lock.json

      - name: Install dependencies
        working-directory: presentation
        run: npm ci

      - name: Build Astro site
        working-directory: presentation
        run: npm run build

      - name: Deploy to gh-pages branch (root)
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: presentation/dist
          publish_branch: gh-pages
          keep_files: true   # NO borra el subdirectorio /api/ deployado por docs.yml
          commit_message: "deploy: presentation site update"
```

**Importante:** `keep_files: true` es crítico. Sin esto, el deploy de la presentación borraría el subpath `/api/` con el dartdoc.

---

### F.2 — Commit

```powershell
git add .github/workflows/deploy-presentation.yml
git commit -m "ci: workflow GH Pages para deploy de presentation/ (F)"
```

---

<a id="g-dartdoc"></a>
## G. Mover dartdoc a `/api/` subpath

**Objetivo:** que dartdoc deje de ocupar la raíz de GH Pages y pase a `/api/`.

**Esfuerzo:** ~20 min

---

### G.1 — Estrategia elegida: peaceiris/actions-gh-pages

Ambos workflows (`docs.yml` para dartdoc y `deploy-presentation.yml` para la web) usan `peaceiris/actions-gh-pages@v4` con `publish_branch: gh-pages` y `keep_files: true`.

Esto permite que **coexistan en la misma rama `gh-pages`**:
- Presentación → raíz `/`
- Dartdoc → subdirectorio `/api/`

---

### G.2 — Editar `.github/workflows/docs.yml`

**Archivo:** `.github/workflows/docs.yml`

**Cambio:**

```yaml
# ANTES (líneas 33-37):
- name: Deploy to GitHub Pages
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: doc/api

# DESPUÉS:
- name: Deploy to GitHub Pages (api subpath)
  uses: peaceiris/actions-gh-pages@v4
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    publish_dir: doc/api
    publish_branch: gh-pages
    destination_dir: api      # ← AÑADIR
    keep_files: true          # ← AÑADIR (no borrar la presentación)
    commit_message: "deploy: dartdoc api update"
```

---

### G.3 — Commit

```powershell
git add .github/workflows/docs.yml
git commit -m "ci(docs): mover dartdoc a /api/ subpath con keep_files (G)"
```

---

<a id="h-pages-settings"></a>
## H. Configurar GitHub Pages settings

**Esfuerzo:** ~5 min

---

### H.1 — Pasos en GitHub

1. Ir a `https://github.com/astralk9999/Transitly/settings/pages`
2. **Source:** Deploy from a branch
3. **Branch:** `gh-pages` / `(root)`
4. **Custom domain:** dejar vacío
5. Click **Save**

---

### H.2 — Verificar primera vez

Tras el primer push a `master` que toque `presentation/`, esperar ~2 min y comprobar:

- `https://astralk9999.github.io/Transitly/` → web de presentación TFG
- `https://astralk9999.github.io/Transitly/api/` → dartdoc

Si tarda más de 5 min, revisar la pestaña **Actions** del repo por errores.

---

<a id="i-verificación"></a>
## I. Verificación end-to-end

**Esfuerzo:** ~30 min

---

### I.1 — Verificación local

```powershell
cd presentation
npm install
npm run build

# Inspeccionar el build
ls dist
# Esperado: index.html, _astro/, favicon.svg, og-image.png, etc.

# Preview local
npm run preview
# Abrir http://localhost:4321/Transitly/ en el navegador
```

**Checklist local:**
- [ ] Todas las 14 secciones visibles
- [ ] Navegación superior funciona (anclas)
- [ ] Botón "Descargar APK" tiene URL correcta
- [ ] Botón "Ver web completa" tiene URL correcta
- [ ] Imágenes/iconos cargan
- [ ] Responsive en móvil (resize ventana o DevTools mobile mode)
- [ ] Sin errores en consola del navegador
- [ ] Mermaid renderiza (si lo añadimos vía CDN)

---

### I.2 — Verificación remota tras deploy

```powershell
# Push para activar el workflow
git push origin master

# Esperar ~2 min y comprobar:
curl -I https://astralk9999.github.io/Transitly/
# Esperado: HTTP 200

curl -I https://astralk9999.github.io/Transitly/api/
# Esperado: HTTP 200

# APK descargable
curl -I https://github.com/astralk9999/Transitly/releases/download/v1.0.0-tfg/app-release.apk
# Esperado: HTTP 302 (redirect) → 200
```

---

### I.3 — Smoke test web (navegador real)

1. Abrir `https://astralk9999.github.io/Transitly/` en Chrome desktop.
2. Hacer scroll lento desde Hero hasta Footer. Cada sección debe verse completa.
3. Click en "Descargar APK" → descarga inicia.
4. Click en "Ver web completa" → abre nueva pestaña con la URL configurada.
5. Hover sobre enlaces nav → cambio de color.
6. Abrir DevTools (F12) → Lighthouse → ejecutar audit.
   - Performance > 90
   - Accessibility > 95
   - Best Practices > 95
   - SEO > 90
7. Cambiar a Mobile mode (Chrome DevTools) → comprobar responsive.

---

<a id="j-cumplimiento"></a>
## J. Cumplimiento guía TFG

**Objetivo:** confirmar que la web cubre **todos** los entregables exigidos por la guía.

---

### J.1 — Tabla entregables guía TFG

| Entregable guía | Cubierto en web | Sección | Notas |
|-----------------|:-:|---------|-------|
| Memoria del Proyecto (PDF) | ✓ | Toda la página | La web ES la memoria visual |
| Aplicación Final (APK) | ✓ | Section13Download | URL release GitHub |
| Documentación Técnica | ✓ | Section11FutureWork + link a `/api/` | Dartdoc en subpath |
| Manual de Usuario | ✓ | Section04Demo + Section13 | Demo + instrucciones |
| Presentación Final (slides PDF) | ✓ | Toda la página | La web reemplaza al PDF |
| Diagrama Gantt y cronograma | ✓ | Section09Methodology | Gantt Mermaid embebido |
| Evaluación del Proyecto | ✓ | Section08Quality + Section10Lessons | Cifras + incidencias |

**Veredicto:** la web cubre los 7 entregables exigidos. El PDF de memoria sigue existiendo en `docs/tfg/` por si el tribunal lo solicita por separado.

---

### J.2 — Mapping con las 5 fases de la guía

| Fase guía | Sección(es) web | Cumplimiento |
|-----------|-----------------|--------------|
| **Fase 1 — Análisis del Contexto** | Section02Problem, Section03Solution | Sector, problema, oportunidades |
| **Fase 2 — Diseño del Proyecto** | Section03Solution, Section05Architecture | Objetivos, viabilidad, indicadores |
| **Fase 3 — Planificación** | Section09Methodology | Gantt, recursos, riesgos |
| **Fase 4 — Desarrollo** | Section05Architecture, Section08Quality | Arquitectura, tests, integración |
| **Fase 5 — Evaluación** | Section08Quality, Section10Lessons | Incidencias, feedback, lecciones |

---

### J.3 — Criterios de evaluación de la guía

| Criterio | Peso | Cobertura web |
|----------|:----:|---------------|
| Análisis del contexto y diseño | 20 % | Section02-03, Section05 |
| Planificación y documentación técnica | 20 % | Section09, link `/api/` |
| Desarrollo técnico de la aplicación | 30 % | Section05-08, link APK |
| Calidad y funcionalidad del resultado | 15 % | Section08, demo Section04 |
| Presentación y defensa oral | 15 % | Toda la web ES la presentación |

---

<a id="k-cronograma"></a>
## K. Cronograma sugerido

**Defensa:** 2026-06-09 (15 días vista desde hoy 2026-05-25).

| Día | Fase | Acción | Esfuerzo |
|-----|------|--------|---------:|
| **D-15 (hoy)** | A | Setup Astro estático en `presentation/` | 1 h |
| **D-14** | B | Layout + 14 secciones (estructura HTML) | 2 h |
| **D-13** | C | Extraer contenido de docs/tfg → secciones | 1 h |
| **D-12** | D | Generar APK release + crear release v1.0.0-tfg | 30 min |
| **D-11** | E + F | Botón redirección + workflow GH Pages | 1 h |
| **D-10** | G + H | Mover dartdoc a /api/ + configurar Pages | 25 min |
| **D-9** | I | Verificación end-to-end (local + remoto) | 30 min |
| **D-7** | — | Polish visual (responsive, animaciones, dark mode opcional) | 1 h |
| **D-5** | — | Ensayo defensa usando la web como apoyo (cronometrar) | 30 min |
| **D-3** | — | Repaso final + smoke test web en distintos navegadores | 30 min |
| **D-1** | — | Backup HTML/dist + verificar URL accesible | 15 min |
| **D-0 (2026-06-09)** | — | Defensa: pantalla con la web en primer plano | — |

**Total esfuerzo:** ~7-8 horas distribuidas.

---

<a id="l-resumen"></a>
## L. Resumen ejecutivo

| Bloque | Items | Esfuerzo | Coste |
|--------|------:|---------:|------:|
| A — Setup Astro | 8 pasos | 1 h | €0 |
| B — Diseño landing | 14 secciones | 2 h | — |
| C — Mapping contenido | 8 docs | 1 h | — |
| D — Release APK | 6 pasos | 30 min | — |
| E — Redirección Astro | 2 | 15 min | — |
| F — Workflow CI | 1 | 30 min | — |
| G — Mover dartdoc | 1 | 20 min | — |
| H — Pages settings | 1 | 5 min | — |
| I — Verificación | 3 sub-pasos | 30 min | — |
| **TOTAL** | **~30 acciones** | **~6-8 h** | **€0** |

---

## Notas finales

- **URL final pública:** `https://astralk9999.github.io/Transitly/`
- **Subpath dartdoc:** `https://astralk9999.github.io/Transitly/api/`
- **APK URL canónica:** `https://github.com/astralk9999/Transitly/releases/download/v1.0.0-tfg/app-release.apk`
- **Backup local del build:** `presentation/dist/` (gitignored, regenerable con `npm run build`)
- **Idioma de la web:** español (el TFG es en español; añadir EN/AR sería trabajo extra opcional).
- **Defensa:** abrir la web en pantalla completa (F11) y navegar con scroll + búsqueda en página (Ctrl+F).

---

**FIN DEL PLAN**

> Documento generado el 2026-05-25. Cada paso es ejecutable directamente desde la raíz del repositorio.
> Cifras canónicas en Sección A "Reglas transversales" verificadas in-situ con `git log`, `flutter test` y `awk` sobre `coverage/lcov.info`.
> El workflow YAML de Sección F es válido y compatible con GitHub Pages oficial.
