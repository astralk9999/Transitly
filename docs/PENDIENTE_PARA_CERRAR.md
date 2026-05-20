# Transitly — Pendiente para el próximo ciclo (todo, en un sitio)

> **Para qué sirve este documento:** lo que falta tras el ciclo de
> remediación cerrado el **2026-05-20**, listo para retomar. Es el
> *playbook* exhaustivo y autocontenido — no hace falta abrir otros docs.
> **Estado verificado (2026-05-20):** `master @ 2b09e8f` ·
> `flutter analyze` **0 issues** ✅ · `flutter test` **175/175** ✅ ·
> cobertura **24,30 %** (4 004/16 476 líneas) · `flutter build apk
> --release` **OK** (73,5 MB) · **CI completamente verde** verificado para
> los 4 jobs (Analyze · Test · Build Web · **Build Android APK**) en los
> commits ya completados; `2b09e8f` con 3/4 ya en `success` y Android APK
> finalizando.
> **Nota:** la rotación del PAT de Supabase (antes SEC1/PROD-4) queda
> **descartada** para este ciclo — entorno dev sin acceso al host actual,
> migración de BD próxima. Retomarla si la migración no ocurre.
> **Cómo usarlo:** §1 lo crítico para liberar releases; §2 refinos sobre
> lo aplicado; §3 inventario completo del plan general pendiente.

---

## 1. Cierre del ciclo actual

### 1.1 ✅ Sintaxis Kotlin de `android/app/build.gradle.kts` — **HECHO**

El bug Groovy/ternario en `build.gradle.kts` está corregido (commit
`5141b39`, CI Android verde). El fichero ahora usa Kotlin DSL puro:
`import java.util.Properties`, `val`/`var`, `if-else` como expresión, y
crea el `signingConfigs("release")` solo cuando `key.properties` existe.
`flutter build apk --release` produce `app-release.apk` (73,5 MB).

### 1.2 🔴 Keystore real (APK publicable) — **PENDIENTE**

Hoy `android/key.properties` y `android/upload-keystore.jks` **no existen**
en local ni CI. Sin ellos, el `if (keystorePropertiesFile.exists())` del
`build.gradle.kts` cae a la rama `debug` → el APK compila **pero no es
publicable** en Play Store (firmado con keystore de debug).

