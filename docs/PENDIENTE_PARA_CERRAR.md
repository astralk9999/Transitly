# Transitly — Pendiente para el próximo ciclo (todo, en un sitio)

> **Para qué sirve este documento:** lo que falta tras el ciclo de
> remediación cerrado el **2026-05-20**, listo para retomar. Es el
> *playbook* exhaustivo y autocontenido — no hace falta abrir otros docs.
> **Estado verificado (2026-05-20):** `master @ dc76cc3` ·
> `flutter analyze` **0 issues** ✅ · `flutter test` **170/170** ✅ ·
> cobertura **24,10 %** (3 967/16 461 líneas; bajó 0,6 pp por LOC nuevo
> sin tests proporcionales) · **CI 3 de 4 jobs verdes**
> (Analyze ✅ · Test ✅ · Build Web ✅ · **Build Android APK ❌**).
> **Nota:** la rotación del PAT de Supabase (antes SEC1/PROD-4) queda
> **descartada** para este ciclo — entorno de desarrollo sin acceso al
> host actual; se asume migración de BD próximamente, lo que invalidará
> el token de facto. Si la migración no ocurre, retomarlo.
> **Cómo usarlo:** §1 para volver a verde inmediato; §2 para refinar lo
> aplicado; §3 inventario pendiente del plan general.

---

## 1. Cierre del ciclo actual (URGENTE — para devolver CI a verde)

### 1.1 🔴 BLOQUEADOR — Arreglar la sintaxis Kotlin de `android/app/build.gradle.kts`

**Síntoma:** el job nuevo *Build Android APK* del CI falla con **21 errores
Kotlin** (`Expecting an element`); `flutter build apk --release` también
fallaría en local. Es **regresión funcional** del lote PROD-1: el fichero
acabó **mezclando Groovy con Kotlin DSL** y usando ternario C-style.

**Dos correcciones, una por bloque:**

A) **Líneas 7-14 — `def`/`new` son Groovy, no Kotlin DSL.** Reemplaza:
```kotlin
def keystorePropertiesFile = rootProject.file("key.properties")
def keystoreProperties = new Properties()
def useReleaseSigning = false
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
    useReleaseSigning = true
}
```
Por:
```kotlin
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = java.util.Properties()
var useReleaseSigning = false
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
    useReleaseSigning = true
}
```

B) **Líneas 52-54 — Kotlin no tiene ternario `?:` C-style.** Reemplaza:
```kotlin
signingConfig = useReleaseSigning
    ? signingConfigs.getByName("release")
    : signingConfigs.getByName("debug")
```
Por:
```kotlin
signingConfig = if (useReleaseSigning)
    signingConfigs.getByName("release")
else
    signingConfigs.getByName("debug")
```

**Verificación:**
```bash
flutter build apk --release    # debe producir app-release.apk (~73 MB)
```
Aunque no haya `key.properties` aún, el ternario debe resolver a
`debug` y compilar (apk no publicable, pero sí compilable — eso es lo que
desbloquea el CI). El APK release **real** requiere también §1.2.

### 1.2 🔴 Keystore real (APK publicable)

Hoy `android/key.properties` y `android/upload-keystore.jks` **no existen**
en local ni CI (gitignored). Sin ellos, aunque §1.1 esté arreglado, el APK
se firma con la keystore de debug → **no publicable** en Play Store.

