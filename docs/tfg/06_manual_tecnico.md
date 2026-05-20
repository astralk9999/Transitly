# 06 — Manual Técnico

**Proyecto:** Transitly
**Versión actual:** post-F27 + ciclos de remediación
**Estado verificado:** `master @ 3a31fb3` · `flutter analyze` 0 · 175/175 tests · CI verde · APK release 73,5 MB

> Este documento cubre **instalación, configuración, despliegue y
> mantenimiento** para un desarrollador o administrador técnico. Para
> el manual de usuario final ver `07_manual_usuario.md`.

---

## 1. Requisitos del sistema

### 1.1. Para desarrollo

| Recurso | Versión mínima recomendada |
|---------|---------------------------|
| Sistema operativo | Windows 10/11, macOS 12+, Linux Ubuntu 20.04+ |
| Flutter SDK | **3.35.x stable** (Dart 3.9+; coincide con CI) |
| Dart SDK | 3.9+ (incluido con Flutter) |
| Android Studio o IntelliJ | Hedgehog+ (Android SDK 34+) |
| Xcode (solo iOS, macOS) | 15+ |
| Java/JDK | 17 LTS (recomendado para Gradle moderno) |
| Git | 2.40+ |
| Node.js (solo Astro web) | 20 LTS |
| Supabase CLI (opcional, para migraciones locales) | 1.x |

### 1.2. Para el dispositivo de usuario final

| Plataforma | Versión mínima |
|------------|----------------|
| Android | API 24 (Android 7.0 Nougat) |
| iOS | 16.0+ |
| Web | Navegador con WebGL2 y soporte WebAssembly (Chrome 90+, Firefox 90+, Safari 15+) |

---

## 2. Instalación inicial

### 2.1. Clonar el repositorio

```bash
git clone https://github.com/astralk9999/Transitly.git
cd Transitly
```

### 2.2. Configurar variables de entorno

El proyecto usa `--dart-define` para inyectar variables en tiempo de
compilación (SEC2 — `.env` ya no se bundlea como asset).

Para desarrollo, puedes usar un script de arranque o pasarlas a
`flutter run` directamente:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJh... \
  --dart-define=POSTHOG_API_KEY=phc_... \
  --dart-define=POSTHOG_HOST=https://eu.posthog.com \
  --dart-define=SENTRY_DSN=https://...@sentry.io/... \
  --dart-define=MAPTILER_API_KEY=...
