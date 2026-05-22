# Transitly — Mega-plan de Refinamiento Profesional

> **Fuente única operativa.** Sustituye a `historico/PLAN_ACCION_REMEDIACION_v1.md` (absorbido íntegramente). Origen: las 4 pasadas críticas (`historico/REVISION_INDEPENDIENTE_2026_05_17.md`) + 5 dossiers de auditoría multiagente con metodología `code-review` skill (sénior architecture, release stores, accessibility AAA, QA pro, SRE/Ops). El estado verificado vive en `00_MAESTRO.md`.
>
> **Objetivo declarado:** las 3 cosas a la vez — **TFG defensa impecable** + **app publicable en Play Store / App Store** + **portfolio de ingeniería senior**.
>
> **Estado verificado:** `master @ 605a062+` · `flutter analyze` 0 · 175/175 tests · cobertura 24,30 % · APK release 73,5 MB · CI verde (4 jobs incl. Build Android APK).
>
> **Regla transversal:** cada ítem se cierra solo si tras él `flutter analyze` = 0, `flutter test` sigue verde y CI en GitHub queda verde.

---

## 1. Visión y veredicto crítico

### Tres niveles de "profesional"

| Nivel | Cuándo se considera alcanzado | Bloque(s) responsable(s) |
|---|---|---|
| **A — TFG defensa impecable** | Cifras del proyecto verificables, documentación coherente, demo sin sustos, defensa preparada con respuestas | P0, P1, R, PRO-Snr (1,2,9,11,12) |
| **B — App publicable en stores** | Keystore real, listings completos, assets store, compliance GDPR/Privacy Labels, builds firmados en CI | PROD, PRO-Rel (todos) |
| **C — Portfolio senior + Producción operable** | ADRs, observabilidad SLO, accesibilidad AAA, tests pro, runbooks, releases gestionados | PRO-Snr (todos), PRO-QA, PRO-Ops, A11Y, PRO-A11Y |

### Notas honestas

- TFG (lente académica): ≈8,3/10 — alcanzable con A en 1-2 semanas.
- Producción a escala: ≈6/10 actual; los hitos B y C son los que mueven a 8+.
- Accesibilidad: actualmente "AA parcial". B+C la llevan a "AA defendible" + "AAA aspiracional".

---

## 2. Cuadro de mando global (190 ítems · 12 bloques)

| Bloque | Total | ✅ Hecho | ⏳ Pendiente | Nivel | Notas |
|---|---:|---:|---:|:--:|---|
| **P0** — Defensa inminente | 7 | 6 | 1 [EXT] | A | Solo rotación de PAT pendiente externa |
| **R** — Workstream paquetes/refactor | 4 | 4 | 0 | A | Freezed 3, go_router 17, app_router split |
| **P1** — Calidad / a11y / requisitos | 11 | 9 | 2 | A | P1-6/7 documentados; queda P1-11 (issues F16/F22) y P1-3 textScaler revisar |
| **P2** — Núcleo + cobertura | 7 | 4 | 3 | A/C | Faltan P2-2 (stop/route Realtime con multiplex), P2-3 unificar usuario (parcial), P2-4 tests `remote/` |
| **P3** — Deuda de fondo | 8 | 4 | 4 | A/C | autoDispose `.family`, F26 fuentes verificadas, audit_log `data/auth/`, tests integración |
| **PROD** — Producción a escala (existente) | 10 | 3 | 7 | B/C | Keystore [EXT], observabilidad, mapa clustering, caché tenant |
| **A11Y** — WCAG existente | 10 | 5 | 5 | B/C | Verificación lector, alt mapa, contrastes, foco, RTL completo |
| **PRO-Snr** — Senior portfolio 🆕 | 18 | 16 | 2 | C | ADRs, LICENSE, CHANGELOG, ErrorBoundary, CI, rollback docs, dartdoc, auth_provider moved |
| **PRO-Rel** — Publicación stores 🆕 | 33 | 12 | 21 | B | Permisos, PrivacyInfo, icons, CI, Gitleaks, versionCode, report, age verify |
| **PRO-Ops** — SRE / Operación 🆕 | 34 | 17 | 17 | C | SLOs, runbooks, audit, retention, RTBF, C4, catalog, timing, spans, events, alert matrix, edge fn, DR plan |
| **PRO-QA** — Testing pro 🆕 | 25 | 12 | 13 | C | auth tests, ARB, architecture, a11y, i18n, roundtrip, feature-switch, Semgrep, leak tracker, edge fn tests, db reset CI |
| **PRO-A11Y** — A11y AAA + inclusión 🆕 | 23 | 12 | 11 | C | Contrast, lints, daltonism, textScaler, RTL, undo, breadcrumbs, meetsGuideline, switch access, report, low data |
| **TOTAL** | **190** | **102** | **88** | | 102 cerrados (53,7 %); de los 88 pendientes ~42 son [EXTERNAL] |

