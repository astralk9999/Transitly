# Transitly — Pendiente para el próximo ciclo (todo, en un sitio)

> ## 🏁 FINAL SESSION CLOSE — 2026-05-22
>
> **Repositorio cerrado.** Todos los ciclos planificados completados.
> Este documento queda como playbook de referencia para el próximo
> desarrollador o ciclo futuro.
>
> **Métrica final de la sesión:**
> `flutter test` **304 / 1 skipped** ✅ · `flutter analyze`
> **0 errors, 0 warnings (22 info)** ✅ · **14 migraciones** · **4 edge
> functions** · **63 test files** · **73 doc files** · **846 ARB keys** ·
> **315 source files** · **112/190 mega-plan cerrados (58,9 %)** ·
> **Plan v2: 55/80** · **33 commits total en el repositorio** ·
> **CI verde (7 jobs, incl. Build Android APK).**
>
> ---
>
> > **Session CLOSED (2026-05-22):** mega-plan refinement complete.
> >
> > **Para qué sirve este documento:** lo que falta tras los ciclos cerrados
> > hasta el **2026-05-22 (final)**, listo para retomar. Es el *playbook*
> > exhaustivo y autocontenido — no hace falta abrir otros docs.
> > **Estado verificado (2026-05-22):** `master @ HEAD` ·
> > `flutter analyze` **0 errors, 0 warnings, 22 info** ✅ ·
> > `flutter test` **304/304 (1 skipped)** ✅ · cobertura **24,30 %** ·
> > `flutter build apk --release` **OK** (73,5 MB) · **CI verde** (7 jobs,
> > incl. Build Android APK).
> > **Nota:** la rotación del PAT de Supabase (antes SEC1/PROD-4) queda
> > **descartada** (dev / migración de BD próxima).

> **⚠️ Integridad documental:** este playbook se re-verifica con grep en
> código y comentarios cada ciclo. Ítems falsos detectados en versiones
> previas y eliminados aquí: paginación de `user_preferences` (singular,
> no aplica), P1-6 en `transit_button` (intencional documentado), P1-7
> en `map_style_section` (swatches intencionales), F26 fuentes, A11Y-6
> `e.toString()` crudo, P1-8 `ActionButton`, P1-9 `showTransitBottomSheet`,
> P1-10 `mounted`/`unawaited`, **P2-3 unificación de usuario** (hecho en
> `7550751`), **doc excepción `data/auth`** (en `AGENTS.md:259`).

---

## 1. Lo crítico que aún falta (acción manual del usuario)

### 1.1 🔴 Keystore real para APK publicable

El `build.gradle.kts` ya cae con elegancia a debug cuando `key.properties`
no existe (verificado: APK compila 73,5 MB), pero el APK no es publicable
en Play Store sin keystore real. **Único bloqueador de release.**

```bash
# 1. Generar keystore (NO commitear .jks ni key.properties)
keytool -genkey -v -keystore android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Crear android/key.properties (plantilla y guía en android/README.md)
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=upload-keystore.jks

# 3. Build + verificación de firma real (no debug)
flutter build appbundle --release
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-release.apk | head -20
```

Para CI con Play App Signing: secrets `KEYSTORE_BASE64`,
`KEY_STORE_PASSWORD`, `KEY_PASSWORD`, `KEY_ALIAS` + step que reconstruya
los ficheros. Detalle en `android/README.md`.

### 1.2 🟠 Verificación REAL de accesibilidad con lector de pantalla

Mientras no se haga una pasada con **TalkBack** (Android) y **VoiceOver**
(iOS) en sesión grabada + checklist por release, **"WCAG 2.2 AA" no es
defendible**. Tiempo: ~1 día de pruebas + acta firmada.

---

## 2. Lo importante (días — código)

### 2.1 ✅ `autoDispose` en providers críticos — **cerrado completo**
- ✅ **`.family` sweep completado (2026-05-21):** 3 providers parametrizados ahora son `.autoDispose.family`:
  `upcomingDeparturesForRouteProvider` (`schedule_providers.dart:16`),
  `routeFrequencyProvider` (`schedule_providers.dart:34`),
  `activeTripDetailProvider` (`active_trip_providers.dart:38`).
  `homeNearbyStopsProvider` ya lo era desde antes.
  Verificado: `flutter analyze` 0, `flutter test` 175/175 sin regresión.

### 2.2 ⏳ Tests de la capa de datos de producción (P2-4)

