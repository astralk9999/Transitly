# 06 — Manual Técnico

**Proyecto:** Transitly (nexto-stop-v2)
**Rama / HEAD:** `master @ b908f3c`
**Fecha del anchor:** 2026-05-23
**Plataformas objetivo:** Android (minSdk 23, targetSdk 34, compileSdk 35), iOS 16.0+, Web (PWA experimental).

> Este manual recoge las instrucciones de **instalación, configuración, despliegue y mantenimiento** de Transitly desde la perspectiva de un desarrollador o de un administrador técnico. Para el uso final de la aplicación vease `07_manual_usuario.md`.

---

## 1. Visión general de la arquitectura

Transitly es una aplicación Flutter con backend Supabase. Las decisiónes estructurales están documentadas como ADRs (`docs/adr/`) y son la referencia normativa:

- **ADR 001 — Riverpod 2.6** como gestor de estado, con uso explicito de `autoDispose` y `family` en las features que lo requieren.
- **ADR 002 — Freezed** para todos los modelos del dominio (veintisiete modelos inmutables con `copyWith`, `==`, `hashCode` y soporte `json_serializable`).
- **ADR 003 — Hive 2.2** con `HiveAesCipher` y tres boxes principales como cache local cifrada.
- **ADR 004 — Supabase** como backend (PostgreSQL, Auth, Realtime, Storage y Edge Functions Deno).
- **ADR 005 — Feature-first** como organizacion del código en `lib/features/`.

En el anchor actual el proyecto suma **veintisiete features**, **catorce migraciónes SQL consecutivas**, **cuatro Edge Functions** desplegadas, **seis runbooks operativos**, **619 tests** en verde, **628 claves ARB** localizadas a ES/EN/AR y **seis jobs CI** que validan analyze, test, build web y build Android (más dos jobs de seguridad). El cuadro de mando interno marca **TFG 8,9 / 10** y **Produccion 6,0 / 10**, diferenciando con claridad la madurez académica de la madurez productiva.

---

## 2. Requisitos del sistema de desarrollo

### 2.1. Software base

| Herramienta | Versión recomendada | Notas |
|-------------|---------------------|-------|
| Flutter SDK | **3.16+** (alíneado con la versión pinneada en CI) | Trae Dart 3 incluido. |
| Dart SDK | **3.2+** | Si se usa Flutter ≥ 3.16, viene integrado. |
| Android Studio | **Hedgehog** o superior con Android SDK API 34 | Incluye `platform-tools`, `cmdline-tools`, NDK opcional. |
| Xcode | **15+** | Solo macOS, requerido para compilar a iOS. |
| Java / JDK | **17 LTS** | Necesario para Gradle moderno. |
| Git | **2.40+** | El proyecto asume `git switch`, `git restore`. |
| Node.js | **20 LTS** | Para tooling auxiliar (Gitleaks local, scripts JS). |
| Deno | **1.40+** | Necesario para ejecutar las Edge Functions en local. |
| Supabase CLI | **1.x** | Para `supabase link`, `db push`, `functions deploy`. |
| Cuenta Supabase | Plan gratuito o superior | Proyecto con PostgreSQL, Auth, Realtime y Storage activos. |
| Cuenta Firebase | Plan Blaze (FCM HTTP v1) o gratuito según uso | Necesario para FCM. |

### 2.2. Sistema operativo

Soportado en Windows 10/11, macOS 12 o superior y Linux Ubuntu 20.04 o superior. La compilacion a iOS exige macOS por requisito de la cadena de Apple.

---

## 3. Instalación paso a paso

### 3.1. Clonado del repositorio

```bash
git clone https://github.com/astralk9999/Transitly.git
cd Transitly
```

### 3.2. Variables de entorno

A partir del refuerzo de seguridad SEC2, las claves se inyectan en tiempo de compilacion mediante `--dart-define` (el fichero `.env` ya no se distribuye como asset). El repositorio incluye `.env.example` como plantilla de referencia con explicación de cada variable.

```bash
cp .env.example .env   # solo como referencia local; no se bundlea
```

Variables obligatorias para arranque:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Variables opcionales (degradacion silenciosa si faltan):

- `SUPABASE_FUNCTIONS_URL` (por defecto `<url>/functions/v1`).
- `POSTHOG_API_KEY`, `POSTHOG_HOST`.
- `SENTRY_DSN`.
- `MAPTILER_API_KEY` (necesaria para teselas en línea fuera de la región offline).

### 3.3. Dependencias y generación de código

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

