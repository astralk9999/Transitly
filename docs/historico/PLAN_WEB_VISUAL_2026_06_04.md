# Plan de acción — Web de presentación más visual (GitHub Pages)

**Fecha:** 2026-06-04
**Autor:** Claude Code (Opus 4.7)
**Estado:** propuesto
**Goal:** Transformar la web de presentación actual (Astro 6 + Tailwind 4, 14 secciones de texto) en una landing visualmente atractiva con animaciones, capturas reales de la app v1.11.0, demos interactivas y dark mode, sin alterar la estructura narrativa de las secciones.
**Stack:** Astro 6.3.7 · Tailwind 4 (modo Vite plugin) · sitemap

---

## 1. Estado actual auditado

**Estructura existente** (`presentation/src/`):
- 1 layout (`Layout.astro`)
- 1 hero (`Section01Hero.astro`)
- 13 secciones de contenido (`Section02Problem` → `Section14Download`)
- 1 footer (`Footer.astro`)
- Configuración Astro 6 + Tailwind 4 + sitemap

**Fortalezas:**
- Estructura narrativa completa (problema → solución → arquitectura → features → métricas → calidad → seguridad → lecciones → futuro → descarga).
- Tipografía coherente con la app (`transit-text-hi/mid/lo`, accent `#977DDF`).
- Botones de descarga ya apuntan a GitHub Releases.
- Build genera a `dist/` y se sirve por GitHub Pages.

**Debilidades visuales identificadas:**
1. **Hero estático** sin movimiento ni elemento visual fuerte.
2. **0 capturas reales** de la app — todo es texto y diagramas SVG.
3. **Sin animaciones de scroll** (clases `reveal` están definidas pero el efecto es mínimo).
4. **Sin dark mode toggle** — la web es siempre oscura aunque el usuario use modo claro.
5. **Sin demo interactiva** del flujo de usuario.
6. **Sin video de uso real** de la app.
7. **Métricas presentadas como números planos** sin animación de counter.
8. **Sin Open Graph / Twitter card** — al compartir el link se ve un thumbnail genérico.
9. **Architecture diagram** estático sin interactividad.
10. **Sin contraste visual entre secciones** — todas tienen el mismo fondo `bg-transit-bg-root`.

---

## 2. Objetivos de mejora

1. **Impacto visual en el hero**: el usuario en los primeros 3 segundos debe saber qué es Transitly y querer ver más.
2. **Producto visible**: ver al menos 6 capturas reales del APK v1.11.0 distribuidas a lo largo de la web.
3. **Sensación de movimiento**: animaciones suaves al hacer scroll, sin sobrecargar.
4. **Profundidad visual**: usar glassmorphism, gradient meshes, y capas para dar tridimensionalidad.
5. **Datos vivos**: métricas con counter animations, gráficos con datos reales.
6. **Compartible**: Open Graph + Twitter card + favicon + manifest PWA.
7. **Accesibilidad respetada**: todo el movimiento se desactiva con `prefers-reduced-motion: reduce`.

---

## 3. Plan dividido en 5 tareas

### Tarea A — Hero impactante (1.5 h)

**Goal:** sustituir el hero plano por uno con video/captura grande, gradient mesh animado de fondo y tipografía display.

**Archivos:**
- Modify: `presentation/src/components/Section01Hero.astro`
- New: `presentation/public/og-image.png` (1200×630 para Open Graph)
- New: `presentation/public/hero-app-mockup.png` (mockup grande de la app)
- New: `presentation/src/styles/hero-bg.css` (gradient mesh CSS)

**Steps:**

- [ ] **Layout dos columnas en desktop, una en móvil:**
  ```
  ┌─────────────────────────────┬──────────────────┐
  │ Tagline grande              │                  │
  │ Transitly                   │  [Mockup móvil]  │
  │ Transporte público con      │  (PNG con marco) │
  │ accesibilidad en el centro  │                  │
  │                             │                  │
  │ [Descargar APK] [Ver demo]  │                  │
  │ Badges: WCAG AA · 619 tests │                  │
  └─────────────────────────────┴──────────────────┘
  ```