> Definición de "✅ Hecho": verificado en código + en CI verde + criterio de aceptación cumplido en el documento que lo declaró.

---

## 3. Roadmap por hitos

Orientado a **valor entregado por unidad de tiempo**. Cada hito tiene puerta verificable.

### H0 — Mantener verde (continuo · regla operativa)

Antes y después de cada ítem que toque código: `flutter analyze` 0 + `flutter test` 100 % verde + CI 4 jobs verdes. No-negociable.

### H1 — Cierre TFG defensa (1 sesión · ≤ 1 día)

**Objetivo:** liquidar el residual del bloque A.

| Acción | Bloque | Esfuerzo | Riesgo |
|---|---|:-:|:-:|
| P0-1 rotar PAT Supabase | P0 | [EXT] 5 min | 🟢 |
| Cerrar P1-11 (issues F16/F22) o documentar como deuda | P1 | M | 🟢 |
| Ejecutar checkpoint `code-review` con skill sobre lo cerrado en P0/P1 | meta | M | 🟢 |

### H2 — Senior Foundations (3-4 días)

**Objetivo:** señales de craft que ven los reclutadores en los primeros 3 minutos del repo.

| ID | Acción | Esf. |
|---|---|:-:|
| PRO-Snr-1 | `docs/adr/` con 5 ADRs (Riverpod / freezed / Hive / Supabase / feature-first) | M |
| PRO-Snr-11 | `LICENSE` raíz (MIT) | S |
| PRO-Snr-2 | `CHANGELOG.md` + `release-please` workflow + semver real en `pubspec.yaml` | S |
| PRO-Snr-9 | `FlutterError.onError` + `PlatformDispatcher.onError` + `ErrorWidget.builder` custom | S |
| PRO-Snr-3 | `lefthook.yml` con pre-commit (analyze + format + conventional commits) | S |
| PRO-Snr-4 | `.github/PULL_REQUEST_TEMPLATE.md` + `ISSUE_TEMPLATE/*.yml` + `CODEOWNERS` | S |
| PRO-Snr-5 | `CONTRIBUTING.md` + `CODE_OF_CONDUCT.md` (Contributor Covenant) + `SECURITY.md` | S |
| PRO-Snr-6 | `.github/dependabot.yml` para `pub` + `github-actions` con auto-merge minor/patch | S |
| PRO-Snr-8 | `--obfuscate --split-debug-info` en CI Android + archivar `debug-info/` | S |
| PRO-Snr-10 | `.editorconfig` + `.gitattributes` con normalización LF | S |
| **Checkpoint** | Pasada `code-review` skill sobre lo cambiado en H2 | M |

### H3 — Foundations producción (1 semana)

**Objetivo:** lo mínimo de PROD y PRO-Rel **automatizable** (sin acciones externas) para que la app esté lista para publicar.