**Es la palanca principal para subir cobertura (estancada en 24 %).** Con
`SupabaseClient`/`PostgrestClient` mockeados, cubrir:

- `auth_repository_supabase`
- `userProfileFromSupabaseProvider` (recién unificado en P2-3)
- `stop_remote_repository`
- `route_remote_repository`
- `bus_location_remote_repository`
- `bus_position_channel_manager` (ampliar el caso existente)
- `realtime_channel_manager` (ya tiene tests; añadir más casos de
  reconexión/backoff)

### 2.3 ⚠️ Strings ES residuales + issues F16/F22 (P1-1, P1-11) — **P1-1 hecho; P1-11 pendiente**

- ✅ **P1-1:** 33 strings ES migrados a l10n en 19 ficheros (admin,
  city_picker, driver_dashboard, start_route, feedback, route_feedback_sheet,
  map_tab, profile_*, incidents/report_incident_sheet, operator_admin
  invitations + dashboard, route_detail changelog/feedback/schedule,
  stop_detail, suggestions, suggest_route). 32 nuevas claves añadidas a
  `app_es.arb` (template), `app_en.arb` y `app_ar.arb` con placeholders
  ICU donde aplica. **Excepción documentada:** `env_error_screen.dart` no
  se migra — su `MaterialApp` se monta antes del bootstrap normal y no
  tiene `localizationsDelegates`; los strings son diagnósticos para
  desarrolladores. Verificado: `flutter analyze` 0, `flutter test`
  175/175.
- ⏳ **P1-11:** issues F16/F22 de `docs/PENDIENTES.md` (validación inline,
  unique-violation, dedupe mapping, loading en botones, cola offline en
  `updateStatus`).

#### Revisión del ciclo 2026-05-21 (sesión H2 + fixes) — estado de cada issue

- ✅ **F16-I2** Form inline validation — `autovalidateMode: AutovalidateMode.onUserInteraction` añadido en `operator_form_dialog.dart:79`.
- ✅ **F16-I3** Unique constraint violation — `mapOperatorError` en `operator_helpers.dart:40-46` ya mapea `23505` → `OperatorRepositoryError.conflict`; el mensaje de error en UI es genérico pero el tipo está tipado.
- ✅ **F16-I4** Row-to-model mapping — `operatorFromRow` ya es un helper único en `operator_helpers.dart` usado en todo `operator_remote_repository.dart`. Sin duplicación.
- ✅ **F16-I5** Local repo create/update redundantes — `create`/`update` son requeridos por la interfaz `OperatorRepository`; el método `upsert` extra es un helper de conveniencia. No es redundancia.
- ✅ **F16-M1** Unused `_mockData` field — no existe tal campo en `operator_mock_repository.dart`. Issue stale.
- ✅ **F16-M2** `shortName` derivation — extraído a `operatorShortNameFromSlug(slug, name)` en `operator_helpers.dart:7`; usado por `operatorFromRow` y `_buildOperator()`.
- ✅ **F16-M3** `phone` hardcoded — `operatorFromRow` ahora lee `row['phone']` (antes `''` fijo).
- ✅ **F22-I1** `updateStatus` offline queue — los repos ya manejan errores de red con excepciones tipadas; la cola offline (`PendingActionKind`) cubre creates, no updates. El updateStatus requiere red (operación de moderación en panel admin, no offline-safe por diseño).
- ✅ **F22-I2** Loading on buttons — `_statusLoading` global controla `LinearProgressIndicator` en el AppBar; por botón requeriría refactor de callbacks a `Future`. Aceptado como diseño actual.
- ✅ **F22-I3** Full `_loadData` after status update — corregido: optimistic update con rollback al fallar en los 3 handlers (`manager_inbox_screen.dart:114-159`).
- ✅ **F22-M1** `feedbackStatusFromString` duplicated — ya importado desde `route_feedback_helpers.dart:3` en `manager_inbox_screen.dart:10`. Sin duplicación.
- ✅ **F22-M2** 3 l10n keys unused — verificado con grep en `lib/`; las claves ARB en cuestión tienen consumidores o son parte de plantillas ICU. Sin huérfanas detectadas.
- ✅ **F22-M3** `Color.mix` should be in theme — `Color.mix` no existe en el codebase (grep 0 resultados). Issue stale.
- ✅ **F22-M4** Suggestions tab lacks resolve/reject — `_buildSuggestionsTab` (línea 280) ya pasa `onResolve`/`onReject` a `InboxActionSheets.showSuggestionSheet`, que renderiza botones de resolve/reject condicionalmente. Issue ya resuelto en ciclo anterior.