```bash
# 1. Generar keystore propio (NO commitear el .jks ni key.properties)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (plantilla en android/key.properties.example
#    + guía completa en android/README.md):
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=upload-keystore.jks

# 3. Build
flutter build apk --release
flutter build appbundle --release   # AAB para Play Store

# 4. Verificar que NO está firmado por debug
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

Para CI con Play App Signing: añadir GitHub Actions secrets
(`KEYSTORE_BASE64`, `KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS`) +
step que reconstruya `upload-keystore.jks` y `key.properties` antes del
build. Detalle en `android/README.md`.

### 1.3 🟡 Saneamiento de `AGENTS.md` — pendiente menor

`AGENTS.md` quedó con afirmaciones obsoletas que ya no son ciertas:

- **L33 "No hay CI, no hay pre-commit hook"** → falso, hay 4 jobs en CI
  (Analyze, Test, Build Web, Build Android APK). Cambiar por: *"CI activo
  en GitHub Actions con 4 jobs (Analyze, Test, Build Web, Build APK).
  Sin pre-commit hook local."*
- **L69-77 "Estado actual (12 mayo 2026): F0…F3.3"** → obsoleto. El
  `multiagent/state/project.json` dice 28/28 fases (`progress_pct: 100`).
  Reemplazar por estado real o eliminar la sección.
- **L153 "Driver editor sigue solo `es`"** → verificar tras add de `app_ar.arb`.

---

## 2. Refinos sobre lo recién aplicado

### ✅ Cerrados en el ciclo

- ✅ **§2.1** `home_tab.dart:347` migrado a `homeRouteSemanticsLabel`.
- ✅ **§2.2** `lib/data/sync/realtime_channel_manager.dart` compartido en
  stop, route, incident, route_feedback (+ `bus_position_channel_manager`
  separado para positions).
- ✅ **§2.4 (parcial)** Paginación añadida a route_suggestion y
  feature_request → **10/12 repos paginados** ahora.
- ✅ **§2.7** Cobertura re-medida (24,10→24,30 %; subió por +5 tests).
- ✅ **§2.8** `test/data/sync/realtime_channel_manager_test.dart` añadido.
- ✅ **§2.9** `android/README.md` creado con flujo de firma de release.
- ✅ **A11Y-4 residual** ("Linea" sin tilde) limpiado.
- ✅ **P3-5** `MockRealtimeService` pausa con `_paused` flag; observer
  cableado en `lib/main.dart:154-173` (`WidgetsBindingObserver` con
  `didChangeAppLifecycleState` reaccionando a paused/resumed).

### ⏳ Refinos aún pendientes

- ⚠️ **§2.4** Quedan **2 repos sin paginar** (los demás "FALTA paginar"
  son helpers, no listas):
  - `lib/data/offline_region/remote/offline_region_remote_repository.dart`
  - `lib/data/user_preferences/remote/user_preferences_remote_repository.dart`
- ⚠️ **§2.3 F13 cobertura Realtime: 5/12** (`bus_location`, `stop`, `route`,
  `incident`, `route_feedback` + `notification_stream_provider` aparte).
  Decidir qué más necesita en vivo (`operator`, `schedule`, etc. → probable
  que no; `route_suggestion`/`feature_request` → quizá para foros).
- ⚠️ **§2.5** `bus_location_remote_repository.streamForRoute` sigue con
  doble `StreamController` (snapshot inicial encima del que devuelve el
  manager). Simplificar con concat/prepend.
- ⚠️ **§2.6** `l10n.yaml` no declara locales explícitos. Verificar que
  `MaterialApp.supportedLocales` incluye `ar` y probar RTL en runtime.
- ❌ **§2.10** El "auth pattern exception" del commit `2b09e8f` debía
  documentarse: grep no encuentra la nota en AGENTS.md ni en docs/.
  Añadir explícitamente en AGENTS.md (sección Arquitectura) que
  `lib/data/auth/` **no** sigue el patrón canónico de 5 archivos por
  decisión consciente (no necesita local/mock — la sesión la gestiona
  Supabase) y por qué.

---

## 3. Pendiente del plan general (PROD / A11Y / P1 / P2 / P3)

### Bloqueadores de producción (PROD)

- **PROD-1 ⚠️ casi** — Sintaxis Kotlin corregida (§1.1 ✅). Falta keystore
  real (§1.2) para que el APK sea publicable.
- **PROD-2 ⚠️ 10/12** — Quedan 2 repos por paginar (§2.4 arriba).
- **PROD-3 ⚠️ 5/12** — Realtime cubre los repos críticos; los demás
  decidir si lo necesitan.
- ~~**PROD-4 SEC1** rotación de PAT~~ — Descartado este ciclo (dev /
  migración de BD próxima).
- **PROD-5 ⚠️ parcial (2 de ~8)** — `autoDispose` aplicado en
  `lib/shared/providers/derived/home_providers.dart` y
  `lib/shared/providers/nfc_provider.dart`. **Faltan los más críticos**:
  - `notificationStreamProvider` (Stream Supabase Realtime — debe cerrarse
    al salir de pantalla)
  - `realtimeTripsProvider` (Timer.periodic — sigue corriendo en bg)
  - `privacyConsentsProvider` (FutureProvider que se re-fetchea)
  - Todos los providers `.family` parametrizados
- **PROD-6 ❌ no hecho** — Mapa a escala: clustering por zoom,
  `RepaintBoundary`, LOD de markers.
- **PROD-7 ❌ no hecho** — Observabilidad: tracing cliente↔Edge↔DB,
  métricas de negocio, SLO/alertas, logs estructurados.
- **PROD-8 ⚠️ avanzado** — CI tiene 4 jobs incluido **Build Android APK
  verde**. Falta: build iOS, gate de cobertura con umbral declarado,
  SAST, Dependabot/Renovate, smoke E2E.
- **PROD-9 ❌ no hecho** — Caché/tenant a escala: tamaño/evicción/cifrado
  Hive; partición por `operator_id`; cifrar `live_recorder_draft`.
- **PROD-10 ❌ no hecho** — Backend a escala: FORCE RLS + auditoría,
  pooling, idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### Accesibilidad (A11Y)

- **A11Y-1 ❌ no hecho** — Alternativa accesible al mapa (lista
  equivalente enlazada + semántica del mapa).
- **A11Y-2 ✅** — `Pressable` ≥48 dp (`TransitSpacing.minTapTarget`).
- **A11Y-3 ❌ no hecho** — Verificación REAL con TalkBack/VoiceOver/Switch
  + checklist por release. Sin esto, **"AA" no es defendible**.
- **A11Y-4 ✅** — Semantics ES migrados a l10n (home_tab, card_tab,
  route_card, etc.). Auditar `Semantics(.*label:\s*['\"]` ocasionalmente.
- **A11Y-5 ✅** — `textScaler` compone el del SO.
- **A11Y-6 ❌ no hecho** — Errores accesibles y claros (no `e.toString()`).
  Archivos con `e.toString()` crudo visibles al usuario:
  - `lib/features/feedback/route_feedback_sheet.dart:207`
  - `lib/features/incidents/report_incident_sheet.dart:141`
  - `lib/features/operator_admin/drivers_screen.dart:59,109`
  - `lib/features/operator_admin/invitation_codes_screen.dart:60,89,157`
  - `lib/features/route_detail/widgets/route_officialize_modal.dart:75`
  - `lib/features/route_detail/widgets/route_share_sheet.dart:82,95,97,123`
- **A11Y-7 ❌ no hecho** — Verificar contrastes de tokens en
  `lib/core/theme/transit_colors.dart` con herramienta (Stark/axe). No
  usar color como único indicador en `status_badge`/`capacity_indicator`.
- **A11Y-8 ❌ no hecho (F26)** — Empaquetar DM Sans + IBM Plex Mono como
  assets locales y poner `_fontsBundled = true` en `lib/main.dart:22`.
  Reducir APK con app bundle/`--split-per-abi`.
- **A11Y-9 ❌ no hecho** — Foco: `FocusTraversalGroup`, visibilidad,
  teclado/switch.
- **A11Y-10 ⚠️ parcial** — `app_ar.arb` añadido. Falta probar RTL en
  runtime, verificar `supportedLocales`, cubrir lectura fácil y
  localización completa de números/fechas/moneda.

### P1 (calidad)

- **P1-1 ❌** — Strings ES visibles → l10n (≈17 críticos; coincide con
  A11Y-6 los más visibles).
- **P1-2 ✅** — A11Y-4 (Semantics → l10n).
- **P1-5 ✅** — 7 modelos a freezed.
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

- **P2-1/P2-2 ⚠️ avanzado** — Realtime 5/12 (ver PROD-3).
- **P2-3 ❌** — Unificar modelo de usuario: provider de perfil que lea
  `profiles` (con `role`) de Supabase; `currentUserProvider` → real si
  `AuthAuthenticated`, mock si guest; guard del router pasa a rol real.
- **P2-4 ❌** — Tests de la capa `remote/` (`auth_repository_supabase`,
  stop, route, bus_location, etc.) con mocks de `SupabaseClient` /
  `PostgrestClient`. Es la palanca principal para subir la cobertura.
- **P2-5 ✅** — SEC2: `Env` por `String.fromEnvironment`.
- **P2-6 ❌ (F26)** — Fuentes locales (ver A11Y-8).
- **P2-7 ❌** — CI: gate de cobertura (umbral declarado, p.ej. 24 %, que
  se eleva tras P2-4).

### P3 (deuda de fondo)

- **P3-1 ⚠️ parcial** — autoDispose (ver PROD-5: 2 providers; faltan).
- **P3-2 ❌** — Semantics para el mapa (ver A11Y-1).
- **P3-3 ⚪ deuda asumida** — Barrido masivo de `EdgeInsets`/`Color(0x`
  a tokens (≈342/≈29 ocurrencias). Bajo valor / alto ruido. Explícitamente
  NO sin tu decisión.
- **P3-4 ❌** — `live_recorder_draft`: `shared_preferences` → Hive cifrado.
- **P3-5 ✅** — `MockRealtimeService.pause/resume` con observer cableado.
- **P3-6 ⚠️** — Patrón `data/auth/` sigue incompleto; "documentar la
  excepción" del commit `2b09e8f` falta verificar (ver §2.10 arriba).
- **P3-7 ❌** — Descomponer `privacy_screen.dart` (>300 LoC) e
  `inbox_action_sheets.dart` (347 LoC).
- **P3-8 ⚠️ parcial (CI)** — Build Android añadido y verde; faltan
  iOS, Dependabot/Renovate, SAST.

---

## 4. Comandos exactos de verificación (copy-paste)

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze                     # → No issues found!
flutter test --coverage             # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "cov=%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
flutter build apk --release         # → √ Built app-release.apk (~73 MB)
# Con key.properties: verificar firma real
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | head -20
```

Tras pushear, consulta `https://github.com/astralk9999/Transitly/actions` y
verifica los 4 jobs (Analyze, Test, Build Web, Build Android APK) en `success`.

---

## 5. Resumen ejecutivo del próximo ciclo

- **CI:** ya completamente verde (incluido Build Android APK). El
  bloqueador Kotlin DSL del ciclo anterior está cerrado.
- **APK release publicable:** falta solo §1.2 (≈15 min — keystore + Play
  App Signing). Sin esto, el APK compila pero se firma con debug.
- **AGENTS.md:** §1.3 saneamiento menor (afirmaciones obsoletas sobre CI
  y estado de fases).
- **"Producción a escala" en serio:** los bloques PROD/A11Y/P2 (semanas de
  trabajo). Avanzaron: paginación 10/12, Realtime 5/12, autoDispose 2,
  Build APK CI. Faltan los grandes (observabilidad, modelo de usuario,
  tests de la capa remote/, accesibilidad real con lector de pantalla).
- **"AA" defendible en accesibilidad:** A11Y-1/3/6/7/9 mínimos. Sin un
  paso REAL con TalkBack/VoiceOver, "AA" no es defendible.
- **Acción externa pendiente:** ninguna obligatoria en este ciclo (PAT
  descartado).

### Cambios respecto al playbook anterior (2026-05-20 mañana)

✅ **Cerrados:**
- §1.1 Kotlin DSL en `build.gradle.kts` (`5141b39`, CI Android verde).
- §2.4 +2 repos paginados (route_suggestion, feature_request) → 10/12.
- §2.8 tests del `RealtimeChannelManager` (`test/data/sync/`).
- §2.9 `android/README.md` con flujo de firma.
- P3-5 `MockRealtimeService` con `WidgetsBindingObserver` real.
- A11Y-4 residual `Linea` → `Línea`/l10n.
- PROD-5 autoDispose en 2 providers (home_providers, nfc_provider).
- Cobertura: 24,10 → 24,30 %. Tests: 170 → 175.

⏳ **Sigue pendiente del playbook previo:**
- §1.2 keystore real (sin él, APK no publicable).
- §1.3 AGENTS.md tiene afirmaciones obsoletas (CI, fases).
- §2.5 `streamForRoute` doble controller.
- §2.6 RTL probado en runtime.
- §2.10 documentar excepción del patrón `data/auth/`.
- Bloque PROD/A11Y/P1/P2/P3 mayoritariamente intacto.