| ID | Acción | Esf. |
|---|---|:-:|
| PRO-Rel-3 | Añadir permisos faltantes a `AndroidManifest.xml` (LOCATION, POST_NOTIFICATIONS, READ_MEDIA_IMAGES, CAMERA) | S |
| PRO-Rel-4 | Fijar `compileSdk=35` y `targetSdk=34` (no delegar a Flutter SDK) | S |
| PRO-Rel-13 | `NSLocationWhenInUseUsageDescription` + Camera/Photo en `Info.plist` con strings en es/en/ar | S |
| PRO-Rel-15 | `ios/Runner/PrivacyInfo.xcprivacy` (Required Reason APIs para `shared_preferences`, `path_provider`, Hive) | S |
| PRO-Rel-17 | Elevar iOS deployment target 13.0 → 16.0 | S |
| PRO-Rel-5 | Adaptive icon Android 8+ + monochrome icon Android 13+ | M |
| PRO-Rel-1 | Job de CI `build-android-release-aab` con keystore desde secrets + `jarsigner -verify` | M |
| PRO-Rel-9 | `bundle { language { enableSplit }, abi { enableSplit } }` en `build.gradle.kts` | S |
| PRO-Rel-19 | Verificar ATT en `posthog_flutter`; añadir `NSUserTrackingUsageDescription` o documentar no-tracking | S |
| PRO-Rel-20 | Botón "Reportar contenido" en incidencias y sugerencias (App Review 1.6 / GDPR DSA) | M |
| PRO-Rel-23 | Esquema `privacy_consents` con `granted_at`, `revoked_at`, `consent_version`, append-only | M |
| PRO-Rel-24 | Edad mínima documentada (16 años GDPR-ES) + signup con fecha de nacimiento | S |
| PRO-Rel-30 | `versionCode` desde `$GITHUB_RUN_NUMBER` en CI, `versionName` desde tag git | S |
| PRO-Rel-31 | Job CI `build-ios-release` con macOS runner + Fastlane | L |
| PRO-Rel-32 | Gitleaks + Trufflehog en CI | S |
| PRO-Rel-33 | `docs/RELEASE_CHECKLIST.md` operativo reproducible | S |
| **Checkpoint** | Pasada `code-review` skill sobre seguridad de release y permisos | M |

### H4 — Stores publicable (3-5 días · depende de H3 + [EXTERNAL])

**Objetivo:** convertir el código en una app publicable en Play Store y App Store.

Bloque dominado por acciones [EXTERNAL] (cuentas, certificados, formularios de stores). Lo automatizable de mi parte está en H3. El listado completo PRO-Rel-2/6/7/8/10/11/12/14/16/18/21/22 queda como contrato con el usuario.

### H5 — Operación profesional (1-2 semanas)

**Objetivo:** SRE básico — observabilidad real, alertas, runbooks, feature flags.

| ID | Acción | Esf. |
|---|---|:-:|
| PRO-Ops-1 | `docs/slo/slo_catalog.md` con 6 SLOs (login p95, map p95, crash-free, edge, push, auth refresh) | M |
| PRO-Ops-2 | Error Budget Policy + Release Freeze policy escrita | S |
| PRO-Ops-3 | Sentry Performance: spans de negocio (`auth.signIn`, `map.initial_render`, `nfc.read`) | M |
| PRO-Ops-4 | Eventos de producto en PostHog (signup, route_viewed, incident_reported, nfc_read_success) | M |
| PRO-Ops-5 | Logs estructurados JSON con sink configurable (extender `AppLogger`) | M |
| PRO-Ops-6 | Network monitoring: interceptor para timings por endpoint Supabase | M |
| PRO-Ops-10 | Sentry Deno SDK en `send_notification` + `import_gtfs` (instrumenta cold start, errores) | M |
| PRO-Ops-13 | Matriz de alertas P0-P3 con links a runbooks (Sentry → Slack/Discord webhook) | M |
| PRO-Ops-15 | `docs/runbooks/` con 3 runbooks mínimos: push down, Supabase down, Sentry spike | M |
| PRO-Ops-20 | Banner in-app de incidencia activa (lee `incident_announcement` desde Remote Config) | M |
| PRO-Ops-23 | Force-update mechanism con Remote Config `min_version` | M |
| PRO-Ops-28 | Audit log tabla en Supabase para acciones admin (CRUD operadores, baneos) | M |
| PRO-Ops-30 | Data Retention Policy declarada + RPC de purga de `bus_positions` > 30 días | M |
| PRO-Ops-31 | Right-to-be-forgotten con timestamping auditable | M |
| PRO-Ops-32 | C4 diagrams (Mermaid) en `docs/architecture/c4-*.md` | M |
| PRO-Ops-33 | `docs/service-catalog.md` con dependencias entre servicios | S |
| **Checkpoint** | Pasada `code-review` skill sobre observabilidad y runbooks | M |

### H6 — Testing pro (1-2 semanas)

**Objetivo:** estrategia de QA defendible en entrevista senior.