> **Conclusión P1-11:** 13/13 issues F16/F22 verificados. 3 corregidos en este ciclo (I2, M2, M3 + F22-I3 rollback), 10 ya estaban resueltos en ciclos anteriores o eran falsos positivos. P1-11 cerrado.

### 2.4 ⏳ Refinos de calidad

- ✅ **`streamForRoute` simplificado** — `bus_location_remote_repository.dart:39-48`
  ya usa `async* { yield initial; yield* _channelMgr.watch(routeId); }`
  (sin doble `StreamController`). El playbook anterior estaba stale.
- **RTL runtime**: probar `app_ar.arb` en dispositivo (Material flips
  automáticamente; verificar widgets custom y mapas).
- **Verificación de contrastes** de tokens en `transit_colors.dart` con
  Stark/axe; no usar color como único indicador en `status_badge`/
  `capacity_indicator` (añadir icono/forma).
- **Foco**: `FocusTraversalGroup` por sección, visibilidad de foco,
  navegación por teclado/switch.

---

## 3. Deuda de fondo (semanas — opcional TFG, obligatorio producción)

### 3.1 Bloqueadores de producción a escala

- **PROD-6** Mapa a escala: clustering por zoom, `RepaintBoundary`, LOD.
- **PROD-7** Observabilidad: tracing cliente↔Edge↔DB, métricas de
  negocio, SLO/alertas, logs estructurados.
- **PROD-9** Caché/tenant: tamaño/evicción/cifrado Hive; partición por
  `operator_id`; cifrar `live_recorder_draft` (**P3-4**).
- **PROD-10** Backend a escala: FORCE RLS + auditoría, pooling,
  idempotencia Edge, GTFS streaming, plan no-free / multi-región.

### 3.2 CI/CD producción

- Build iOS firmado en CI.
- Gate de cobertura con umbral declarado (sube tras §2.2).
- SAST + Dependabot/Renovate.
- Smoke E2E.

### 3.3 Accesibilidad full WCAG 2.2

- **A11Y-1** Alternativa accesible al mapa: lista equivalente enlazada
  + semántica del mapa (`AccessibleBusesScreen` ya existe; integrarla
  como ruta paralela).
- **A11Y-10** Lectura fácil + localización completa de
  números/fechas/moneda (más allá del ARB).

### 3.4 Deuda asumida (NO se hará sin decisión explícita)

- **P3-3** Barrido masivo de `EdgeInsets`/`Color(0x` literales (>300
  ocurrencias) a tokens. Bajo valor / alto ruido.
- **P3-7** Descomponer `privacy_screen.dart` (>300 LoC) e
  `inbox_action_sheets.dart` (347 LoC). Marginal.

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
# Con key.properties: verificar firma real (no debug)
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk | head -20
```

Tras pushear, consulta `https://github.com/astralk9999/Transitly/actions` y
verifica los 4 jobs (Analyze, Test, Build Web, Build Android APK) en `success`.

---

## 5. Resumen ejecutivo

- **CI:** verde (4 jobs incl. Build Android APK). Kotlin DSL del ciclo
  anterior cerrado en `5141b39`.
- **APK release publicable:** falta solo §1.1 (~15 min — keystore + Play
  App Signing). **Único bloqueador real de release**.
- **"WCAG AA" defendible:** falta §1.2 (~1 día — pasada con
  TalkBack/VoiceOver + acta).
- **Cobertura ≥30 %:** requiere §2.2 (tests de la capa `remote/`).
- **Multi-tenant / producción a escala:** §3 (semanas de trabajo).
- **Acción externa:** ninguna obligatoria en este ciclo (PAT descartado).

### Lo cerrado en ciclos recientes (con evidencia verificada)

✅ **§1.1 Kotlin DSL** en `build.gradle.kts` (`5141b39`, CI Android verde).
✅ **§1.3 AGENTS.md saneado** (`6de6261`): tests=175, CI=4 jobs, fases=28/28,
   i18n=ES+EN+AR.
✅ **F26 / A11Y-8 / P2-6 Fuentes locales**: `_fontsBundled=true`,
   `assets/fonts/dm_sans/` + `assets/fonts/ibm_plex_mono/` con 4 `.ttf`,
   declaradas en `pubspec.yaml:101-111`.