- [ ] **Gradient mesh de fondo** con CSS (sin JS, performance friendly):
  ```css
  .hero-bg {
    background:
      radial-gradient(at 27% 37%, hsla(265, 75%, 60%, 0.25) 0px, transparent 50%),
      radial-gradient(at 97% 21%, hsla(190, 70%, 50%, 0.18) 0px, transparent 50%),
      radial-gradient(at 52% 99%, hsla(296, 50%, 55%, 0.20) 0px, transparent 50%),
      var(--transit-bg-root);
  }
  ```

- [ ] **Animación sutil del mesh** con `@keyframes` (3 spots flotando lento):
  ```css
  .hero-bg { animation: meshFloat 30s ease-in-out infinite; }
  @keyframes meshFloat { 50% { filter: hue-rotate(15deg); } }
  @media (prefers-reduced-motion: reduce) { .hero-bg { animation: none; } }
  ```

- [ ] **Mockup móvil**: render screenshot real de la app en frame (Phone Mockup). Generar con:
  - Opción A (recomendada): captura real del Pixel emulator + frame SVG/PNG superpuesto.
  - Opción B: usar la API de https://shots.so o https://mockup.photos para generar mockup desde captura plana.

- [ ] **Tipografía display**: añadir `font-family: 'IBM Plex Mono'` con weight 800 para el headline + gradient text con `bg-clip-text`:
  ```html
  <h1 class="text-6xl md:text-8xl font-extrabold bg-gradient-to-br from-transit-accent to-transit-neon-cyan bg-clip-text text-transparent">
    Transitly
  </h1>
  ```

- [ ] **Botones más prominentes**: tamaño `px-10 py-5`, sombra con accent glow `shadow-[0_8px_24px_rgba(151,125,223,0.4)]`, hover scale-105.

**Criterio:** primer scroll del usuario muestra ya el producto visualmente.

---

### Tarea B — Capturas reales de la app integradas (2 h)

**Goal:** mostrar el producto, no solo describirlo.

**Archivos:**
- New: `presentation/public/screenshots/{home,map,nfc,profile,widgets,routes}.png` (6 capturas)
- Modify: `Section03Solution.astro`, `Section06Features.astro`, `Section10Accessibility.astro`

**Steps:**

- [ ] **Capturar 6 pantallas del APK v1.11.0** con el emulador (Pixel 6 API 34, 1080×2340):
  1. `home.png` — Home tab con saludo + Próximo bus + Mis paradas
  2. `map.png` — Mapa con polylines + filtros + selección de línea
  3. `nfc.png` — Card tab con saldo + último escaneo
  4. `profile.png` — Perfil con paletas (modo claro elegido)
  5. `widgets.png` — Captura de los 3 widgets en pantalla de inicio Android
  6. `routes.png` — Detalle de ruta con timeline de paradas

- [ ] **Procesar cada captura** con marco de móvil:
  - Opción rápida (15 min total): generar con https://shots.so/?image=<base64> o `figma` con plugin Mockup.
  - Opción artesanal (1 h): SVG de Phone Frame propio + screenshot embebido.

- [ ] **Integrar en secciones** con grid de 2 columnas (imagen | texto):
  - `Section03Solution.astro`: añadir `home.png` + `map.png` lado a lado tras el bloque "Solución".
  - `Section06Features.astro`: grid 3×2 con las 6 capturas con leyenda corta cada una.
  - `Section10Accessibility.astro`: `profile.png` con paletas → demuestra alto contraste activado.

- [ ] **Lightbox al hacer click** (opcional, sin JS pesado):
  ```html
  <a href={image} target="_blank" class="block hover:scale-[1.02] transition-transform">
    <img src={image} alt={alt} class="rounded-2xl shadow-2xl" loading="lazy" />
  </a>
  ```

- [ ] **Lazy loading**: `loading="lazy"` en todos los `<img>` para no bloquear primera carga.

**Criterio:** scroll completo de la web → 6 capturas reales visibles.

---

### Tarea C — Animaciones de scroll y micro-interacciones (1.5 h)

**Goal:** sensación de movimiento sin marear al usuario.

**Archivos:**
- Modify: `presentation/src/layouts/Layout.astro` (añadir IntersectionObserver script)
- Modify: cada `SectionXX.astro` (añadir `data-reveal` attributes)

