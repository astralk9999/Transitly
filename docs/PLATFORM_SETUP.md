# Platform Setup — Transitly

> Guía unificada de configuración para todas las plataformas de Transitly:
> Firebase/FCM, MapTiler, Web (Astro + Flutter), Widgets nativos, y Wearables.

---

# 1. Firebase / FCM

> Fase F21 · Push notifications

## 1.1 Create Firebase project

1. Go to https://console.firebase.google.com
2. Click **Add project** → name it `transitly`
3. Enable Google Analytics (optional but recommended)
4. Click **Create project** and wait for provisioning

## 1.2 Android: google-services.json

1. In Firebase Console → **Project settings** → **Add app** → **Android**
2. Package name: match `android/app/build.gradle.kts` (default: `com.transitly.transitly`)
3. SHA-1 (optional; needed later for dynamic links / phone auth)
4. Click **Register app**, then **Download google-services.json**
5. Place at: `android/app/google-services.json`
6. The `android/build.gradle.kts` and `android/app/build.gradle.kts` already contain the Google Services plugin

## 1.3 iOS: GoogleService-Info.plist

1. In Firebase Console → **Project settings** → **Add app** → **iOS**
2. Bundle ID: match Xcode project → Runner target (default: `com.transitly.app`)
3. Click **Register app**, then **Download GoogleService-Info.plist**
4. Place at: `ios/Runner/GoogleService-Info.plist`
5. In Xcode: drag into Runner → ensure **Copy items if needed** is checked, target membership includes `Runner`

## 1.4 iOS: APNs key (required for notifications)

1. https://developer.apple.com → **Certificates, Identifiers & Profiles**
2. Under **Keys**, create a new **APNs Auth Key**
3. Download the `.p8` file and note the **Key ID**
4. In Firebase Console → **Project settings** → **Cloud Messaging** → **Apple app configuration**
5. Upload `.p8`, enter Key ID and Apple Team ID
6. Enable **Push Notifications** capability in Xcode → Runner → **Signing & Capabilities** → **+ Capability** → **Push Notifications**

## 1.5 firebase_options.dart (recommended)

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=transitly
```

Generates `lib/firebase_options.dart`. Update `lib/data/push/firebase_setup.dart`:

```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 1.6 Test notification

1. Firebase Console → **Cloud Messaging** → **Send your first message**
2. Enter title and body → **Send test message**
3. Add an FCM registration token (logged by the app)
4. Click **Test**

## 1.7 Troubleshooting

| Symptom | Check |
|---------|-------|
| App crashes on start | Verify `google-services.json` or `GoogleService-Info.plist` exists |
| No token generated | Check network / Google Play Services (Android) / APNs (iOS) |
| iOS: no notification permission | Ensure `Info.plist` has no `FirebaseMessagingAutoInitEnabled = false` |
| Notifications not received in background | iOS: APNs key uploaded; Android: correct priority |

---

# 2. MapTiler

> Fase F20 · Tile provider para producción

## 2.1 Registro y API key

1. Crear cuenta en https://cloud.maptiler.com
2. Obtener API key desde el dashboard
3. Añadir al `.env`:

```
MAPTILER_API_KEY=<tu-api-key>
```

## 2.2 Estilos disponibles

| Estilo | URL | Uso recomendado |
|--------|-----|-----------------|
| `streets-v2` | `https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={key}` | General |
| `basic-v2` | `https://api.maptiler.com/maps/basic-v2/{z}/{x}/{y}.png?key={key}` | Limpio, movilidad |
| `bright-v2` | `https://api.maptiler.com/maps/bright-v2/{z}/{x}/{y}.png?key={key}` | Alto contraste |

Seleccionables desde Apariencia → "Estilo de mapa".

## 2.3 Atribución obligatoria

Mostrar en una esquina del mapa: **© OpenStreetMap contributors · MapTiler**

## 2.4 Límites free tier

- 100.000 tiles/mes (gratis)
- Monitorizar uso desde https://cloud.maptiler.com/usage

## 2.5 Failover

Si MapTiler responde 5xx repetido, fallback temporal a OSM público con banner "Servicio degradado". Log via `[Map]` tag.

---

# 3. Web (Astro + Flutter)

> Fase F23 · Monorepo híbrido: Astro SSR + Flutter Web islands

## 3.1 Requisitos

- **Node.js** >= 18
- **npm** >= 9
- **Flutter** >= 3.24
- Supabase project (mismo que la app móvil)

## 3.2 Estructura