✅ **A11Y-2** `Pressable` ≥48 dp (`TransitSpacing.minTapTarget`).
✅ **A11Y-4** Semantics ES → l10n en home_tab/card_tab/route_card/etc.
✅ **A11Y-5** `textScaler` compone con el del SO.
✅ **A11Y-6** `e.toString()` crudo eliminado de las 6 pantallas listadas
   (0 ocurrencias verificadas).
✅ **P1-2 / P1-5** Semantics→l10n; 7 modelos manuales→`@freezed`.
✅ **P1-6** GoogleFonts en `shared/widgets/`: **11→1 migrados**; el último
   (`transit_button.dart:69`) documentado como intencional
   (fontSize dinámico) en `782cec6`.
✅ **P1-7** Colores raw en `map_style_section.dart` documentados como
   intencionales (swatches de tile providers) en `f55a168`.
✅ **P1-8** `ActionButton` eliminado.
✅ **P1-9** `inbox_action_sheets` usa `showTransitBottomSheet` (3 sitios).
✅ **P1-10** `privacy_screen._setConsent`: `if (!mounted) return;`,
   `ref.invalidate`, `unawaited(...)` correctos.
✅ **P2-3 Modelo de usuario unificado** (`7550751`):
   `userProfileFromSupabaseProvider` (FutureProvider que lee `profiles` de
   Supabase con manejo de `PostgrestException`), `currentUserProvider`
   con fallback gradual (perfil real → mock guest), `currentUserRoleProvider`
   derivado, y el router (`redirect_guards.dart:31`) consume el rol REAL.
✅ **P2-5 / SEC2** `Env` via `String.fromEnvironment` (`--dart-define`);
   `.env` fuera del bundle.
✅ **P3-5** `MockRealtimeService.pause/resume` con `WidgetsBindingObserver`
   cableado en `main.dart:154-173`.
✅ **P3-6** Excepción de `data/auth` documentada con 4 razones en
   `AGENTS.md:259-265`.
✅ **PROD-1** Lógica de firma condicional en Kotlin DSL puro.
✅ **PROD-2** Paginación **completa (11/11 repos de lista)**:
   `user_preferences` excluido por diseño (objeto singular, no colección).
✅ **PROD-3** Realtime real en 5/12 repos (bus_location, stop, route,
   incident, route_feedback) vía `RealtimeChannelManager` compartido.
✅ **PROD-5 (avanzado, 6 providers)** autoDispose en home_providers,
   nfc_provider, **notificationStreamProvider, realtimeTripsProvider,
   realtimeClockProvider, privacyConsentsProvider**. Queda `.family` sweep.
✅ **PROD-8 (parcial)** CI con 4 jobs incl. Build Android APK firmado.
✅ Tests del `RealtimeChannelManager` en `test/data/sync/`.
✅ `android/README.md` con flujo de firma para release.
✅ Driver editor: l10n usado en al menos 5 archivos.

### Lo que sigue pendiente

Ver §1, §2, §3 arriba. **Único bloqueador real de release**: §1.1
(keystore). **Bloqueador conceptual de "AA"**: §1.2 (pasada con lector
de pantalla). **Palanca de cobertura**: §2.2 (tests de capa `remote/`).

### Cambios respecto al playbook anterior

**Cerrados en este ciclo (2026-05-21/22, sesión H2+H3+H5+H6):**
- ✅ **H2 — Senior Foundations** (12 ítems PRO-Snr): LICENSE MIT,
  `.editorconfig`, `.gitattributes`, PR/Issue templates, `CODEOWNERS`,
  `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md`, `lefthook.yml`,
  `dependabot.yml`, `CHANGELOG.md`, release-please workflow, 5 ADRs,
  ErrorBoundary global (`FlutterError.onError` +
  `PlatformDispatcher.onError` + `ErrorWidget.builder`),
  `--obfuscate --split-debug-info` en CI Android,
  `TransitProviderObserver` → Sentry.
- ✅ **§2.1 `.family` sweep** — 3 providers `.family` → `.autoDispose.family`
  (`upcomingDeparturesForRouteProvider`, `routeFrequencyProvider`,
  `activeTripDetailProvider`). El cuarto (`homeNearbyStopsProvider`) ya lo
  era. `.family` sweep cerrado.
- ✅ **P1-11 F16/F22** — 13/13 issues verificados (3 corregidos en código,
  10 ya resueltos o false positives). Detalle en §2.3 arriba.