```

Variables obligatorias:

- `SUPABASE_URL` y `SUPABASE_ANON_KEY` — sin estas la app crashea al
  arrancar (`EnvErrorScreen`).

Variables opcionales (degradación silenciosa si faltan):

- `SUPABASE_FUNCTIONS_URL` (por defecto `<url>/functions/v1`).
- `POSTHOG_API_KEY`, `POSTHOG_HOST`, `SENTRY_DSN`, `MAPTILER_API_KEY`.

Plantilla con explicaciones en `.env.example` (archivo trackeado).

### 2.3. Instalar dependencias

```bash
flutter pub get
```

Resuelve ~150 paquetes transitive (Riverpod, go_router, freezed,
supabase_flutter, hive, flutter_map, etc.). Verifica que termina con
`Got dependencies!`.

### 2.4. Generar localizaciones e l10n

```bash
flutter gen-l10n
```

Produce `lib/l10n/generated/app_localizations.dart`,
`app_localizations_es.dart`, `_en.dart`, `_ar.dart`. **Obligatorio
tras un checkout fresco**.

### 2.5. Generar código (`@freezed` + `json_serializable`)

```bash
tool/build.sh
# alias de: dart run build_runner build --delete-conflicting-outputs
```

Para sesiones largas editando modelos:

```bash
tool/build_watch.sh
```

### 2.6. Verificar el entorno

```bash
flutter analyze            # → No issues found!
flutter test               # → All tests passed! (175/175)
```

Si esto sale verde, el entorno está listo.

### 2.7. Ejecutar en un dispositivo

```bash
flutter devices             # lista dispositivos conectados
flutter run                 # selecciona el dispositivo
flutter run -d chrome       # web en Chrome
flutter run -d emulator-5554 # Android emulador concreto
```

---

## 3. Estructura del repositorio

```
Transitly/
├── lib/                          # Código Dart (~260 ficheros)
│   ├── main.dart                 # Bootstrap (Env → Hive → Supabase → ProviderScope)
│   ├── app.dart                  # MaterialApp.router + theme + locale
│   ├── core/                     # router/, theme/, utils/
│   ├── data/                     # Capa más profunda; NO depende de features/
│   │   ├── auth/                 # Repos auth (excepción al patrón canónico)
│   │   ├── mock/                 # MockDataService, MockRealtimeService
│   │   ├── cache/                # Hive adapters + boxes + HiveInit
│   │   ├── nfc/                  # NfcCardService + i18n
│   │   ├── sync/                 # RealtimeChannelManager, OfflineSyncService
│   │   └── <entity>/             # 12 entidades con patrón canónico de 5 ficheros
│   ├── features/                 # Feature-first (~25 features)
│   ├── l10n/                     # ARB es/en/ar + generated/
│   └── shared/                   # models/ (27+ @freezed), providers/, widgets/
├── android/
│   ├── app/build.gradle.kts      # Kotlin DSL puro (signing condicional)
│   ├── gradle.properties         # Heap 4G + daemon=false + workers.max=2
│   ├── key.properties            # GITIGNORED — credenciales keystore
│   ├── key.properties.example    # Plantilla commiteada
│   └── README.md                 # Guía de firma de release
├── ios/                          # Configuración iOS (Info.plist, entitlements)
├── web/                          # Index, manifest, icons
├── linux/ macos/ windows/        # Targets desktop
├── astro/                        # Marketing site SSR (Astro + Tailwind)
├── assets/
│   ├── mock/                     # comujesa_data.json (datos seed)
│   ├── fonts/                    # DM Sans + IBM Plex Mono (F26 bundled)
│   ├── achievements.json         # Catálogo de logros
│   └── branding/                 # Logo
├── shaders/                      # smoke.frag (shader del fondo)
├── docs/                         # Documentación viva + tfg/ + historico/
│   ├── README.md                 # Índice (mapeo TFG)
│   ├── 00_MAESTRO.md             # Fuente única de verdad
│   ├── SCALABILITY.md            # Dossier producción
│   ├── ACCESSIBILITY.md          # Dossier WCAG
│   ├── ARCHITECTURE.md           # Reglas de arquitectura
│   ├── PLAN_ACCION_REMEDIACION.md
│   ├── PENDIENTE_PARA_CERRAR.md
│   ├── PENDIENTES.md             # Cola interna [F<n>]
│   ├── PLATFORM_SETUP.md
│   ├── FCM_SETUP.md, FONTS_F26.md, HOME_WIDGETS.md, WEB_SETUP.md
│   ├── SECURITY_PAT_ROTATION.md, RELEASE_CHECKLIST.md
│   ├── WEARABLE_NIVEL_1.md, PROPUESTAS_FUTURAS.md
│   ├── tfg/                      # Memoria académica (01..08)
│   └── historico/                # Documentos archivados (trazabilidad)
├── multiagent/                   # Documentación del sistema multiagente IA
├── supabase/
│   ├── migrations/               # 13 migraciones SQL
│   └── functions/                # Edge Functions (import_gtfs, send_notification)
├── data/seed/                    # spanish_gtfs_feeds.yaml
├── test/                         # 175 tests Dart
├── tool/                         # build.sh, build_watch.sh
├── tools/                        # migrate_comujesa.dart, seed_operators.dart, scripts JS
├── pubspec.yaml                  # Dependencias Dart
├── build.yaml                    # Config codegen
├── analysis_options.yaml         # strict-casts, strict-raw-types, lints
├── l10n.yaml                     # Config i18n
├── .github/workflows/ci.yml      # CI 4 jobs
├── AGENTS.md                     # Guía operativa para agentes IA
└── README.md                     # Entrada del repositorio
```

---

## 4. Base de datos (Supabase)

### 4.1. Migraciones

```bash
# Conectar al proyecto remoto (una vez)
supabase login
supabase link --project-ref <tu-ref>

# Aplicar migraciones
supabase db push

# Listar estado
supabase migration list
```

13 ficheros en `supabase/migrations/`:

- `001_init.sql` — schema base (operadores, paradas, rutas, schedules,
  perfiles, posiciones).
- `002_rls.sql` — RLS default-deny + funciones helper (`is_admin`,
  `is_moderator_or_admin`).
- `003_rls_fixes.sql` — patches a `search_path` y revocación de
  permisos a `anon`.
- `004_storage.sql` — buckets para avatares y adjuntos.
- `005_functions.sql` — RPCs (búsqueda geográfica, votos).
- `006_vote_helpers.sql`, `007_invitation_helpers.sql`,
  `007_notification_triggers.sql` — helpers para votos, códigos de
  invitación, triggers de notificaciones.
- `012_reputation.sql`, `013_offline_export.sql`, `014_push_tokens.sql`,
  `015_push_triggers.sql`, `016_data_exports.sql` — extensiones de
  producto.

### 4.2. Tablas principales

| Tabla | Descripción |
|-------|-------------|
| `profiles` | 1:1 con `auth.users`; incluye `role` (`passenger`/`driver`/`operator_admin`/`moderator`/`admin`) |
| `operators` | Operadores de transporte (COMUJESA + 9 más definidos) |
| `routes`, `stops`, `route_stops`, `schedules` | Modelo GTFS adaptado |
| `bus_positions` | Posiciones GPS de buses (Realtime activo) |
| `incidents`, `route_feedback`, `route_suggestions`, `feature_requests` | Contribuciones comunitarias |
| `notifications`, `device_tokens` | Notificaciones in-app + FCM |
| `privacy_consents`, `data_exports`, `data_deletion_requests` | GDPR |

### 4.3. Row-Level Security (RLS)

- **Default-deny activo** en todas las tablas con PII.
- Roles: `anon` (lectura limitada), `authenticated` (lectura/escritura
  bajo policy), `service_role` (solo backend / Edge Functions).
- Políticas verificables vía Supabase Dashboard → Database → Policies.

### 4.4. Edge Functions

Las 2 funciones en Deno viven en `supabase/functions/`:

```bash
# Desplegar
supabase functions deploy import_gtfs
supabase functions deploy send_notification