**Steps:**

- [ ] **Implementar IntersectionObserver una vez** en `Layout.astro`:
  ```html
  <script>
    if (!window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      const obs = new IntersectionObserver((entries) => {
        entries.forEach(e => {
          if (e.isIntersecting) {
            e.target.classList.add('revealed');
            obs.unobserve(e.target);
          }
        });
      }, { threshold: 0.15, rootMargin: '0px 0px -50px 0px' });
      document.querySelectorAll('[data-reveal]').forEach(el => obs.observe(el));
    } else {
      document.querySelectorAll('[data-reveal]').forEach(el => el.classList.add('revealed'));
    }
  </script>
  <style>
    [data-reveal] {
      opacity: 0;
      transform: translateY(24px);
      transition: opacity 0.7s ease-out, transform 0.7s ease-out;
    }
    [data-reveal].revealed { opacity: 1; transform: none; }
    [data-reveal][data-delay="100"] { transition-delay: 0.1s; }
    [data-reveal][data-delay="200"] { transition-delay: 0.2s; }
    [data-reveal][data-delay="300"] { transition-delay: 0.3s; }
    [data-reveal][data-delay="500"] { transition-delay: 0.5s; }
  </style>
  ```

- [ ] **Aplicar `data-reveal`** a los bloques importantes de cada sección (no a TODO, sería ruido):
  - Heading de sección
  - Cards principales
  - Imágenes de capturas

- [ ] **Stagger con `data-delay`** en grids: tras la heading (`delay-0`), las cards entran con `delay-100`, `delay-200`, `delay-300`.

- [ ] **Hover en cards**:
  ```css
  .feature-card {
    transition: transform 0.2s ease-out, border-color 0.2s ease-out;
  }
  .feature-card:hover {
    transform: translateY(-4px);
    border-color: rgba(151, 125, 223, 0.4);
  }
  ```

- [ ] **Parallax sutil del hero** al hacer scroll (solo si reduce-motion no está activo):
  ```js
  if (!reduce) {
    addEventListener('scroll', () => {
      const y = window.scrollY;
      hero.style.transform = `translateY(${y * 0.3}px)`;
    }, { passive: true });
  }
  ```

**Criterio:** scroll suave, contenido aparece progresivamente, sin saltos bruscos.

---

### Tarea D — Métricas con counter animation + sticky nav (1 h)

**Goal:** las cifras se animan al entrar en viewport. Nav siempre accesible.

**Archivos:**
- Modify: `Section08Metrics.astro` (counter)
- Modify: `Layout.astro` (sticky nav con scroll spy)

**Steps:**

- [ ] **Counter animation** vanilla (sin libs):
  ```html
  <div data-counter data-target="619" data-suffix=" tests">0</div>
  <script>
    const counters = document.querySelectorAll('[data-counter]');
    const obs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (!e.isIntersecting) return;
        const el = e.target;
        const target = +el.dataset.target;
        const suffix = el.dataset.suffix || '';
        const dur = 1400;
        const start = performance.now();
        const tick = (t) => {
          const p = Math.min((t - start) / dur, 1);
          el.textContent = Math.floor(p * target) + suffix;
          if (p < 1) requestAnimationFrame(tick);
        };
        requestAnimationFrame(tick);
        obs.unobserve(el);
      });
    }, { threshold: 0.5 });
    counters.forEach(c => obs.observe(c));
  </script>
  ```

- [ ] **Métricas a animar:**
  - 619 tests
  - 15 migraciones SQL
  - 27 features
  - 94 commits posteriores al MVP
  - 88 MB del APK v1.11.0