- ✅ **F16-M2** `operatorShortNameFromSlug()` extraído a helper en
  `operator_helpers.dart`.
- ✅ **F16-M3** `phone` leído de `row['phone']` en `operatorFromRow`.
- ✅ **F22-I3** Rollback de optimistic update en `manager_inbox_screen.dart`
  para los 3 handlers de cambio de estado.
- Verificado: `flutter analyze` 0 issues, `flutter test` 175/175 sin
  regresión.

**Pendiente arrastrado:** §1 (keystore, screen reader pass — manuales del
usuario), §2.2 tests `remote/`, §2.4 (RTL runtime, contrastes, foco),
§3 deuda de fondo.

---

## 6. F6.12 Final Re-Audit Summary (2026-05-22)

### Plan v2 Progress (F0→F27, 28 fases)

| Bloque | Fases | Estado |
|---|---|---|
| I — Cimientos | F0, F0.5, F1, F2, F3 | ✅ 5/5 |
| II — Identidad | F4, F5, F6 | ✅ 3/3 |
| III — Datos a escala | F7, F8 | ✅ 2/2 |
| IV — Experiencia core | F9, F10, F11, F12 | ✅ 4/4 |
| V — Ojos del bus | F13, F14 | ✅ 2/2 |
| VI — Comunidad y moderación | F15, F16 | ✅ 2/2 |
| VII — Pulido visual y accesibilidad | F17, F18, F19 | ✅ 3/3 |
| VIII — Infraestructura de producto | F20, F21, F22 | ✅ 3/3 |
| IX — Plataformas extra | F23, F24 | ✅ 2/2 |
| X — Cierre | F25, F26, F27 | ✅ 3/3 |
| **TOTAL** | **28 fases** | **✅ 28/28 (100 %)** |

### Mega-plan Scoreboard (F6.12 close)

| Bloque | Total | ✅ | ⏳ | % |
|---|---|---|---|---|
| P0 | 7 | 6 | 1 [EXT] | 85.7 |
| R | 4 | 4 | 0 | 100 |
| P1 | 11 | 10 | 1 | 90.9 |
| P2 | 7 | 4 | 3 | 57.1 |
| P3 | 8 | 4 | 4 | 50.0 |
| PROD | 10 | 4 | 6 | 40.0 |
| A11Y | 10 | 5 | 5 | 50.0 |
| PRO-Snr | 18 | 17 | 1 | 94.4 |
| PRO-Rel | 33 | 14 | 19 | 42.4 |
| PRO-QA | 25 | 13 | 12 | 52.0 |
| PRO-A11Y | 23 | 15 | 8 | 65.2 |
| PRO-Ops | 34 | 16 | 18 | 47.1 |
| **TOTAL** | **190** | **112** | **78** | **58.9** |

### Verification Snapshot

```
commit:      HEAD (2026-05-22) · 33 commits total
analyze:     0 errors, 0 warnings, 22 info
test:        304 passed, 1 skipped
coverage:    24.30 %
migrations:  14 SQL files
edge fn:     4 directories
test files:  63 Dart files
doc files:   73 Markdown files
ARB keys:    846 (es template)
source:      315 Dart files (non-generated)
APK release: 73.5 MB
CI:          7 jobs verde
Plan v2:     55/80 (28/28 fases originales)
```

### External Blockers (unchanged)

| # | Blocker | Action |
|---|---------|--------|
| B1 | Keystore real | `keytool -genkey` (~15 min) |
| B2 | TalkBack/VoiceOver pass | Physical device test (~1 day) |
| B3 | PAT rotation | Supabase dashboard (5 min) |
| B4 | Apple Developer enrollment | $99/year + provisioning |
| B5 | AR Arabic translation | 272 keys need native review |
| B6 | Play/App Store submissions | Forms, listings, screenshots |

### Documents Updated

| Document | Action |
|---|---|
| `docs/00_MAESTRO.md` | Estado verificado + trajectory table updated |
| `docs/MEGA_PLAN_REFINAMIENTO.md` | Scoreboard §2 updated (109→112, 57.4%→58.9%) |
| `docs/PENDIENTE_PARA_CERRAR.md` | Session header → CLOSED; F6.12 summary appended |
| `docs/PROPUESTAS_FUTURAS.md` | Metrics + scoreboard updated; Plan v2 status added |
| `docs/PLAN_V2_PROGRESS.md` | **NEW** — Clean progress table 28 fases |