```bash
# 1. Generar keystore propio (NO commitear el .jks ni key.properties)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (plantilla en android/key.properties.example)
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=upload-keystore.jks

# 3. Build
flutter build apk --release
flutter build appbundle --release   # para Play Store

# 4. Verificar que NO está firmado por debug
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

Para el CI (Play App Signing): añadir los 4 valores como GitHub Actions
secrets (`KEYSTORE_BASE64`, `KEY_STORE_PASSWORD`, `KEY_PASSWORD`,
`KEY_ALIAS`) y un step que reconstruya `upload-keystore.jks` +
`key.properties` antes del build.

### 1.3 (Si se hace §1.1+§1.2) Verificación y commit

```bash
flutter analyze            # No issues found!
flutter test --coverage    # All tests passed!
flutter build apk --release
git add android/app/build.gradle.kts
git commit -m "fix(android): correct Kotlin DSL syntax in build.gradle.kts"
git push origin master
# Verificar en GitHub Actions: los 4 jobs en success.
```

---

## 2. Refinos sobre lo recién aplicado (calidad, no bloqueante)

Estado de los refinos que pedía el playbook anterior:

- ✅ **§2.1** `home_tab.dart:347` ya usa `homeRouteSemanticsLabel(route.code, time)`.
- ✅ **§2.2** ChannelManager para stop/route → **mejor de lo pedido**: se
  creó `lib/data/sync/realtime_channel_manager.dart` **compartido** y lo
  usan stop, route, incident y route_feedback. bus_location mantiene su
  `bus_position_channel_manager.dart` específico.
- ⚠️ **§2.3** F13 cobertura: ahora **5 de 12** repos con Realtime real
  (`bus_location`, `stop`, `route`, `incident`, `route_feedback`). Quedan
  sin Realtime (decidir cuáles lo necesitan): `route_suggestion`,
  `feature_request`, `operator`, `schedule`, `notification`,
  `user_preferences`, `offline_region`. *Nota: `notification` tiene
  Realtime en `notification_stream_provider.dart`, fuera del repo.*
- ⚠️ **§2.4** Paginación: ahora **8 de 12** repos paginados (añadidos:
  stop, route, incident, route_feedback). **Faltan paginar 4:**
  - `lib/data/feature_request/remote/feature_request_remote_repository.dart`
  - `lib/data/route_suggestion/remote/route_suggestion_remote_repository.dart`
  - `lib/data/user_preferences/remote/user_preferences_remote_repository.dart`
  - `lib/data/offline_region/remote/offline_region_remote_repository.dart`
  Patrón a seguir: parámetros `int? offset, int? limit` →
  `range(offset, offset+limit-1)`; tope por defecto 100; UI con
  `ListView.builder` + paginación al llegar al final.
- ⚠️ **§2.5** `bus_location_remote_repository.streamForRoute` aún hace
  doble controller (snapshot inicial + canal en `StreamController` propio
  encima del que devuelve el manager). Simplificar (usar concat/prepend).
- ❌ **§2.6** `l10n.yaml` sigue sin declarar locales explícitos. Verifica
  en runtime que `MaterialApp.supportedLocales` incluye `ar` (debería
  via `AppLocalizations.supportedLocales`) y prueba RTL real en
  dispositivo.
- ✅ **§2.7** cobertura re-medida: **24,10 %** (3 967/16 461). Baja 0,6
  pp respecto a 24,74 % — esperable porque entró LOC nuevo (ChannelManager,
  paginación, freezed migrations) sin la misma proporción de tests.
  Actualiza la cifra en `docs/00_MAESTRO.md`, `docs/tfg/05`,
  `docs/PLAN_ACCION_REMEDIACION.md`.
- ❌ **§2.8** Tests del `BusPositionChannelManager` y
  `RealtimeChannelManager` — la lógica de reintentos/backoff con jitter
  no está probada de forma determinista (`fake_async` + inyección de
  `Random`/`Duration`).
- ❌ **§2.9** Doc del flujo de firma de release (`android/README.md` o
  ampliar `docs/PLATFORM_SETUP.md`): cómo generar `upload-keystore.jks`,
  Play App Signing, secrets en CI.
- ⚠️ **Lints §1.1** del anterior playbook se cerraron vía
  `// ignore: prefer_const_constructors` (4 en `operator_remote_error_test.dart`,
  1 en `a11y_semantics_test.dart`). Funcional y aceptable; si quieres
  rigor, comprobar si el constructor de `PostgrestException` y los
  `Color(...)` pueden ser `const` y quitar los ignores.

---

## 3. Pendiente del plan general (PROD / A11Y / P1 / P2 / P3)

### Bloqueadores de producción (PROD)

- **PROD-1 ⚠️ regresión funcional** — Lógica de signing condicional bien
  planteada pero **rota por sintaxis Kotlin** (§1.1). Y falta el keystore
  real (§1.2). Hasta entonces, el APK release **no es publicable**.
- **PROD-2 ⚠️ avanzado (8/12)** — Quedan 4 repos por paginar (§2.4).
- **PROD-3 ⚠️ avanzado (5/12)** — Realtime real cubre bus_location, stop,
  route, incident, route_feedback. Decidir cuáles más necesitan en vivo.
- ~~**PROD-4 SEC1** rotación de PAT~~ — **Descartado este ciclo** (entorno
  dev sin acceso al host; migración de BD próxima invalida el token).
- **PROD-5 ❌ no hecho** — `autoDispose` en providers críticos
  (`nfcScanProvider`, `notificationStreamProvider`, `realtimeTripsProvider`,
  `privacyConsentsProvider`, providers `.family`). Sin esto, fugas de
  memoria y canales/timers vivos tras salir de pantalla.