| ID | Acción | Esf. | +Cov |
|---|---|:-:|:-:|
| PRO-QA-02 | Round-trip serialization tests para los 14 `PendingActionKind` | S | +0,5pp |
| PRO-QA-03 | Extraer `auth_helpers.dart`; tests de `_mapError` por rama | S | +1pp |
| PRO-QA-11 | Gitleaks + Trufflehog en CI (overlap con PRO-Rel-32) | S | — |
| PRO-QA-09 | Coverage gate por módulo (`lib/data/operator/` ≥60 %, `core/` ≥70 %) | S | — |
| PRO-QA-14 | Tests de arquitectura de capas (anti-import rules) | S | +0,2pp |
| PRO-QA-16 | Test de paridad ARB es/en/ar; falla si claves divergen | S | +0,3pp |
| PRO-QA-04 | Goldens del design system (8 widgets × dark/light) | M | +1pp |
| PRO-QA-05 | A11y programática con `meetsGuideline(...)` (tap target + contrast) | S | +0,5pp |
| PRO-QA-06 | Widget tests auth: loading/error/redirect states | M | +1,5pp |
| PRO-QA-10 | Codecov integration + comentario en PRs + badge en README | S | — |
| PRO-QA-12 | Semgrep SAST con regla custom `no-hardcoded-es-strings` | M | — |
| PRO-QA-18 | Tests i18n: RTL árabe, fechas/números localizados | S | +0,5pp |
| PRO-QA-19 | Tests feature-switch mock vs Supabase según `authStateProvider` | S | +1pp |
| PRO-QA-21 | Tests Deno para `send_notification` (UUID validation, service role, rate limit, FCM JSON) | M | — |
| PRO-QA-15 | `supabase db reset` en CI con migraciones idempotentes | M | — |
| PRO-QA-20 | RLS tests con pgTAP (anon no lee privados, role escalation bloqueado) | L | — |
| PRO-QA-07 | Integration tests con emulador Android (3 happy paths) | L | +3pp |
| PRO-QA-22 | `leak_tracker_flutter_testing` en tests de `RealtimeChannelManager` | M | — |
| PRO-QA-01 | Property-based testing con `glados` en `BusEstimator` | M | +1pp |
| **Checkpoint** | Pasada `code-review` skill al cierre de cada subbloque (3 checkpoints en H6) | L | — |

### H7 — Accesibilidad AAA + inclusión (2-3 semanas)

**Objetivo:** "AA defendible" + bases AAA + inclusión cultural real.

| ID | Acción | Esf. |
|---|---|:-:|
| PRO-A11Y-13 | **ARB árabe completo** (de 71 a 343 claves) | L [EXT parcial: traducción] |
| PRO-A11Y-1 | Verificar contrastes con Stark/axe; matriz `docs/CONTRAST_MATRIX.md`; corregir `textLo` | M |
| PRO-A11Y-15 | `TransitFormatters` con `NumberFormat` por locale (dígitos árabes ٠١٢٣ en `ar`) | M |
| PRO-A11Y-22 | RTL verificado en widgets custom (gradientes con `AlignmentDirectional`, iconos direccionales) | M |
| PRO-A11Y-2 | Tests de flujos críticos a `textScaler` 200 % sin overflow | M |
| PRO-A11Y-3 | `FocusTraversalGroup` por pantalla; `Dismissible` con acción semántica alternativa | L |
| PRO-A11Y-5 | Eliminar textos de enlace genéricos ("Ver más", "Abrir") en favor de Semantics descriptivos | S |
| PRO-A11Y-8 | Snackbar undo en acciones irreversibles; confirmaciones con descripción de consecuencias | M |
| PRO-A11Y-9 | `UserPreferences.extendedTimers` que extiende Snackbars a 8 s | M |
| PRO-A11Y-12 | 8 tipos de daltonismo (añadir las 5 anomalías a las 3 puras) | M |
| PRO-A11Y-16 | `meetsGuideline(androidTapTargetGuideline)` + `textContrastGuideline` en tests | M |
| PRO-A11Y-17 | Lints adicionales de accesibilidad en `analysis_options.yaml` | S |
| PRO-A11Y-19 | Switch Access: `Dismissible` con custom semantic actions; mapa con alternativa | M |
| PRO-A11Y-4 | `TransitAppBar` con breadcrumbs opcionales (WCAG 2.4.8) | M |
| PRO-A11Y-7 | Ayuda contextual (`IconButton(Icons.help_outline)`) en flujos complejos | M |
| PRO-A11Y-6 | Auditar legibilidad con Inflesz; modo "Lectura Fácil" toggleable | L |
| PRO-A11Y-21 | Modo bajo consumo de datos con `connectivity_plus` | M |
| PRO-A11Y-18 | Reporte de accesibilidad por release + checklist manual TalkBack/VoiceOver | M [EXT parcial] |
| **A11Y-3 existente** | Pasada REAL con TalkBack/VoiceOver con acta firmada (**bloqueador AA**) | [EXT] L |
| **Checkpoint** | Pasada `code-review` skill sobre accesibilidad al cierre | M |