```
/                       ← Flutter (raíz, sin cambios)
/astro/                 ← Proyecto Astro (SSR + páginas públicas)
/astro/src/
  layouts/Layout.astro  ← Layout global (header, footer, SEO meta)
  pages/
    index.astro         ← Landing page
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

## 3.3 Variables de entorno (Astro)

```bash
cd astro
cp .env.example .env
```

`.env`:

```
PUBLIC_SUPABASE_URL=https://mmzahxtiaurkgtmtehxk.supabase.co
PUBLIC_SUPABASE_ANON_KEY=<tu-anon-key>
PUBLIC_MAPTILER_API_KEY=<tu-key-maptiler>
```

## 3.4 Instalar y ejecutar

```bash
cd astro
npm install
npm run dev          # http://localhost:4321
npm run build        # astro/dist/ (SSR standalone)
```

## 3.5 Flutter Web islands

Las páginas bajo `/app/*` cargan una build de Flutter Web como iframe/island.

### Build rápido

```bash
flutter build web --release --base-href "/app/" --pwa-strategy none
```

La build se genera en `build/web/`. Para que Astro la sirva, cópiala a `astro/public/flutter-web-build/` o usa:

```powershell
.\tools\build_web.ps1
```

### Entry points por feature

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

## 3.6 Despliegue

```bash
cd astro
npm run build
node dist/server/entry.mjs   # Puerto 4321
```

### Docker

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY astro/dist/server ./dist/server
COPY astro/public ./public
EXPOSE 4321
CMD ["node", "dist/server/entry.mjs"]
```

## 3.7 SEO

- **Sitemap:** `/sitemap-index.xml`, `/sitemap-0.xml` (generado por `@astrojs/sitemap`)
- **Robots.txt:** `/robots.txt`
- **Open Graph / Twitter Cards:** `og:title`, `og:description`, `og:image`
- **Schema.org:** JSON-LD en páginas de operador (`BusOrCoachStation`) y ruta (`BusTrip`)

## 3.8 Tailwind tokens

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

## 3.9 CI/CD (GitHub Actions)

```yaml
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
```

---

# 4. Widgets nativos

> Fase F24 · Home widgets para Android e iOS vía SharedPreferences/App Group

## 4.1 Contrato JSON

### Próximo bus (`next_bus_<routeCode>`)

```json
{
  "stopName": "Plaza del Caballo",
  "routeCode": "L1",
  "etaMinutes": 8,
  "source": "driver",
  "updatedAt": "2026-05-15T10:23:00.000Z"
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `stopName` | String | Nombre de la parada |
| `routeCode` | String | Código de la ruta |
| `etaMinutes` | int | Minutos estimados hasta llegada |
| `source` | String | `driver`, `official`, `estimated` |
| `updatedAt` | ISO 8601 | Última actualización |

### Estado de línea (`line_status_<routeCode>`)

```json
{
  "routeCode": "M2",
  "upcoming": [
    {"stopName": "Plaza del Caballo", "etaMinutes": 5},
    {"stopName": "Estación FFCC", "etaMinutes": 14},
    {"stopName": "Hospital", "etaMinutes": 22}
  ],
  "updatedAt": "2026-05-15T10:23:00.000Z"
}
```

### Configuración de widget

| Clave | Tipo | Descripción |
|-------|------|-------------|
| `widget_fav_stop` | String | Nombre de la parada favorita |
| `widget_fav_line` | String | Código de la línea favorita |

## 4.2 Flujo de actualización

1. El usuario configura parada/línea favorita en **Perfil → Widgets**
2. Un `Workmanager` periodic task (cada 15 min) consulta la API y llama a `WidgetDataWriter`
3. Los datos se persisten en `SharedPreferences`
4. El widget nativo lee `SharedPreferences` (Android) o `UserDefaults` con App Group (iOS)
5. Opcionalmente, `HomeWidget.updateWidget()` fuerza el refresco desde Dart

## 4.3 Notas de implementación nativa

- **Android:** Leer `SharedPreferences` con el mismo `package`. El widget usa `RemoteViews` y se actualiza con `AppWidgetManager`.
- **iOS:** Configurar un **App Group** compartido entre la app y el widget extension. Usar `UserDefaults(suiteName:)`.
- Las claves y el formato JSON son estables. No cambiar sin migrar.

---

# 5. Wearables (Nivel 1)

> Fase F27 · Complications (watchOS) + Tiles (Wear OS)
> Documentación completa: `docs/WEARABLE_NIVEL_1.md`

## 5.1 watchOS Complications

- **Families:** `.accessoryCircular`, `.accessoryRectangular`, `.accessoryInline`
- **TimelineProvider:** Lee de `UserDefaults(suiteName: "group.com.transitly.app")`
- **Refresh:** Gestionado por WidgetKit (el sistema decide frecuencia)
- **Datos:** Mismo contrato JSON que widgets nativos (§4)

## 5.2 Wear OS Tiles

- **TileService:** Layout con ícono bus + ruta + ETA
- **Refresh:** WorkManager cada 15 min → DataStore → `TileService.requestUpdate()`
- **Configuración:** Activity con `ScalingLazyColumn` para elegir parada favorita
- **Datos:** Lee `SharedPreferences` (mismo que widgets nativos)

## 5.3 Arquitectura de datos compartidos

```
WidgetDataWriter (Flutter)
       │
       ▼
SharedPreferences / UserDefaults (App Group)
       │
       ├──▶ Widget (Android/iOS)
       ├──▶ Complication (watchOS)
       └──▶ Tile (Wear OS, vía DataStore)
```

## 5.4 Limitaciones

- Requiere **Xcode + macOS** para watchOS complications
- Requiere **dispositivo físico** (Apple Watch / Wear OS) para probar
- Sin `WatchConnectivity` en Nivel 1: refresco no inmediato
- Sin teléfono emparejado, el Wear OS Tile muestra datos stale
- App Store requiere review adicional para apps con Watch companion

## 5.5 Roadmap wearable

| Nivel | Descripción | Estado |
|-------|-------------|--------|
| **0** | Notificaciones automáticas vía SO | ✅ F21 |
| **1** | Complications + Tiles | ✅ F27 |
| **2** | Acciones interactivas | ⏳ Futuro |