- **PROD-6 ❌ no hecho** — Mapa a escala (clustering por zoom,
  `RepaintBoundary`, LOD de markers).
- **PROD-7 ❌ no hecho** — Observabilidad: tracing cliente↔Edge↔DB,
  métricas de negocio, SLO/alertas, logs estructurados para agregación.
- **PROD-8 ⚠️ parcial** — CI ya tiene job de **Build Android APK** (bien),
  pero falla por §1.1; sigue faltando: gate de cobertura con umbral,
  build iOS, SAST, Dependabot, smoke E2E.
- **PROD-9 ❌ no hecho** — Caché/tenant a escala: tamaño/evicción/cifrado
  Hive; partición por `operator_id`; cifrar `live_recorder_draft`.
- **PROD-10 ❌ no hecho** — Backend a escala: FORCE RLS + auditoría,
  pooling, idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### Accesibilidad (A11Y)

- **A11Y-1 ❌ no hecho** — Alternativa accesible al mapa (lista equivalente
  enlazada + semántica del mapa). El mapa sigue sin `Semantics`.
- **A11Y-2 ✅** — `Pressable` con suelo 48 dp (`TransitSpacing.minTapTarget`).
- **A11Y-3 ❌ no hecho** — Verificación REAL con TalkBack/VoiceOver/Switch
  + checklist por release. Sin esto no es defendible "AA".
- **A11Y-4 ✅ mayoritariamente** — Semantics ES migrados a l10n en home_tab,
  card_tab, etc. (queda algún caso menor en otras pantallas; auditar grep
  `Semantics(.*label:\s*['\"]`).
- **A11Y-5 ✅** — `textScaler` compone el del SO (`MediaQuery.textScalerOf`).
- **A11Y-6 ❌ no hecho** — Errores accesibles y claros (no `e.toString()`).
  Archivos con `e.toString()` crudo visibles al usuario:
  - `lib/features/feedback/route_feedback_sheet.dart:207`
  - `lib/features/incidents/report_incident_sheet.dart:141`
  - `lib/features/operator_admin/drivers_screen.dart:59,109`
  - `lib/features/operator_admin/invitation_codes_screen.dart:60,89,157`
  - `lib/features/route_detail/widgets/route_officialize_modal.dart:75`
  - `lib/features/route_detail/widgets/route_share_sheet.dart:82,95,97,123`
- **A11Y-7 ❌ no hecho** — Verificar contrastes de tokens base en
  `lib/core/theme/transit_colors.dart` con herramienta (Stark/axe). Texto
  secundario sobre `GlassCard` translúcido es sospechoso. No usar color
  como único indicador (añadir icono/forma a `status_badge`/`capacity_indicator`).
- **A11Y-8 ❌ no hecho (F26)** — Empaquetar DM Sans + IBM Plex Mono como
  assets locales y poner `_fontsBundled = true` en `lib/main.dart:22`.
  Reducir APK con `--split-per-abi` (ya activado en CI) o app bundle.
- **A11Y-9 ❌ no hecho** — Foco: `FocusTraversalGroup` por sección,
  visibilidad de foco, soporte teclado/switch.
- **A11Y-10 ⚠️ parcial** — `app_ar.arb` añadido. Falta probar RTL en
  runtime, verificar `supportedLocales`, cubrir lectura fácil y
  localización completa de números/fechas/moneda.

### P1 (calidad)

- **P1-1 ❌** — Strings ES visibles → l10n (≈17 críticos; lista exacta en
  PLAN_ACCION_REMEDIACION.md §P1-1 y arriba en A11Y-6).
- **P1-2 ✅ mayoritariamente** — A11Y-4 (ver arriba).
- **P1-5 ✅** — 7 modelos a freezed (hecho).
- **P1-6 ❌** — Tokens en `lib/shared/widgets/`: 11 usos de `GoogleFonts.*`
  inline en `empty_state`, `error_card`, `reputation_badge`, `route_card`,
  `status_badge`, `transit_button`, `transit_chip`. Crear variantes de
  `TransitTypography` y migrar.
- **P1-7 ❌** — Tokens en widgets extraídos por la descomposición I1
  (≈15 widgets de `features/appearance/` + `features/management/`).
- **P1-8 ❌** — Eliminar `lib/features/management/widgets/action_button.dart`
  y reemplazar por `TransitButton(isPrimary:false, isSmall:true)`.
- **P1-9 ❌** — `inbox_action_sheets.dart`: 3 `showModalBottomSheet`
  inline → `showTransitBottomSheet`.