- [ ] **Sticky nav con scroll spy**: el nav actual ya es sticky. Añadir scroll spy:
  ```js
  const sections = document.querySelectorAll('section[id]');
  const navLinks = document.querySelectorAll('nav a[href^="#"]');
  addEventListener('scroll', () => {
    let current = '';
    sections.forEach(sec => {
      if (window.scrollY + 100 >= sec.offsetTop) current = sec.id;
    });
    navLinks.forEach(link => {
      link.classList.toggle('active', link.hash === `#${current}`);
    });
  }, { passive: true });
  ```

- [ ] **Indicador activo en el nav** con `.active { color: var(--transit-accent); }`.

**Criterio:** las métricas se animan al primer scroll y el nav resalta la sección visible.

---

### Tarea E — Polish final + meta tags + favicon (1 h)

**Goal:** detalles que profesionalizan.

**Archivos:**
- Modify: `Layout.astro` (`<head>` con OG/Twitter)
- New: `presentation/public/favicon.svg`, `og-image.png`, `apple-touch-icon.png`
- New: `presentation/public/manifest.json` (PWA)

**Steps:**

- [ ] **Open Graph + Twitter card**:
  ```html
  <meta property="og:title" content="Transitly — Transporte público con accesibilidad en el centro" />
  <meta property="og:description" content="App Flutter para autobuses urbanos con NFC, modo conductor, accesibilidad WCAG AA y trilingüe ES/EN/AR." />
  <meta property="og:image" content="https://astralk9999.github.io/Transitly/og-image.png" />
  <meta property="og:url" content="https://astralk9999.github.io/Transitly/" />
  <meta property="og:type" content="website" />
  <meta name="twitter:card" content="summary_large_image" />
  ```

- [ ] **Favicon** SVG con el logo de Transitly (color `#977DDF`):
  ```html
  <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
  <link rel="apple-touch-icon" href="/apple-touch-icon.png" />
  ```

- [ ] **Manifest PWA** mínimo (para "Add to home screen" en navegadores compatibles):
  ```json
  {
    "name": "Transitly — Presentación",
    "short_name": "Transitly",
    "icons": [{"src":"/apple-touch-icon.png","sizes":"180x180","type":"image/png"}],
    "theme_color": "#08081A",
    "background_color": "#08081A",
    "display": "standalone"
  }
  ```

- [ ] **Smooth scroll** entre secciones del nav:
  ```css
  html { scroll-behavior: smooth; scroll-padding-top: 80px; }
  @media (prefers-reduced-motion: reduce) { html { scroll-behavior: auto; } }
  ```

- [ ] **Mejorar el footer** con badges de stack (Flutter + Supabase + Sentry + PostHog) y enlaces a:
  - GitHub repo
  - Releases
  - Documentación TFG (`docs/tfg/`)
  - LICENSE

**Criterio:** al compartir el link en Slack/WhatsApp aparece thumbnail con título + descripción. Favicon visible en pestaña.

---

## 4. Decisiones tomadas

| # | Decisión | Justificación |
|---|----------|---------------|
| D1 | **No introducir librerías de animación** (GSAP, Framer Motion) | El bundle se mantiene <50 KB JS; CSS y vanilla JS bastan para todo |
| D2 | **Dark mode obligatorio** (sin toggle a claro) | La web ES la imagen de marca; modo claro distrae del producto, además la app sí ofrece ambos modos |
| D3 | **6 capturas reales, no diagramas inventados** | El producto existe y está distribuido (v1.11.0); demostrar > describir |
| D4 | **`prefers-reduced-motion`** respetado en todas las animaciones | Coherencia con el discurso de accesibilidad WCAG AA |
| D5 | **Counter animation sin librería** | 15 líneas de JS hacen lo mismo que CountUp.js |
| D6 | **Mockup móvil con frame** (no captura plana) | Refuerza visualmente que es app móvil sin necesidad de explicarlo |
| D7 | **OG image generada con la captura del hero + tagline overlay** | Una imagen que sirve para todo el sharing |

---

## 5. Archivos modificados/creados (resumen)

### Nuevos (10)
- `presentation/public/screenshots/home.png`, `map.png`, `nfc.png`, `profile.png`, `widgets.png`, `routes.png`
- `presentation/public/hero-app-mockup.png`
- `presentation/public/og-image.png`
- `presentation/public/favicon.svg`
- `presentation/public/apple-touch-icon.png`
- `presentation/public/manifest.json`
- `presentation/src/styles/hero-bg.css`