# Probar localmente
supabase functions serve import_gtfs
```

- `import_gtfs`: requiere rol admin/operator_admin; descarga ZIP GTFS,
  parsea CSV y hace upsert en `operators`/`stops`/`routes`/`schedules`.
  Validación anti-SSRF con DNS A/AAAA y `redirect:"manual"`.
- `send_notification`: invocada por triggers SQL (`pg_net`); valida que
  el invocador sea `service_role` (tiempo constante), aplica rate-limit
  best-effort, envía push FCM HTTP v1 con OAuth JWT firmado.

---

## 5. Build y release

### 5.1. Android — debug

```bash
flutter run --debug
```

### 5.2. Android — release APK

```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
# Output: build/app/outputs/flutter-apk/app-release.apk (~73 MB)
```

**Firma:** el `build.gradle.kts` detecta si `android/key.properties`
existe. Si sí, firma con la keystore real (release publicable); si no,
cae al keystore de debug (APK no publicable). Pasos para keystore real
en `android/README.md`:

```bash
# Generar keystore
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Crear android/key.properties (gitignored) con:
#   storePassword=...
#   keyPassword=...
#   keyAlias=upload
#   storeFile=upload-keystore.jks

# Verificar firma
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

### 5.3. Android — App Bundle (Play Store)

```bash
flutter build appbundle --release --dart-define=...
# Output: build/app/outputs/bundle/release/app-release.aab
```

### 5.4. iOS — release IPA

```bash
flutter build ios --release --dart-define=...
# Abrir en Xcode: Product → Archive → Distribute App
```

Requiere certificado Apple Developer y provisioning profile.

### 5.5. Web

```bash
flutter build web --release --dart-define=...
# Output: build/web/
```

Para integrar con el sitio Astro, copiar `build/web/` al directorio
público de Astro o servir como subruta.

### 5.6. Desktop (Linux/macOS/Windows)

```bash
flutter build linux --release
flutter build macos --release   # solo en macOS
flutter build windows --release # solo en Windows
```

---

## 6. CI/CD (GitHub Actions)

Workflow en `.github/workflows/ci.yml` con 4 jobs paralelos en cada
push y PR a `master`:

1. **Flutter Analyze** — `flutter analyze` (debe ser 0 issues).
2. **Flutter Test** — `flutter test --coverage` + upload de
   `coverage/lcov.info` como artifact.
3. **Build Web (release)** — `flutter build web --release`.
4. **Build Android APK** — `flutter build apk --release` con
   `--split-per-abi` y `--dart-define` desde secrets.

**Secrets requeridos en GitHub** (Settings → Secrets and variables → Actions):

- `SUPABASE_URL`, `SUPABASE_ANON_KEY` — para builds reales.
- Para firma de release (cuando se configure): `KEYSTORE_BASE64`,
  `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`. Step que
  reconstruya `upload-keystore.jks` y `key.properties` antes del build.

---

## 7. Mantenimiento operativo

### 7.1. Actualizar dependencias

```bash
flutter pub outdated      # ver pendientes
flutter pub upgrade       # bump menor + parche
tool/build.sh             # regenerar codegen si cambian modelos
flutter analyze && flutter test  # verificar
```

Actualizaciones mayores (Riverpod 3, Sentry 9, etc.) están fijadas en
`pubspec.yaml` por decisión consciente — actualizarlas requiere
migración propia documentada como deuda en
`docs/PLAN_ACCION_REMEDIACION.md`.

### 7.2. Añadir nuevo operador

1. Añadir entrada en `data/seed/spanish_gtfs_feeds.yaml` con `slug`,
   `name`, `region`, `gtfs_url`.