`flutter pub get` resuelve apróximadamente 150 paquetes (Riverpod 2.6, supabase_flutter, hive 2.2, flutter_map, sentry 8, posthog 5, flutter_secure_storage, very_good_analysis, leak_tracker_flutter_testing, entre otros). `build_runner` regenera los Freezed y `json_serializable`. `flutter gen-l10n` produce las clases tipadas de localización a partir de los ARB.

### 3.4. Firebase Cloud Messaging

Para el target Android e iOS, se requiere generar la configuración de Firebase:

```bash
flutterfire configure --project=transitly-prod
```

Esto produce `lib/firebase_options.dart`, `android/app/google-services.json` y `ios/Runner/GoogleService-Info.plist`. Sin estos ficheros el `firebase_setup.dart` degrada silenciosamente: la app funciona sin push.

### 3.5. Ejecución en debug

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJh...
```

### 3.6. Build release

```bash
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/debug-info \
  --dart-define=SUPABASE_URL=... \
  --dart-define=SUPABASE_ANON_KEY=...
```

El binario se firma con la keystore real si existe `android/key.properties`; en caso contrario, se firma con la debug key y el artefacto no es públicable.

---

## 4. Configuración avanzada

### 4.1. Feature flags y constantes de compilacion

Los `--dart-define` se utilizan también como **feature flags**. Las flags actuales incluyen `ENABLE_NFC`, `ENABLE_WIDGETS_NATIVE`, `ENABLE_REALTIME_DRIVER` y `OPERATOR_DEFAULT_SLUG`. Se ajustan en la línea de compilacion sin tocar código.

### 4.2. Cambiar el operador por defecto

El operador por defecto es COMUJESA (`comujesa`). Para cambiarlo:

1. Insertar el operador objetivo en la base mediante `dart tools/seed_operators.dart`.
2. Pasar `--dart-define=OPERATOR_DEFAULT_SLUG=<slug>` en el build.

### 4.3. Cambiar la paleta de marca

Las paletas viven en `lib/core/theme/palettes/`. Cada paleta declara los tokens `surfaceHi/Mid/Lo`, `textHi/Mid/Lo`, `primary`, `accent` y `signal*`. Tras editar o anadir una nueva paleta:

1. Ejecutar `dart run tool/contrast_check.dart` para validar WCAG AA.
2. Anadir el caso al test `accessibility_matrix_test.dart`.
3. Regenerar `00_MAESTRO.md` con `tool/verify_state.sh`.

### 4.4. Anadir un idioma

1. Crear `lib/l10n/app_<código>.arb` con todas las claves traducidas (628 en el anchor).
2. Anadir el código en `l10n.yaml`.
3. Si es RTL, anadir el código en `RTL_LOCALES` (`lib/core/utils/locale_utils.dart`).
4. Ejecutar `flutter gen-l10n`.

---

## 5. Estructura del repositorio

```
nexto-stop-v2/
├── lib/                      Código Dart (~260 ficheros)
│   ├── main.dart             Bootstrap (Env → Hive → Supabase → ProviderScope)
│   ├── app.dart              MaterialApp.router + theme + locale
│   ├── core/                 router, theme, utils, observability
│   ├── data/                 12 entidades con repositorio canonico, cache Hive,
│   │                         realtime channel manager, push, sync, NFC
│   ├── features/             27 features con `*_screen.dart`
│   ├── l10n/                 ARB ES/EN/AR + generated
│   └── shared/               Widgets reutilizables, models Freezed, providers
├── test/                     619 tests
├── supabase/
│   ├── migrations/           14 migraciónes consecutivas
│   └── functions/            4 Edge Functions Deno
├── android/                  Kotlin DSL, signing condicional, ABI splits
├── ios/                      Info.plist, entitlements
├── web/                      PWA experimental
├── docs/
│   ├── 00_MAESTRO.md         Fuente única de verdad
│   ├── adr/                  5 ADRs vivos
│   ├── runbooks/             6 runbooks operativos
│   ├── historico/            Auditorias y planes archivados
│   └── tfg/                  Memoria académica (01..08)
├── tool/                     Scripts Dart y shell (verify_state, contrast, build)
└── .github/workflows/ci.yml  CI con 6 jobs (4 build + 2 seguridad)
```

---

## 6. Backend Supabase

### 6.1. Vinculacion con el proyecto

```bash
supabase login
supabase link --project-ref <ref>
```

### 6.2. Aplicación de migraciónes

```bash
supabase db push
supabase migration list
```

Las catorce migraciónes consecutivas (`001_init.sql` hasta `016_data_exports.sql`, sin que existan `014` ni `015` tras la consolidacion documentada en la incidencia de 04/05/2026) cubren: schema base, RLS default-deny, parches de `search_path`, storage, RPCs, helpers de votos, helpers de invitación, triggers de notificaciones, tokens FCM, triggers push, auditoria extendida, reputación, exportacion offline y exportaciones GDPR.

### 6.3. Despliegue de Edge Functions

Las cuatro funciones desplegadas son `delete_user`, `import_gtfs`, `purge_old_data` y `send_notification`. Tres se despliegan con verificación de JWT y la cuarta (`import_gtfs`) sin verificación, porque se invoca desde una cron interna autenticada por `service_role`:

```bash
supabase functions deploy delete_user --verify-jwt
supabase functions deploy send_notification --verify-jwt
supabase functions deploy purge_old_data --verify-jwt
supabase functions deploy import_gtfs --no-verify-jwt
```

### 6.4. Secretos en Supabase

```bash
supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat fcm-service-account.json)"
supabase secrets set SENTRY_DSN="https://..."
supabase secrets set ALLOWED_ORIGINS="https://transitly.app,https://app.transitly.app"
```

### 6.5. Cron interno

Para `purge_old_data` y `delete_user_worker` se habilita `pg_cron` (requiere Supabase Pro) y se programan ejecuciónes diarias con la zona horaria del proyecto.

---

## 7. CI/CD

El workflow `.github/workflows/ci.yml` define **seis jobs principales** ejecutados en cada push y en cada pull request hacia `master`:

1. **Flutter Analyze** — bloqueo total ante cualquier error, warning o info.
2. **Flutter Test** — `flutter test --coverage`, validacion de umbral global y upload a Codecov.
3. **Build Web (release)** — compilacion del target web.
4. **Build Android APK / AAB** — APK con `--split-per-abi`, `--obfuscate` y `--split-debug-info`, validacion del budget de tamano, archivado de symbol files y firma del AAB.

A estos se anaden dos jobs auxiliares: **Gitleaks** (escaneo de secretos en el repositorio) y **Semgrep** (SAST con reglas locales en `.semgrep/rules.yaml`).

### 7.1. Secrets necesarios en GitHub

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEY_PROPERTIES_BASE64`
- `GOOGLE_SERVICES_JSON_BASE64`
- `GOOGLE_SERVICES_INFO_PLIST_BASE64`
- `SUPABASE_ACCESS_TOKEN`
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- `SENTRY_AUTH_TOKEN`
- `POSTHOG_API_KEY`
- `CODECOV_TOKEN`