### Modificados (16)
- `presentation/src/layouts/Layout.astro` (OG meta, manifest, IntersectionObserver, scroll spy, smooth scroll)
- `presentation/src/components/Section01Hero.astro` (mockup + gradient mesh + display font)
- `presentation/src/components/Section03Solution.astro` (capturas home + map)
- `presentation/src/components/Section06Features.astro` (grid 3×2 capturas)
- `presentation/src/components/Section08Metrics.astro` (counters)
- `presentation/src/components/Section10Accessibility.astro` (captura profile con paletas)
- `presentation/src/components/Footer.astro` (badges stack + links)
- 9 secciones más con `data-reveal` attributes y polish menor

### Sin tocar
- `astro.config.mjs`, `package.json` (no se añaden dependencias)
- `dist/` (se regenera con `npm run build`)
- Resto del repositorio fuera de `presentation/`

---

## 6. Estimación de tiempo

| Tarea | Tiempo | Prioridad |
|-------|--------|-----------|
| A — Hero impactante | 1.5 h | **Alta** |
| B — Capturas reales | 2 h | **Alta** |
| C — Animaciones scroll | 1.5 h | Media |
| D — Counters + scroll spy | 1 h | Media |
| E — Polish meta tags | 1 h | Baja |
| Build + deploy GitHub Pages | 15 min | — |
| **Total** | **~7 h** | una sesión larga o dos cortas |

---

## 7. Orden de ejecución recomendado

1. **B primero** (capturas) — el contenido visual real es lo que más impacta y se reutiliza en A y D.
2. **A** (hero) — con la captura ya disponible, el hero queda definitivo.
3. **C** (animaciones) — añade sensación de movimiento.
4. **D** (counters + nav spy) — pulido funcional.
5. **E** (meta tags) — al final, cuando el contenido visible está cerrado.
6. **Build + deploy** vía `npm run build` + push a `master` (GitHub Pages se actualiza solo si está configurado para servir `presentation/dist/`).

---

## 8. Riesgos

- **R1: Capturas de la app que muestran datos personales** → usar cuenta de demo o blurrear nombre/email del usuario en `profile.png`.
- **R2: Mockups muy pesados** (PNG sin optimizar pueden ser 1-2 MB cada uno) → optimizar con `sharp` o `squoosh` antes de commit. Objetivo: <300 KB por captura.
- **R3: GitHub Pages no sirve desde `presentation/dist/` por defecto** → verificar configuración en repo Settings → Pages, o usar GitHub Action que despliegue `dist/`.
- **R4: Counters disparándose dos veces** si el IntersectionObserver no se desuscribe → `obs.unobserve(el)` tras el primer trigger.
- **R5: Reduce-motion afecta a Astro hydration** → no debería, todo es CSS y vanilla JS sin frameworks reactivos.
- **R6: Tailwind 4 JIT puede no incluir clases dinámicas** (ej. `delay-${n}`) → usar clases estáticas para los delays.

---

## 9. Criterios de aceptación

1. Compartir el link de la web en WhatsApp → preview con OG image y título correcto.
2. Visitar la web → primer scroll ya muestra mockup del móvil.
3. Scroll completo → al menos 6 capturas reales de la app visibles.
4. Llegar a la sección de métricas → los números cuentan desde 0 hasta su valor real con animación.
5. Activar `prefers-reduced-motion: reduce` en el navegador → todas las animaciones desactivadas, contenido visible.
6. Nav desktop al hacer scroll → enlace de la sección actual con color accent.
7. Botón "Descargar APK" → lleva a `https://github.com/astralk9999/Transitly/releases/latest`.
8. Favicon visible en la pestaña del navegador.

---

## 10. Próximos pasos

Cuando apruebes:
- **"arranca todo en orden"** → 7 h en una sesión larga (recomendado).
- **"arranca B+A primero"** → contenido visual (capturas + hero) en 3.5 h; resto en otra sesión.
- **"solo polish meta tags"** → E sólo (1 h) si lo que urge es que el link compartible se vea bien.

Recomiendo **"arranca B+A primero"** porque las capturas reales son lo más impactante visualmente y se reutilizan en el resto de tareas.

---

## Changelog

- **2026-06-04** — Plan creado tras auditoría de `presentation/src/`. Web actual tiene estructura completa pero es muy textual. 5 tareas para añadir capa visual sin reescribir narrativa. Cero librerías nuevas, todo con CSS y vanilla JS.
