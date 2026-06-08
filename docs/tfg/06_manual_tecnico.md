# 06 — Manual Técnico

**Proyecto:** Transitly (nexto-stop-v2)
**Rama / HEAD original:** `master @ b908f3c` (2026-05-23)
**Rama / HEAD actualizado:** `master @ b47180d0` (2026-06-08)
**Release distribuible:** v1.12.1 (APK universal) — descargable desde https://github.com/astralk9999/Transitly/releases/tag/v1.12.1
**Plataformas objetivo:** Android (minSdk 24 / Android 7.0+, targetSdk 34, compileSdk 36), iOS 16.0+, Web (PWA experimental).

> Este manual recoge las instrucciones de **instalación, configuración, despliegue y mantenimiento** de Transitly desde la perspectiva de un desarrollador o de un administrador técnico. Para el uso final de la aplicación vease `07_manual_usuario.md`.

---

## 1. Visión general de la arquitectura

Transitly es una aplicación Flutter con backend Supabase. Las decisiónes estructurales están documentadas como ADRs (`docs/adr/`) y son la referencia normativa:

- **ADR 001 — Riverpod 2.6** como gestor de estado, con uso explicito de `autoDispose` y `family` en las features que lo requieren.
- **ADR 002 — Freezed** para todos los modelos del dominio (veintisiete modelos inmutables con `copyWith`, `==`, `hashCode` y soporte `json_serializable`).
- **ADR 003 — Hive 2.2** con `HiveAesCipher` y tres boxes principales como cache local cifrada.
- **ADR 004 — Supabase** como backend (PostgreSQL, Auth, Realtime, Storage y Edge Functions Deno).
- **ADR 005 — Feature-first** como organizacion del código en `lib/features/`.

A fecha de defensa el proyecto suma **veintisiete features** (446 ficheros `.dart`, ~94k LOC), **cincuenta y una migraciónes SQL consecutivas**, **ocho Edge Functions** desplegadas, **seis runbooks operativos**, **679 tests** en verde, **642 claves ARB** localizadas a ES/EN/AR y **seis jobs CI** (analyze, test, build web, build APK, semgrep, gitleaks). El cuadro de mando interno marca **TFG 8,9 / 10** y **Produccion 6,0 / 10**, diferenciando con claridad la madurez académica de la madurez productiva.

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

El proyecto Firebase es `transitly-ee8cf`. El repositorio ya incluye `lib/firebase_options.dart` con las claves del proyecto; el fichero `android/app/google-services.json` **no se versiona** (está en `.gitignore`) y debe colocarse manualmente o regenerarse con:

```bash
flutterfire configure --project=transitly-ee8cf --platforms=android
```

Esto produce/actualiza `lib/firebase_options.dart` y `android/app/google-services.json`. Sin el `google-services.json` el `firebase_setup.dart` degrada silenciosamente: la app funciona sin push. Para el **envío programático** desde el backend hace falta además la *service account* de Firebase como secreto `FCM_SERVICE_ACCOUNT_JSON` (ver `docs/FCM_SETUP.md`).

### 3.5. Ejecución en debug

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<tu-proyecto>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJh...
```

### 3.6. Build release

```bash
# APK universal (el publicado en v1.12.1; máxima compatibilidad de dispositivos)
flutter build apk --release --dart-define-from-file=dart_defines.json

# Alternativa por ABI (binarios más pequeños) o App Bundle para Play Store
flutter build apk --release --split-per-abi \
  --obfuscate --split-debug-info=build/debug-info \
  --dart-define-from-file=dart_defines.json