### 7.2. Releases con `release-please`

El flujo de release es: anotacion de cambios con Conventional Commits, tag `vX.Y.Z`, `release-please` abre PR de release, al fusionarse se pública GitHub Release con el `CHANGELOG.md` actualizado y se adjuntan los artefactos (APK por ABI, AAB firmado, debug-info).

---

## 8. Mantenimiento rutinario

### 8.1. Actualizacion mensual de dependencias

```bash
flutter pub outdated
flutter pub upgrade --major-versións
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze && flutter test
```

Las actualizaciones mayores (Riverpod 3, Sentry 9, etc.) se ejecutan en rama separada con migración documentada en `docs/MEGA_PLAN_REFINAMIENTO.md`.

### 8.2. Rotacion de claves

La `anon key` y los PAT de Supabase se rotan cada **seis meses**, siguiendo el procedimiento de `docs/SECURITY_PAT_ROTATION.md`. La rotacion implica generar la nueva clave, actualizar secrets en GitHub, regenerar el build de release y revocar la clave anterior.

### 8.3. Auditorias trimestrales

Cada trimestre se ejecutan tres scripts de verificación:

- `tool/verify_state.sh` — confirma cifras del anchor.
- `tool/check_no_hardcoded.sh` — busca strings hardcodeados fuera de l10n.
- `dart run tool/contrast_check.dart` — válida contraste WCAG AA de todas las paletas.

### 8.4. Backup de la keystore Android

La keystore de release es irreemplazable: una perdida obliga a públicar la app como una nueva entrada en Play Store. Por ello se guarda en **tres ubicaciónes independientes** (gestor de secretos personal, copia cifrada offline y backup en almacenamiento frio), y nunca se elimina del repositorio personal de claves.

---

## 9. Runbooks operativos

Los seis runbooks de `docs/runbooks/` describen incidentes habituales en producción. Resumen por archivo:

- **`disaster_recovery.md`.** Procedimiento de recuperacion ante perdida de datos o de proyecto Supabase: restaurar desde el último `pg_dump` validado, comprobar consistencia de RLS y notificar a usuarios via push y banner in-app.
- **`error_budget_policy.md`.** Define el error budget mensual (objetivo 99,5 % de exito en arranques en frio y 99,0 % en envio de push) y la política de freeze de releases cuando se consume el 75 % del budget.
- **`migration_rollback.md`.** Pasos para revertir una migración erronea: marcar como `down` la migración en `supabase/migrations/_meta`, aplicar el inverso manual y reanunciar el estado al equipo. Incluye el aprendizaje de la incidencia 04/05/2026.
- **`push_down.md`.** Diagnostico cuando FCM deja de enviar: validar el JWT firmado, comprobar la cuota del proyecto Firebase, verificar el ratio de errores en `device_tokens` y forzar reenvio del token desde la app.
- **`sentry_spike.md`.** Procedimiento ante un pico de errores en Sentry: bisecar la versión implicada con `release-please`, aplicar un kill-switch via feature flag remoto si procede y abrir incidencia con plantilla postmortem.
- **`supabase_down.md`.** Actuacion ante caida del backend: activar banner offline en la app (ya cableado), confirmar el estado en `status.supabase.com` y, si la caida supera quince minutos, comúnicar a usuarios y replanificar la sesión de demo.

---

## 10. Resolucion de problemas frecuentes

| Sintoma | Causa probable | Solucion |
|---------|----------------|----------|
| Firebase `initializeApp` falla en arranque. | Falta `firebase_options.dart` o `google-services.json`. | Ejecutar `flutterfire configure --project=transitly-prod`. Si no se desea push, dejar el degradado silencioso del `firebase_setup.dart`. |
| RLS responde con error `42501`. | Política de Row Level Security denegada por falta de rol. | Revisar `is_admin()`, `is_moderator_or_admin()` y el campo `role` en `profiles`. |
| `flutter build apk --release` falla con duplicado `androidx.work`. | Reintroduccion accidental de `workmanager`. | Eliminar el plugin del `pubspec.yaml`. Esta es la incidencia historica de 22/04/2026. |
| Los tests de `integration_test` fallan en CI. | Emulador inadecuado o falta `integration_test` en `dev_dependencies`. | Usar emulador Pixel 6 API 34 y confirmar la dependencia. |
| Las teselas del mapa no aparecen sin red. | `FMTC StoreDirectory` no inicializado en el arranque. | Inicializar `FMTCStore` antes de `runApp` en `main.dart`. |
| Hive lanza `HiveError: Cipher mismatch`. | Se abrio un box antes de inicializar `flutter_secure_storage`. | Asegurar el orden: `SecureStorage` → `HiveAesCipher` → `Hive.openBox`. |
| Sentry no captura nada en release. | Uso de `print` en lugar de `AppLogger.error`. | Sustituir `print` por `AppLogger.error(...)`; en release los breadcrumbs se anaden fuera del bloque `kDebugMode`. |

---

## 11. Versiónado y release notes

El proyecto sigue **SemVer** (`MAJOR.MINOR.PATCH`) y aprovecha **Conventional Commits** como entrada para `release-please`. El flujo es:

1. Todos los commits hacia `master` usan los tipos `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `perf:` o `build:`.
2. `release-please` mantiene una pull request de release abierta con la versión siguiente y el `CHANGELOG.md` autogenerado.
3. Al fusionar la PR, se crea el tag `vX.Y.Z` y la `GitHub Release` con los artefactos adjuntos.
4. El `CHANGELOG.md` queda commiteado y trazable.

---

## 12. Referencias internas

- `docs/00_MAESTRO.md` — fuente única de verdad de las cifras del proyecto.
- `docs/adr/` — cinco ADRs vivos.
- `docs/runbooks/` — seis runbooks operativos.
- `docs/MEGA_PLAN_REFINAMIENTO.md` — plan vivo con clasificacion P0-P3.
- `docs/EXTERNAL_BLOCKERS.md` — diecinueve bloqueadores externos al alcance individual.
- `docs/SECURITY_PAT_ROTATION.md` — rotacion de PAT y claves anon.
- `docs/RELEASE_CHECKLIST.md` — comprobaciones previas al release.
- `docs/historico/AUDIT_2026_05_22.md` — auditoria deep-dive con trece sub-agentes.
- `docs/historico/PLAN_ACCION_REMEDIACION_v2.md` — plan v2 en seis fases.
- `AGENTS.md` — guia operativa para sesiónes de desarrollo asistido por IA.
- `android/README.md` — flujo de firma de release y Play App Signing.