- **P1-10 ❌** — `privacy_screen._setConsent`: `if (!mounted) return;`
  antes de `ref.invalidate`; `unawaited(...)` explícito en el caller.
- **P1-11 ❌** — Issues F16/F22 de `PENDIENTES.md` (validación inline,
  unique-violation, dedupe mapping, loading en botones de estado, cola
  offline en `updateStatus`).

### P2 (núcleo + cobertura)

- **P2-1/P2-2 ⚠️ avanzado** — Realtime cubre 5/12 (ver PROD-3).
- **P2-3 ❌** — Unificar modelo de usuario: provider de perfil que lea
  `profiles` (con `role`) de Supabase; `currentUserProvider` → real si
  `AuthAuthenticated`, mock si guest; guard del router pasa a rol real.
- **P2-4 ❌** — Tests de la capa `remote/` (`auth_repository_supabase`,
  stop, route, bus_location, etc.) con mocks de `SupabaseClient` /
  `PostgrestClient`. Sigue arrastrando la cobertura a la baja.
- **P2-5 ✅** — SEC2 hecho: `Env` por `String.fromEnvironment`.
- **P2-6 ❌ (F26)** — Fuentes locales (ver A11Y-8).
- **P2-7 ❌** — CI: gate de cobertura (umbral declarado, p.ej. 24 %, que
  se eleva tras P2-4).

### P3 (deuda de fondo)

- **P3-1 ❌** — `autoDispose` selectivo (ver PROD-5).
- **P3-2 ❌** — Semantics para el mapa (ver A11Y-1).
- **P3-3 ⚪ deuda asumida** — Barrido masivo de `EdgeInsets`/`Color(0x`
  a tokens (≈342/≈29 ocurrencias). Explícitamente NO se hará sin tu
  decisión: bajo valor / alto ruido.
- **P3-4 ❌** — `live_recorder_draft`: `shared_preferences` → Hive cifrado.
- **P3-5 ❌** — `MockRealtimeService`: pausar `Timer.periodic` en
  `AppLifecycleState.paused`.
- **P3-6 ❌** — Completar patrón canónico de `lib/data/auth/` (faltan
  `local`/`mock`/`provider`; nomenclatura `abstract_…`) o documentar la
  excepción en AGENTS.md.
- **P3-7 ❌** — Descomponer `privacy_screen.dart` (>300 LoC) e
  `inbox_action_sheets.dart` (347 LoC).
- **P3-8 ⚠️ parcial (CI)** — Build Android añadido (PROD-8) pero rojo;
  faltan Dependabot/Renovate y build iOS.

---

## 4. Comandos exactos de verificación (copy-paste)

Al cerrar cada lote, ejecuta esto y todo debe estar verde:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze                     # → No issues found!
flutter test --coverage             # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "cov=%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
flutter build apk --release         # → √ Built app-release.apk (~73 MB)
# Si tienes key.properties: comprueba con jarsigner que NO está firmado por debug:
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | head -20
```

Tras pushear, consulta el último run en
`https://github.com/astralk9999/Transitly/actions` y verifica los 4 jobs
(Analyze, Test, Build Web, **Build Android APK**) en `success`.

---

## 5. Resumen ejecutivo del próximo ciclo

- **Lo que falta para que CI vuelva a verde:** §1.1 (≈5 min — sintaxis
  Kotlin del `build.gradle.kts`). **Es el bloqueador inmediato.**
- **Lo que falta para que sea release publicable:** §1.2 (≈15 min —
  generar keystore + `key.properties` + Play App Signing).
- **Lo que falta para "producción a escala" en serio:** los bloques PROD,
  A11Y, P2 (semanas de trabajo). Ninguno es opcional para escalar.
- **Lo que falta para "AA" defendible en accesibilidad:** A11Y-1/3/6/7/9
  mínimos. Sin un paso REAL con lector de pantalla, "AA" no es
  defendible aunque se complete el resto.
- **Acción externa pendiente:** *(ninguna obligatoria en este ciclo —
  la rotación de PAT queda fuera de alcance hasta la migración de BD).*

### Cambios respecto al playbook anterior

- ✅ Hechos en el ciclo cerrado: lints (vía `// ignore`), `flutter_dotenv`
  eliminado, `home_tab.dart:347` a l10n, ChannelManager compartido para
  stop/route/incident/route_feedback, paginación añadida a 4 repos,
  job de Build Android APK en CI, +22 tests (148→170).
- 🆕 Bloqueador detectado: sintaxis Kotlin en `build.gradle.kts` (§1.1).
- 🗑️ Descartado: rotación de PAT (PROD-4) — fuera de alcance en dev.