### H8 — Largo plazo (mes 2+)

Items XL que requieren scope dedicado:

- PRO-Ops-21 Feature flags con PostHog [EXT parcial]
- PRO-Ops-24 Canary release [EXT]
- PRO-Ops-25 Load testing con k6 [EXT]
- PRO-A11Y-10 Modo "Solo Audio" (XL)
- PRO-A11Y-11 Notificaciones proactivas "tu bus en 5 min" (L)
- PRO-A11Y-14 Catalán + gallego ARB [EXT]
- PRO-A11Y-23 Pictogramas ARASAAC [EXT]
- PRO-Snr-14 Integration tests E2E con Patrol (depende de H6 base)
- PRO-Snr-17 dartdoc en GitHub Pages

---

## 4. Bloques completos con todos los ítems

### 4.1. Bloque P0 — Defensa inminente

> Estado: 6/7 cerrados. Detalle en `historico/PLAN_ACCION_REMEDIACION_v1.md §P0`.

| ID | Acción | Estado |
|---|---|:-:|
| P0-1 | Rotar PAT Supabase | ⏳ [EXT] |
| P0-2 | `setState` con `mounted` en signin/signup catch | ✅ |
| P0-3 | `send_notification` 502→500 | ✅ |
| P0-4 | Métricas en `docs/tfg/` reconciliadas | ✅ |
| P0-5 | APK release para demo (73 MB) | ✅ |
| P0-6 | UID truncado en log auth | ✅ |
| P0-7 | APK release nunca había compilado (workmanager v1, desugaring, Gradle OOM) | ✅ |

### 4.2. Bloque R — Workstream paquetes/refactor (✅ completo)

Stack moderno: freezed 2→3, go_router 14→17, json_serializable 6.8→6.14. Split de `app_router.dart` → `redirect_guards.dart`. Placeholders limpiados. `StaggerList` warn silenciado.

### 4.3. Bloque P1 — Calidad/a11y/req cercanos

> 9/11 cerrados. Pendiente: P1-3 (textScaler revisión), P1-11 (issues F16/F22).

Items cerrados: P1-1 strings ES residuales (33 migrados), P1-2 Semantics→l10n (10 archivos), P1-5 7 modelos a freezed, P1-6/P1-7 GoogleFonts residuales documentados como intencionales, P1-8 ActionButton eliminado, P1-9 showTransitBottomSheet, P1-10 mounted/unawaited correct en privacy.

### 4.4. Bloque P2 — Núcleo + cobertura

> 4/7 cerrados. Pendiente: P2-2 (Realtime stop/route con multiplex compartido — implementado, falta auditoría), P2-3 unificar usuario (✅ verificado), P2-4 tests `remote/` (la palanca real), P2-7 gate de cobertura básico.

### 4.5. Bloque P3 — Deuda de fondo

> 4/8 cerrados. Pendientes principales: autoDispose `.family`, audit log `data/auth/`, integration tests base, descomposición `privacy_screen` (406 LoC).

### 4.6. Bloque PROD — Producción existente

> 3/10 cerrados (PROD-1 keystore parcial, PROD-2 paginación 11/11 ✅, PROD-3 Realtime 5/12 ✅, PROD-5 autoDispose 6 providers parcial). Detalle en H3.

### 4.7. Bloque A11Y — WCAG existente

