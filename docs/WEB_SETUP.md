# WEB_SETUP.md — Transitly Web híbrida (Astro + Flutter Web)

> F23: Setup del monorepo Astro, páginas SSR, Flutter Web islands.

---

## Requisitos

- **Node.js** >= 18 (`node --version`)
- **npm** >= 9 (`npm --version`)
- **Flutter** >= 3.24 (`flutter --version`)
- Supabase project (mismo que la app móvil)

---

## Estructura

```
/                       ← Flutter (raíz, sin cambios)
/astro/                 ← Proyecto Astro (SSR + páginas públicas)
/astro/src/
  layouts/Layout.astro  ← Layout global (header, footer, SEO meta)
  pages/
    index.astro         ← Landing page (hero, features, stats live)
    sobre.astro         ← Acerca de
    privacidad.astro    ← Política de privacidad
    terminos.astro      ← Términos de uso
    ciudades/
      index.astro       ← Lista de operadores (SSR desde Supabase)
      [slug].astro      ← Detalle de operador + mapa estático
    rutas/
      [slug].astro      ← Detalle de ruta + paradas + horarios
    app/
      editor/index.astro   ← Flutter Web island (editor de rutas)
      admin/index.astro    ← Flutter Web island (panel admin)
      map/index.astro      ← Flutter Web island (mapa interactivo)
/web/                   ← Build de Flutter Web (generado por flutter)
/tools/build_web.ps1    ← Script PowerShell para build web
```

---

## Setup inicial

### 1. Variables de entorno (Astro)

```bash
cd astro
cp .env.example .env
```

Edita `.env` con los valores reales:

```
PUBLIC_SUPABASE_URL=https://mmzahxtiaurkgtmtehxk.supabase.co
PUBLIC_SUPABASE_ANON_KEY=<tu-anon-key>
PUBLIC_MAPTILER_API_KEY=<tu-key-maptiler>
```

### 2. Instalar dependencias

```bash
cd astro
npm install
```

### 3. Desarrollo local

```bash
cd astro
npm run dev          # http://localhost:4321
```

### 4. Build de producción

```bash
cd astro
npm run build        # Genera astro/dist/ (SSR standalone)
```

---

## Flutter Web islands

Las páginas bajo `/app/*` cargan una build de Flutter Web como un iframe/island.

### Build rápido (modo dev)

```bash
flutter build web --release --base-href "/app/" --pwa-strategy none
```

La build se genera en `build/web/`. Para que Astro la sirva, cópiala a `astro/public/flutter-web-build/` o usa el script:

```powershell
.\tools\build_web.ps1
```

### Entry points mínimos

Para builds más ligeras (una por feature), crea entry points en `lib/web_entry/`:

```
lib/web_entry/
  editor_main.dart    # runApp solo con RouteEditor
  admin_main.dart     # runApp solo con AdminPanel
  map_main.dart       # runApp solo con MapScreen
```

Build por feature:

```bash
flutter build web --release --base-href "/app/editor/" --pwa-strategy none -t lib/web_entry/editor_main.dart
flutter build web --release --base-href "/app/admin/" --pwa-strategy none -t lib/web_entry/admin_main.dart
flutter build web --release --base-href "/app/map/" --pwa-strategy none -t lib/web_entry/map_main.dart
```

---

## Despliegue en Astro

El adaptador `@astrojs/node` permite desplegar como servidor Node standalone:

```bash
cd astro
npm run build
node dist/server/entry.mjs   # Inicia en puerto 4321
```

Para producción, usa PM2, Docker o el servicio de hosting que prefieras.

### Docker (opcional)

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY astro/dist/server ./dist/server
COPY astro/public ./public
EXPOSE 4321
CMD ["node", "dist/server/entry.mjs"]
```

---

## SEO

- **Sitemap:** `/sitemap-index.xml` y `/sitemap-0.xml` (generado por `@astrojs/sitemap`)
- **Robots.txt:** `/robots.txt` (incluido en `astro/public/`)
- **Open Graph / Twitter Cards:** cada página define `og:title`, `og:description`, `og:image`
- **Schema.org:** JSON-LD embebido en páginas de operador (`BusOrCoachStation`) y ruta (`BusTrip`)
- **Meta description** única por página, generada en SSR

## Tailwind config

Los tokens de diseño en `astro/tailwind.config.mjs` replican `TransitColorScheme` y `TransitTypography`:

| Token CSS | Valor |
|-----------|-------|
| `transit-bg` | `#08081A` |
| `transit-surface` | `#10102A` |
| `transit-accent` | `#977DDF` |
| `transit-neon-cyan` | `#00D4FF` |
| `transit-neon-magenta` | `#FF006E` |
| `text-hi` | `#F8F8FF` |
| `text-mid` | `#A0A0B8` |

Fuentes: **DM Sans** (UI) + **IBM Plex Mono** (datos/código).

---

## CI/CD (GitHub Actions sugerido)

```yaml
# .github/workflows/web-deploy.yml
name: Deploy Web
on:
  push:
    branches: [master]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 20 }
      - run: cd astro && npm ci && npm run build
      # Deploy astro/dist/ a tu hosting (Railway, Vercel, etc.)
```