2. Ejecutar `dart tools/seed_operators.dart` (inserta la fila en
   `operators`).
3. Ejecutar la Edge Function `import_gtfs` con el slug del operador.

### 7.3. Añadir nueva entidad con repositorio

Seguir el patrón canónico de `lib/data/operator/` (referencia):

1. `lib/data/<entity>/domain/<entity>_repository.dart` — interfaz
   abstracta + `<Entity>RepositoryException` tipado.
2. `lib/data/<entity>/remote/<entity>_remote_repository.dart` —
   implementación Supabase.
3. `lib/data/<entity>/local/<entity>_local_repository.dart` —
   implementación Hive.
4. `lib/data/<entity>/local/<entity>_mock_repository.dart` — fallback
   modo guest.
5. `lib/data/<entity>/<entity>_repository_provider.dart` — Provider
   Riverpod con SWR y selector mock vs real.

### 7.4. Añadir nueva clave de localización

1. Añadir en `lib/l10n/app_es.arb` (template).
2. Añadir en `lib/l10n/app_en.arb` y `lib/l10n/app_ar.arb` (traducción).
3. Si tiene placeholders, declarar `@key` con `placeholders` en
   `app_es.arb`.
4. `flutter gen-l10n` para regenerar.
5. Usar como `AppLocalizations.of(context).<key>(args)`.

### 7.5. Rotar PAT de Supabase

Procedimiento en `docs/SECURITY_PAT_ROTATION.md`. Resumen:

1. Generar nuevo PAT en `supabase.com/dashboard/account/tokens` con
   alcance mínimo.
2. Sustituir en `.mcp.json` local (gitignored).
3. Revocar el PAT viejo en el dashboard.

### 7.6. Backup y restauración

- **Datos Supabase:** `supabase db dump > backup.sql`.
- **Hive local:** los boxes están en el directorio de aplicación del
  dispositivo; no requieren backup manual (se reconstruyen del backend).
- **Código:** repositorio Git con CI que valida cada push.

---

## 8. Solución de problemas frecuentes

| Problema | Solución |
|----------|----------|
| `flutter pub get` falla con "SDK constraint" | Asegurar Flutter 3.35+; alinear con `analysis_options.yaml` y `pubspec.yaml` |
| `flutter build apk --release` falla con "Duplicate class androidx.work" | Causa: workmanager versión antigua. Solución: ya eliminado en este proyecto; si vuelve a aparecer, no añadirla. |
| "Core library desugaring required" | Confirmar `isCoreLibraryDesugaringEnabled = true` y dependencia `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` en `build.gradle.kts` |
| Gradle daemon "disappeared unexpectedly" | Reducir heap en `android/gradle.properties` a `-Xmx4G`, añadir `org.gradle.daemon=false` |
| `flutter analyze` rojo con `info` triviales | Para libs externos: añadir `// ignore: lint_name` con justificación |
| Tests fallan con `Supabase.instance` no inicializado | `pumpApp` debe llamar al setup mock en `test/helpers/pump_app.dart` |
| App muestra `EnvErrorScreen` al arrancar | Variables `SUPABASE_URL` o `SUPABASE_ANON_KEY` faltan en `--dart-define` |
| Lector de pantalla anuncia en español con app en inglés | Asegurar que `Semantics(label: ...)` usa `AppLocalizations.of(context).<key>`, no string literal |
| Sentry/PostHog no reportan crashes/eventos | El usuario debe haber otorgado consentimiento en Privacidad → toggle correspondiente |

---

## 9. Monitorización y observabilidad

- **Sentry** (`SENTRY_DSN` configurado) — issues, eventos, alertas.
- **PostHog** (`POSTHOG_API_KEY` configurado) — analítica de producto.
- **Supabase Dashboard** — logs de Edge Functions, queries lentas, RLS
  policies.
- **GitHub Actions** — historial de builds, artefactos de cobertura.

A producción a escala faltan SLO declarados, tracing distribuido y
alertas (PROD-7 del plan vivo).

---

## 10. Referencias

- `docs/00_MAESTRO.md` — fuente única de verdad.
- `docs/ARCHITECTURE.md` — reglas de arquitectura.
- `docs/PLATFORM_SETUP.md`, `docs/FCM_SETUP.md`, `docs/HOME_WIDGETS.md`,
  `docs/WEB_SETUP.md` — guías por plataforma/feature.
- `docs/SECURITY_PAT_ROTATION.md` — rotación de PAT.
- `docs/RELEASE_CHECKLIST.md` — checklist pre-release.
- `AGENTS.md` — guía operativa para agentes (sesiones de desarrollo
  asistido).
- `android/README.md` — flujo de firma de release y Play App Signing.