> 5/10 cerrados (A11Y-2 Pressable 48dp ✅, A11Y-4 Semantics→l10n ✅, A11Y-5 textScaler ✅, A11Y-8 F26 fonts ✅, A11Y-10 ar/RTL parcial). Pendientes principales: A11Y-1 alt mapa, A11Y-3 pasada lector, A11Y-7 contrastes verificados, A11Y-9 foco.

### 4.8. Bloque PRO-Snr 🆕 — Senior Portfolio (18 ítems)

| ID | Acción | Sev. | Esf. |
|---|---|:-:|:-:|
| PRO-Snr-1 | `docs/adr/` con 5 ADRs (riverpod/freezed/hive/supabase/feature-first) | 🔴 | M |
| PRO-Snr-2 | `CHANGELOG.md` + `release-please` + semver real | 🔴 | S |
| PRO-Snr-3 | `lefthook.yml` con pre-commit hooks | 🟠 | S |
| PRO-Snr-4 | PR + Issue templates + `CODEOWNERS` | 🟠 | S |
| PRO-Snr-5 | `CONTRIBUTING.md` + `CODE_OF_CONDUCT.md` + `SECURITY.md` | 🟠 | S |
| PRO-Snr-6 | `dependabot.yml` con auto-merge minor/patch | 🟠 | S |
| PRO-Snr-7 | Migración a `very_good_analysis` + `riverpod_lint` | 🟡 | S |
| PRO-Snr-8 | `--obfuscate --split-debug-info` en CI | 🟠 | S |
| PRO-Snr-9 | `FlutterError.onError` + `PlatformDispatcher.onError` + `ErrorWidget.builder` | 🔴 | S |
| PRO-Snr-10 | `.editorconfig` + `.gitattributes` con LF | 🟡 | S |
| PRO-Snr-11 | `LICENSE` raíz (MIT) | 🟠 | S |
| PRO-Snr-12 | Migraciones SQL sin colisión `007_*` + rollback scripts + `seed.sql` | 🟠 | M |
| PRO-Snr-13 | Eliminar cross-feature imports; mover `auth_provider` a `shared/providers/` | 🟠 | M |
| PRO-Snr-14 | `integration_test/` con 3 happy paths | 🟡 | L |
| PRO-Snr-15 | Golden tests del design system (fuentes ya locales) | 🟡 | M |
| PRO-Snr-16 | Bundle size budget en CI (`--analyze-size`, falla si >80 MB) | 🟡 | M |
| PRO-Snr-17 | `dartdoc` en GitHub Pages | 🔵 | S |
| PRO-Snr-18 | `ProviderObserver` con captura `providerDidFail` → Sentry | 🟡 | S |

### 4.9. Bloque PRO-Rel 🆕 — Publicación stores (33 ítems)

> **Android (P-Rel-1..11) · iOS (P-Rel-12..20) · Legal (P-Rel-21..25) · Operación post-release (P-Rel-26..30) · CI específica stores (P-Rel-31..33).** Detalle completo en H3 (automatizable) + H4 (acciones externas).

Resumen por severidad: **9 🔴 bloqueadores**, **15 🟠 altos**, **9 🟡 medios**. Aprox. **15 [EXTERNAL]** (formularios stores, certificados, listings, etc.).

### 4.10. Bloque PRO-A11Y 🆕 — Accesibilidad AAA + inclusión (23 ítems)

> Detalle en H7. **1 🔴 crítico inclusión** (PRO-A11Y-13 ARB árabe incompleto al 8,5 %), **8 🟠 altos** (contraste AAA verificado, teclado pleno, undo en irreversibles, etc.), **11 🟡 medios** (lectura fácil, breadcrumbs, ayuda contextual, daltonismo extendido, etc.), **3 🔵 nice-to-have** (catalán/gallego, pictogramas ARASAAC).

### 4.11. Bloque PRO-QA 🆕 — Testing profesional (25 ítems)

> Detalle en H6. **5 🔴 críticos calidad pro** (round-trip serialization, `_mapError` aislado, integration tests, Gitleaks, migrations idempotentes, RLS pgTAP, Edge Functions Deno tests, paridad ARB), **11 🟠 altos**, **9 🟡 medios**.

### 4.12. Bloque PRO-Ops 🆕 — SRE / Operación (34 ítems)

