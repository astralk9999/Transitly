# Transitly · `nexto-stop-v2`

> Proyecto académico (TFG) — aplicación companion de transporte público urbano
> construida alrededor de **COMUJESA**, el operador de autobuses de Jerez de la
> Frontera (Cádiz). **Plataformas soportadas: Android y Web.**

[![codecov](https://codecov.io/gh/astralk9999/Transitly/branch/master/graph/badge.svg)](https://codecov.io/gh/astralk9999/Transitly)

---

## Resumen del proyecto

Transitly es una app de movilidad urbana con backend real en **Supabase**
(PostgreSQL + PostGIS, Auth, Storage, Realtime y Edge Functions) y
notificaciones push reales vía **Firebase Cloud Messaging**. Sus funcionalidades
principales:

- **Mapa en vivo** (`flutter_map` + MapTiler/CartoDB): líneas, paradas, zonas,
  posición de autobuses en tiempo real (canal Realtime con backoff exponencial)
  y caché de teselas offline (FMTC).
- **Líneas y horarios de COMUJESA**: catálogo real de líneas, paradas físicas
  deduplicadas y horarios exactos, con sincronización offline.
- **Estimación de llegadas** (ETA) combinando horario oficial, GPS del conductor
  y estimación propia.
- **Lector NFC** de la tarjeta prepago del *Consorcio de Transportes de
  Andalucía* (Mifare Classic): saldo e histórico de viajes.
- **Comunidad**: incidencias, sugerencias de paradas/zonas, votos, reputación
  (XP), moderación y promoción de aportaciones a contenido oficial.
- **Multi-rol**: usuario, conductor (emisión GPS en vivo, editor de rutas),
  operador y administrador (panel de gestión completo).
- **Push reales con la app cerrada** (FCM + Edge Function `send_notification`
  + triggers SQL), notificaciones in-app y alertas geográficas.
- **Widgets nativos de Android** (próximo bus / estado de línea) con refresco
  periódico en segundo plano (`home_widget` + `workmanager`).
- **Offline-first**: caché Hive, cola de sincronización y exportación de datos.
- **i18n** ES / EN / AR (RTL) — ARB completos y sincronizados — y trabajo real
  de **accesibilidad** (alto contraste, matrices para daltonismo, fuente
  OpenDyslexic, `textScaler`, movimiento reducido, objetivos táctiles 48 dp).
  Estado WCAG 2.2 AA: *parcial*, auditoría en [`docs/ACCESSIBILITY.md`](./docs/ACCESSIBILITY.md).
- **Telemetría opcional** (Sentry + PostHog) condicionada al consentimiento.
- **Superficie web**: build de Flutter Web embebida en un sitio **Astro**
  (`astro/`, uso local) y web de entregables del TFG en GitHub Pages
  (`presentation/`).

### Stack técnico

| Capa | Tecnología |
|------|------------|
| UI / framework | Flutter 3.9.2+ · Dart 3 (strict casts + strict raw types) |
| Estado | Riverpod 2.6 (`autoDispose`, providers derivados, `overrideWith` en tests) |
| Navegación | go_router 17.2 (`StatefulShellRoute`, `redirect` por ruta) |
| Backend | Supabase (`supabase_flutter` 2.8) — 53 migraciones SQL, 8 Edge Functions, RLS completo |
| Push | Firebase Cloud Messaging (`firebase_messaging`) con degradación elegante |
| Mapa | flutter_map 7 + MapTiler (fallback gratuito CartoDB) + FMTC offline |
| NFC | nfc_manager 3.5 (Mifare Classic, solo Android) |
| Telemetría | Sentry + PostHog (opt-in) |
| Web | Astro SSR + islas de Flutter Web |
| Tipografía | DM Sans + IBM Plex Mono (assets locales) |

La capa de datos sigue el patrón de repositorios `domain / local / mock /
remote` por entidad: sin sesión autenticada la app sirve los datos mock de
`assets/mock/comujesa_data.json`; con sesión Supabase, los mismos repositorios
leen/escriben el backend remoto.

Toda la documentación está indexada en [`docs/README.md`](./docs/README.md)
(arquitectura, escalabilidad, accesibilidad, memoria del TFG, runbooks…).

---

## Guía de instalación desde cero

La guía cubre todo el camino: base de datos (Supabase), Google Cloud (OAuth),
Firebase (push), mapas y la app en Android y Web.

### 0. Prerrequisitos

| Herramienta | Versión | Para qué |
|-------------|---------|----------|
| [Flutter SDK](https://docs.flutter.dev/get-started/install) (canal stable) | ≥ 3.9.2 | App Android y Web |
| Android Studio + Android SDK | API 24+ | Emulador / dispositivo |
| [Node.js](https://nodejs.org) | ≥ 18 | Scripts de seed y sitio Astro |
| [Supabase CLI](https://supabase.com/docs/guides/cli) | última | Migraciones y Edge Functions |
| Git | — | Clonar el repo |

```bash
git clone https://github.com/astralk9999/Transitly.git nexto-stop-v2
cd nexto-stop-v2
flutter pub get
flutter gen-l10n        # genera lib/l10n/generated (ES/EN/AR)
```

### 1. Crear el proyecto Supabase (base de datos)

1. Entra en <https://supabase.com/dashboard> → **New project** (región UE
   recomendada). Anota:
   - **Project ref** (el subdominio: `https://<ref>.supabase.co`),
   - **anon key** (Settings → API),
   - **service_role key** (solo para backend/CLI, *nunca* en el cliente).
2. Aplica las **53 migraciones** de [`supabase/migrations/`](./supabase/migrations)
   en orden. Opción recomendada (CLI):

   ```bash
   npm install -g supabase
   supabase login
   supabase link --project-ref <ref>
   supabase db push
   ```

   Alternativa: copiar/pegar cada `NNN_*.sql` en el SQL Editor del Dashboard,
   en orden numérico. La `001_init.sql` tarda 30–60 s (instala PostGIS e
   índices GIST). Verificaciones post-instalación en
   [`supabase/README.md`](./supabase/README.md).
3. **Storage**: los 5 buckets (`avatars`, `report-attachments`,
   `route-attachments`, `data-exports`, `operator-assets`) los crea la
   migración `004_storage.sql`; detalle de límites y paths en
   [`supabase/storage_setup.md`](./supabase/storage_setup.md).

### 2. Sembrar los datos de COMUJESA

Las migraciones solo contienen DDL; los datos de líneas/paradas/horarios se
generan desde el JSON del repo:

```bash
node tools/seed_comujesa.mjs        # escribe tools/seed_out/comujesa_seed.sql
```

Ejecuta el SQL resultante en el SQL Editor del Dashboard (es **idempotente**:
usa UUIDs deterministas y se puede relanzar). Sin este paso la app funciona,
pero el backend remoto estará vacío.

### 3. Configurar autenticación

#### 3.1 Email / contraseña

En el Dashboard → **Authentication → Providers → Email**:

- **Confirm email → OFF** (el proyecto no usa SMTP propio; el código asume
  login inmediato tras el registro). Si más adelante configuras SMTP, los
  pasos para reactivar la verificación están en
  [`docs/SUPABASE_SETUP.md`](./docs/SUPABASE_SETUP.md).

En **Authentication → URL Configuration → Redirect URLs** añade:

- `transitly://login-callback` (deep link de la app Android)
- la URL de tu despliegue web + `/app/` si vas a usar login en Web

#### 3.2 Google OAuth (Google Cloud)

El login con Google usa el flujo OAuth **web** de Supabase (no depende del
SHA-1 del APK):

1. <https://console.cloud.google.com> → crea un proyecto → **APIs & Services →
   OAuth consent screen** (tipo *External*, añade tu email de prueba).
2. **Credentials → Create credentials → OAuth client ID → Web application**:
   - *Authorized redirect URI*: `https://<ref>.supabase.co/auth/v1/callback`
3. Copia **Client ID** y **Client Secret** en Supabase → **Authentication →
   Providers → Google** (actívalo).
4. Guarda el Client ID también como `GOOGLE_WEB_CLIENT_ID` (paso 6).

### 4. Edge Functions y secretos

Despliega las 8 funciones de [`supabase/functions/`](./supabase/functions):

```bash
supabase functions deploy approve_user_route delete_user generate_data_export \
  import_gtfs promote_stop_to_official purge_old_data send_notification \
  validate_share_code --project-ref <ref>
```

Para que los **triggers SQL** puedan invocar `send_notification` (push), crea
estos secretos en el Vault (SQL Editor, una sola vez):

```sql
select vault.create_secret('<service_role_key>', 'service_role_key');
select vault.create_secret('https://<ref>.supabase.co/functions/v1', 'functions_url');
```

`import_gtfs` requiere además la env var `ALLOWED_ORIGINS` (allowlist CORS,
sin comodines). Detalles de endurecimiento en
[`supabase/README.md`](./supabase/README.md).

### 5. Firebase / FCM (push reales)

Opcional pero recomendado — sin esto la app funciona y simplemente no recibe
push. Guía completa: [`docs/FCM_SETUP.md`](./docs/FCM_SETUP.md) y
[`docs/PLATFORM_SETUP.md`](./docs/PLATFORM_SETUP.md).

1. <https://console.firebase.google.com> → **Add project**.
2. Añade una app **Android** con package name `com.transitly.transitly`
   (el `applicationId` de `android/app/build.gradle.kts`).
3. Descarga `google-services.json` → colócalo en `android/app/`.
4. Genera `lib/firebase_options.dart`:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<tu-proyecto-firebase>
   ```

5. Para que el **backend envíe** push: Firebase → ⚙️ Configuración del
   proyecto → *Cuentas de servicio* → **Generar nueva clave privada** (JSON), y:

   ```bash
   supabase secrets set FCM_PROJECT_ID=<tu-proyecto-firebase> --project-ref <ref>
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)" --project-ref <ref>
   supabase functions deploy send_notification --project-ref <ref>
   ```

Prueba rápida: Firebase Console → Cloud Messaging → *Enviar mensaje de
prueba* pegando el token del dispositivo (queda en la tabla `device_tokens`
tras iniciar sesión).

### 6. Variables de entorno de la app

La app lee la configuración **en tiempo de compilación** vía `--dart-define`
(ver `lib/core/env.dart`). Lo cómodo es un archivo `dart_defines.json` en la
raíz (está **gitignored** — nunca lo subas):

```json
{
  "SUPABASE_URL": "https://<ref>.supabase.co",
  "SUPABASE_ANON_KEY": "<anon-key>",
  "SUPABASE_FUNCTIONS_URL": "https://<ref>.supabase.co/functions/v1",
  "GOOGLE_WEB_CLIENT_ID": "<client-id>.apps.googleusercontent.com",
  "POSTHOG_API_KEY": "",
  "POSTHOG_HOST": "https://eu.posthog.com",
  "SENTRY_DSN": "",
  "MAPTILER_API_KEY": ""
}
```

- **Obligatorias**: `SUPABASE_URL` y `SUPABASE_ANON_KEY` (si faltan, la app
  arranca con una pantalla de error de entorno).
- **Opcionales** (degradan en silencio): telemetría (`SENTRY_DSN`,
  `POSTHOG_API_KEY`) y `MAPTILER_API_KEY` — sin clave de MapTiler el mapa usa
  CartoDB gratuito como fallback. Clave gratuita en
  <https://cloud.maptiler.com> (100k teselas/mes).

`.env.example` documenta las mismas variables como referencia.

### 7. Ejecutar en Android

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Para el APK de release:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Si existe `android/key.properties` (con `storeFile`, `storePassword`,
`keyAlias`, `keyPassword`) el build se firma con ese keystore; si no, usa la
firma debug — suficiente para instalar y probar.

### 8. Ejecutar en Web

Build de Flutter Web:

```bash
flutter build web --release --base-href "/app/" --pwa-strategy none \
  --dart-define-from-file=dart_defines.json
```

El sitio Astro (`astro/`, uso local) sirve las páginas públicas SSR y embebe
la build de Flutter:

```bash
cd astro
cp .env.example .env    # PUBLIC_SUPABASE_URL, PUBLIC_SUPABASE_ANON_KEY, PUBLIC_MAPTILER_API_KEY
npm install
npm run dev             # http://localhost:4321
```

Detalles (entry points por feature, despliegue, Docker) en
[`docs/PLATFORM_SETUP.md`](./docs/PLATFORM_SETUP.md). La web de entregables
del TFG vive aparte en `presentation/` (GitHub Pages).

### 9. Verificar la instalación

```bash
flutter analyze     # debe terminar sin issues
flutter test        # suite completa
```

Checklist funcional: crear una cuenta (login inmediato, sin email de
confirmación), iniciar sesión con Google, ver líneas y paradas de COMUJESA en
el mapa, y — si configuraste FCM — recibir un push de prueba con la app
cerrada.

---

## NFC (sensible)

Las claves Mifare por defecto de la tarjeta del Consorcio viven en
`lib/data/nfc/nfc_card_service.dart` (ingeniería inversa de la app pública
`saldotarjetas`, **solo uso académico**). Se pueden sobreescribir en build:

```bash
flutter run --dart-define=NFC_KEY_SECTOR0=<hex-6-bytes> --dart-define=NFC_KEY_SECTOR9=<hex-6-bytes>
```

---

## Estructura del repositorio

```
lib/            App Flutter (domain / data / shared / features)
supabase/       53 migraciones SQL + 8 Edge Functions (Deno)
assets/mock/    Datos COMUJESA (fuente del seed)
tools/          Seed, OCR de horarios, build web, utilidades
astro/          Sitio web Astro (SSR + islas Flutter Web, uso local)
presentation/   Web de entregables del TFG (GitHub Pages)
docs/           Documentación técnica + memoria del TFG
test/           Suite de tests (unit, widget, smoke)
multiagent/     Sistema multiagente usado durante el desarrollo
```

---

## Licencia y datos

Los datos de horarios/paradas/líneas de COMUJESA incluidos en `assets/mock/`
proceden de horarios públicos, reformateados con fines educativos. Este
proyecto no reclama autoría sobre los datos subyacentes.