```

El binario se firma con la keystore real si existe `android/key.properties`; en caso contrario, se firma con la debug key y el artefacto no es públicable. El APK universal de v1.12.1 ocupa ~91 MB (incluye arm64-v8a, armeabi-v7a y x86_64).

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
├── lib/                      Código Dart (446 ficheros, ~94k LOC)
│   ├── main.dart             Bootstrap (Env → Hive → Supabase → Firebase → ProviderScope)
│   ├── app.dart              MaterialApp.router + theme + locale
│   ├── core/                 router, theme, utils, observability
│   ├── data/                 12 entidades con repositorio canonico, cache Hive,
│   │                         realtime channel manager, push, sync, NFC
│   ├── features/             27 features con `*_screen.dart`
│   ├── l10n/                 ARB ES/EN/AR + generated (642 claves)
│   └── shared/               38 widgets reutilizables, 30 models Freezed, providers
├── test/                     679 tests
├── supabase/
│   ├── migrations/           51 migraciónes consecutivas
│   └── functions/            8 Edge Functions Deno
├── android/                  Kotlin DSL, signing condicional, foreground service
├── ios/                      Info.plist, entitlements
├── web/                      PWA experimental
├── astro/                    Web de producto (landing + app Flutter en /app, SSR)
├── presentation/             Web del TFG (GitHub Pages: presentación + entregables)
├── docs/
│   ├── 00_MAESTRO.md         Fuente única de verdad
│   ├── adr/                  5 ADRs vivos
│   ├── runbooks/             6 runbooks operativos
│   ├── historico/            Auditorias y planes archivados
│   └── tfg/                  Memoria académica (01..08)
├── tool/ y tools/            Scripts Dart, shell y Node (verify_state, contrast, seed, apply_sql)
└── .github/workflows/        CI (6 jobs) + deploy de Pages + dartdoc + release-please
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

Las **cincuenta y una migraciónes consecutivas** (`001_init.sql` en adelante) cubren: schema base, RLS default-deny, parches de `search_path`, storage, RPCs, helpers de votos, helpers de invitación, triggers de notificaciones, tokens FCM, triggers push, auditoria extendida, reputación, exportacion offline, exportaciones GDPR, sistema de reputación/XP, avisos geo, líneas y horarios de COMUJESA, conductor en vivo (`driver_live_trips`), zonas y la función `is_route_owner` que rompe la recursión RLS 42P17.

### 6.3. Despliegue de Edge Functions

Las **ocho funciones desplegadas** son `send_notification`, `import_gtfs`, `delete_user`, `purge_old_data`, `generate_data_export`, `approve_user_route`, `promote_stop_to_official` y `validate_share_code`. Las invocadas por el usuario verifican JWT; las invocadas por cron o triggers internos (autenticados por `service_role`) se despliegan sin verificación:

```bash
supabase functions deploy send_notification        # invocada por triggers (service_role)
supabase functions deploy delete_user --verify-jwt
supabase functions deploy generate_data_export --verify-jwt
supabase functions deploy validate_share_code --verify-jwt
supabase functions deploy approve_user_route --verify-jwt
supabase functions deploy promote_stop_to_official --verify-jwt
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

---

## Adenda — Procedimientos añadidos entre 23/05 y 04/06 de 2026

### Distribución del APK como GitHub Release Asset

Desde la versión v1.11.0 los APKs no se versionan en el repositorio sino que se publican como assets de release en GitHub. El flujo es:

1. Generar el APK release: `flutter build apk --release --dart-define-from-file=dart_defines.json`.
2. Crear el tag local: `git tag vX.Y.Z <commit>` (por convención el commit del cierre de la versión).
3. Push del tag: `git push origin vX.Y.Z`.
4. Crear el release con el APK:
   ```powershell
   $apk = "C:\Users\<user>\AppData\Local\Temp\transitly-vX.Y.Z.apk"
   & "C:\Program Files\GitHub CLI\gh.exe" release create vX.Y.Z `
     "$apk#Transitly vX.Y.Z (Android APK)" `
     --title "vX.Y.Z — resumen breve" `
     --notes "<notas en markdown>"
   ```
5. Verificar que `https://github.com/astralk9999/Transitly/releases/latest` redirige al nuevo release.

La presentación web (`presentation/src/`) enlaza siempre a `releases/latest`, por lo que no requiere rebuild tras un release nuevo.

### Aplicación de migraciones SQL adicionales

Las migraciones SQL posteriores al anchor original se aplican vía MCP de Supabase o directamente desde el SQL Editor del dashboard. Para auditar políticas RLS existentes ante un sospechoso de recursión 42P17:

```sql
SELECT schemaname, tablename, policyname, cmd, qual, with_check
FROM pg_policies
WHERE tablename IN ('<tabla_1>', '<tabla_2>', '<tabla_3>')
ORDER BY tablename, policyname;
```

La migración `fix_route_shares_rls_recursion` (2026-06-04) introduce la función `public.is_route_owner(uuid)` con `SECURITY DEFINER STABLE` para romper ciclos en políticas de visibilidad. Documentación operativa completa en `docs/SUPABASE_SETUP.md` sección "RLS Policies — gotchas conocidos".

### Recuperación ante crash de arranque

Si la app no arranca tras un cambio en preferencias de accesibilidad:

1. **Recuperación automática esperada:** al detectar dos crashes consecutivos en arranque, `BootCanary` activa `RecoveryScreen` con tres acciones (restaurar valores por defecto, continuar sin cambios, reportar el problema).
2. **Recuperación manual de último recurso:** `adb shell pm clear com.transitly.transitly` borra todas las preferencias y caches y permite arrancar con la configuración inicial.

### Bypass temporal de verificación de email

Mientras no se configure SMTP propio:

- **Supabase Dashboard → Authentication → Providers → Email:** toggle "Confirm email" en OFF.
- **Cuentas históricas sin verificar** (creadas antes del bypass): ejecutar en SQL Editor `UPDATE auth.users SET email_confirmed_at = now() WHERE email_confirmed_at IS NULL;` para desbloquearlas.
- **Reactivar verificación cuando se disponga de SMTP:** seguir los pasos descritos en `docs/SUPABASE_SETUP.md` sección "Estado actual (2026-06-04)" → "Reactivar verificación cuando se configure SMTP".

### Diagnóstico en builds release

Desde el 04/06 los niveles `warn` y `error` de `AppLogger` emiten a `logcat` también en builds release (los niveles `debug`, `info` y `perf` siguen siendo debug-only). Para capturar logs filtrados por el proceso de la app:

```powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$pid_app = & $adb -s <device-id> shell pidof com.transitly.transitly
& $adb -s <device-id> logcat -d --pid=$pid_app | Select-String "Auth|WARN|ERROR"
```

---

## Adenda 2 — Procedimientos de la release v1.12.1 (8 de junio de 2026)

### Activación del push FCM en el cliente

1. Colocar `android/app/google-services.json` del proyecto `transitly-ee8cf` (no se versiona).
2. Verificar que el plugin está activo en `android/app/build.gradle.kts`: `id("com.google.gms.google-services")` (el classpath ya está en `android/build.gradle.kts`).
3. `lib/firebase_options.dart` ya contiene las claves reales del proyecto.
4. Compilar e instalar. La app registra el token en `device_tokens` al iniciar sesión; verificación en logcat: `FlutterFirebaseMessagingBackgroundService started`.
5. Para el envío programático, configurar la *service account* como secreto de la Edge Function (ver `docs/FCM_SETUP.md`):
   ```bash
   supabase secrets set FCM_PROJECT_ID=transitly-ee8cf
   supabase secrets set FCM_SERVICE_ACCOUNT_JSON="$(cat service-account.json)"
   ```

### Modo conductor en segundo plano (foreground service)

El seguimiento usa `Geolocator.getPositionStream` con `AndroidSettings.foregroundNotificationConfig`. Requiere en `AndroidManifest.xml` los permisos `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION` y `WAKE_LOCK` (ya añadidos). No requiere paquetes adicionales.

### Publicación de la release y la web (GitHub Pages)

1. Compilar el APK universal: `flutter build apk --release --dart-define-from-file=dart_defines.json`.
2. Crear la release y subir el APK como asset (vía `gh release create` o la API REST de GitHub) con un nombre claro (`transitly-vX.Y.Z.apk`); marcarla como *latest*.
3. La web (`presentation/`) se despliega sola al hacer push a `master` tocando `presentation/**` (workflow `deploy-presentation.yml` → rama `gh-pages`). Los botones `[data-download-apk]` resuelven el APK desde `releases/latest` vía la API de GitHub, por lo que la web no necesita reconstruirse tras cada release.