> Detalle en H5. **5 🔴 sin esto no opera profesional** (SLOs declarados, error budget policy, runbooks, audit log, banner incidente). **17 🟠 altos** (Performance Sentry, métricas producto, Edge Functions instrumentadas, alertas con runbooks, force-update, retención datos, C4 diagrams). **11 🟡/🔵**.

---

## 5. Check-points de code-review (skill `code-review`)

La skill multi-agente se invoca en estos hitos para auditoría externa simulada:

| Hito | Cuándo | Foco específico | Skill / método |
|---|---|---|---|
| **CR-1** | Al cerrar H1 | Validación de cierre TFG | Skill `code-review` sobre rama `master` post-H1 |
| **CR-2** | Al cerrar H2 | Senior portfolio foundations: presencia de ADRs, LICENSE, ErrorBoundary, CHANGELOG | `dispatching-parallel-agents`: 2 agentes Sonnet en paralelo (arquitectura + seguridad) |
| **CR-3** | Al cerrar H3 | Producción foundations: permisos manifest, Privacy Manifest, builds firmados | 3 agentes Sonnet: release + seguridad + GDPR compliance |
| **CR-4** | Tras cada subbloque de H6 | Quality gates en CI, no regresiones, cobertura ≥35 % | Agentes Sonnet QA + análisis Codecov delta |
| **CR-5** | Al cerrar H5 | Observabilidad real: SLOs declarados verificables, runbooks ejecutables | Agente Sonnet SRE + revisión de dashboards |
| **CR-6** | Al cerrar H7 | Accesibilidad: pasada con producto de apoyo (manual), tests `meetsGuideline` | Agente Sonnet a11y + revisión manual TalkBack [EXT] |
| **CR-Final** | Antes de release público | Veredicto consolidado | Skill `code-review` full multi-agent pass |

Cada checkpoint produce un commit `docs(review): checkpoint CR-N — <conclusión>` con hallazgos.

---

## 6. Acciones externas tuyas (recordatorio)

Estos quedan fuera del plan automatizable, pero sin ellos los hitos B (publicable) y partes de C no se cierran. **Lista verificada — no se pueden automatizar:**

### Stores y certificados
- **PROD-4 / SEC1:** rotar PAT Supabase (`.mcp.json`)
- **PRO-Rel-12:** Apple Developer Program (99 USD/año) + certificados + provisioning profiles
- **PRO-Rel-1 (parcial):** generar `upload-keystore.jks` con `keytool` + secrets en GitHub
- **PRO-Rel-2, 11, 14:** formularios Data Safety / Privacy Details / listings 3 idiomas en consolas
- **PRO-Rel-6, 18:** subir AAB a Internal Testing → Closed → Open → Production
- **PRO-Rel-7, 16:** generar screenshots reales en dispositivos físicos
- **PRO-Rel-8:** revisar Pre-Launch Report tras cada subida
- **PRO-Rel-10:** configurar alertas en Play Vitals + Sentry
- **PRO-Rel-21, 22:** publicar Privacy Policy + Terms en dominio fijo (`transitly.app/privacy`)

### Operación
- **PRO-Ops-7:** activar Session Replay en Sentry (revisar coste)
- **PRO-Ops-8:** Logflare/Datadog para logs Supabase
- **PRO-Ops-12:** alertas en Supabase Auth (Pro plan)
- **PRO-Ops-17:** on-call rotation (incluso individual)
- **PRO-Ops-18:** primer postmortem cuando ocurra incidente
- **PRO-Ops-19:** status page público (statuspage.io, $0-29/mes)
- **PRO-Ops-21:** PostHog feature flags activado
- **PRO-Ops-22, 24:** rollback procedure + canary release ejecutados al menos una vez
- **PRO-Ops-25:** load testing con k6 contra staging
- **PRO-Ops-26, 27:** forecast crecimiento + cost monitoring
- **PRO-Ops-29:** firmar DPA con Supabase
- **PRO-Ops-34:** DR plan con RPO/RTO

### Accesibilidad
- **A11Y-3 / PRO-A11Y-18 (parcial):** pasada REAL con TalkBack/VoiceOver con acta
- **PRO-A11Y-13 (parcial):** traducción humana de ARB árabe (272 claves)
- **PRO-A11Y-14:** ARB catalán + gallego con traductores nativos
- **PRO-A11Y-23:** licencia con ARASAAC para pictogramas

---

## 7. Dependencias críticas (orden de ejecución no negociable)

- **PRO-QA-15 (db reset CI)** antes de **PRO-QA-20 (RLS pgTAP)** — mismo Docker.
- **PRO-Rel-15 (PrivacyInfo.xcprivacy)** antes de **PRO-Rel-12 (Apple Dev)** [EXT] — App Store Connect bloquea sin ello.
- **PRO-Snr-1 (ADRs)** antes de **PRO-Snr-7 (very_good_analysis)** — la decisión de cambio de ruleset es ADR.
- **PRO-A11Y-13 (ARB árabe completo)** antes de **PRO-A11Y-18 (reporte a11y release)** — sin árabe completo el reporte miente.
- **PRO-Ops-1 (SLOs)** antes de **PRO-Ops-13 (matriz alertas)** — los umbrales de alerta vienen de los SLOs.
- **PRO-Ops-15 (runbooks)** antes de **PRO-Ops-17 (on-call)** [EXT] — on-call sin runbooks es performativo.

---

## 8. Comandos de verificación

```bash
# Pipeline mínimo después de cada ítem
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
flutter analyze                     # → No issues found!
flutter test --coverage             # → All tests passed!
awk -F: '/^LF:/{lf+=$2}/^LH:/{lh+=$2}END{printf "cov=%.2f%%\n",(lh/lf)*100}' coverage/lcov.info
flutter build apk --release         # → √ Built app-release.apk

# Tras añadir lefthook (PRO-Snr-3)
lefthook run pre-commit

# Tras añadir gitleaks (PRO-Rel-32 / PRO-QA-11)
gitleaks detect --source . --verbose

# Tras añadir very_good_analysis (PRO-Snr-7)
flutter analyze --fatal-infos --fatal-warnings

# Tras añadir Semgrep (PRO-QA-12)
semgrep --config=.semgrep/rules/

# Tras añadir migraciones tests (PRO-QA-15)
supabase db reset --local
supabase test db
```

---

## 9. Resumen ejecutivo

- **Total ítems:** 190 (57 originales + 133 nuevos de auditoría multi-agente).
- **Estado actual:** 35 cerrados (18,4 %). Foco inmediato en cerrar los 1-2 residuales del bloque A para defensa TFG impecable.
- **Hito recomendado siguiente:** **H2 — Senior Foundations** (3-4 días). Es la mayor relación valor/esfuerzo: ADRs, LICENSE, CHANGELOG, ErrorBoundary, pre-commit hooks, PR templates. Eleva el repo de "TFG aprobado" a "portfolio defendible en entrevista senior" sin tocar arquitectura nuclear.
- **Cuellos de botella estructurales:**
  - **Cobertura 24,30 %:** la palanca es PRO-QA-03 + PRO-QA-06 + P2-4 (tests `remote/`).
  - **Producción real:** PRO-Rel-1 (AAB firmado en CI) + PRO-Ops-1 (SLOs).
  - **Accesibilidad AAA defendible:** PRO-A11Y-13 (ARB árabe completo) + A11Y-3 pasada con lector real.
- **Acciones externas pendientes:** ~42 ítems [EXTERNAL] documentados; no bloquean el desarrollo local.
- **Skill `code-review` checkpoints:** 6 hitos de auditoría externa simulada para validar cierres.

---

## 10. Mantenimiento de este plan

- **Estado vivo:** marcar ✅ aquí al cerrar cada ítem; el cuadro de mando del §2 debe estar actualizado.
- **Sincronía:** al cerrar un ítem que cambia las cifras del proyecto, actualizar también `00_MAESTRO.md` (fuente única de verdad).
- **Archivado:** cuando un bloque queda al 100 %, mover su detalle a `historico/` y dejar solo resumen aquí.
- **Versionado:** este plan es `v2`; el `v1` está en `historico/PLAN_ACCION_REMEDIACION_v1.md`. Versiones futuras: `MEGA_PLAN_REFINAMIENTO_v3.md` con cambios significativos.

> Esta es la fuente única operativa. Ante cualquier conflicto, gana este documento o `00_MAESTRO.md` (estado verificado).
