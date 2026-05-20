# 04 — Desarrollo e Implementación

**Proyecto:** Transitly
**Estado verificado:** `master @ 3a31fb3` · 28/28 fases · 175/175 tests · cobertura 24,30 % · `flutter analyze` 0 issues · APK release 73,5 MB · CI verde (4 jobs)

---

## 1. Metodología de desarrollo

### 1.1. Modelo

**Desarrollo ágil iterativo por fases atómicas de 1-4 días.** Cada fase
tiene un objetivo único, una rama de trabajo en `master` directa
(sin ramas de feature) y un cierre formal verificable.

- **Sin Scrum / Kanban formales** — la naturaleza individual del TFG no
  lo requiere; el rol de Product Owner lo cubre el plan de
  `PLAN_TRANSITLY_V2.md` (ahora archivado tras cierre F27).
- **Tracker de tareas:** `multiagent/state/queue.json` (cola viva durante
  cada sesión) + `docs/PENDIENTES.md` (deuda con tags por fase) +
  `docs/PLAN_ACCION_REMEDIACION.md` (plan vivo de remediación
  post-cierre).
- **Sesiones presenciales** con el tutor: seguimiento de progreso y
  validación de avances; revisiones críticas independientes
  documentadas en `docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md`
  (4 pasadas críticas).

### 1.2. Asistencia de IA documentada

Trabajo asistido por un **sistema multiagente** documentado en
`multiagent/ARCHITECTURE.md` con 5 roles bien delimitados:

- **Queen** — planificación de fases y coordinación.
- **Developer** — escritura de código y tests.
- **Review** — análisis crítico, revisiones por pares simuladas.
- **Git** — commits semánticos y push.
- **Documentation** — sincronía de `tfg/` y plan.

La declaración explícita de esta asistencia es un compromiso de
**integridad académica**: el TFG se evalúa por el rigor del proyecto y
las decisiones tomadas, no por la negación de herramientas. Cada commit
queda firmado y trazable.

### 1.3. Control de versiones

- **Git + GitHub.** Repositorio privado del TFG.
- **Conventional Commits** (`feat:`, `fix:`, `docs:`, `refactor:`,
  `chore:`). Mensajes en imperativo.
- **Sin ramas de feature** — todo sobre `master`; los conflictos no
  existen en proyecto individual.
- **CI obligatoria verde** en cada push (4 jobs: Analyze, Test, Build
  Web, Build Android APK).
- **Pre-commit local:** `flutter analyze` 0 + `flutter test` 100 %
  manualmente antes de cada commit.

### 1.4. Calidad y arquitectura como reglas operativas

Reglas no negociables del proyecto (recogidas en `AGENTS.md`):

1. **`data/` no depende de `features/`**.
2. **Design tokens en `core/theme/` se consumen, nunca se duplican**.
3. **Patrón de errores tipado** (`enum FooError` + `class
   FooException`); nada de `catch (_) {}` silencioso.
4. **`avoid_print: true`** en `lib/` (solo `AppLogger`).
5. **`strict-casts: true` + `strict-raw-types: true`** en
   `analysis_options.yaml`.
6. **Modelos críticos en `@freezed`** con `.freezed.dart` commiteados.
7. **`shared/widgets/` solo si se usa en ≥2 features**.
8. **Cada `*_screen.dart` ≤ ~300 LoC** → descomponer en `widgets/` si
   crece.

---

## 2. Estructura del código

### 2.1. Capas

```
lib/
├── main.dart           Bootstrap secuencial
├── app.dart            MaterialApp.router + theme + locale
├── core/               Núcleo (router, theme, utils)
├── data/               Repositorios + caché + sync (más profunda)
├── features/           Feature-first (≈25 features)
├── l10n/               ARB + generated (es/en/ar)
└── shared/             Models + providers + widgets reusables
```

Detalle en `docs/ARCHITECTURE.md`.

### 2.2. Patrón canónico de repositorio

Cada entidad de dominio sigue el patrón de 5 ficheros:

```
lib/data/<entity>/
├── domain/<entity>_repository.dart       (interfaz abstracta)
├── remote/<entity>_remote_repository.dart (Supabase)
├── local/<entity>_local_repository.dart   (Hive)
├── local/<entity>_mock_repository.dart    (modo guest)
└── <entity>_repository_provider.dart      (Riverpod SWR + selector)
```

**Excepción documentada** (`AGENTS.md §259-265`): `lib/data/auth/` solo
tiene 2 ficheros (`auth_repository.dart` abstracto +
`auth_repository_supabase.dart`) porque la sesión la gestiona el SDK
de Supabase; no necesita local/mock/provider (el provider vive en
`features/auth/auth_provider.dart`).

### 2.3. Cifras del código (por capa)

Aproximaciones medibles a fecha de cierre F27:

| Capa | Ficheros `.dart` (excluyendo generados) | Comentario |
|------|:-:|------------|
| `lib/core/` | ~15 | Tokens, router, utils |
| `lib/data/` | ~75 | 12 entidades × 5 ficheros = 60 + sync, mock, cache, auth (excepción) |
| `lib/features/` | ~120 | ~25 features, cada una con 1-5 ficheros |
| `lib/shared/` | ~50 | 27+ modelos + ~25 providers + ~30 widgets compartidos |
| `lib/l10n/` | 4 ARB + 4 generated | 343 claves por locale |
| **Total** | ~260 ficheros .dart | ~35.000 LOC |

---

## 3. Integraciones técnicas

### 3.1. Backend Supabase

- **PostgreSQL + PostGIS** para datos geoespaciales (paradas, rutas).
- **13 migraciones SQL** versionadas en `supabase/migrations/`.
- **RLS default-deny** activo en todas las tablas con datos personales.
- **`SECURITY DEFINER`** con `search_path` fijado en todas las funciones
  (`002_rls.sql:18`).
- **2 Edge Functions** en Deno (`import_gtfs`, `send_notification`):
  - `import_gtfs` con anti-SSRF (resolución DNS A/AAAA,
    `redirect:"manual"`, rangos privados bloqueados), validación de rol
    admin + parser GTFS streaming.
  - `send_notification` con validación de invocador (`service_role` en
    tiempo constante), rate-limit best-effort (TOCTOU documentado),
    fail-closed si el INSERT en `notifications` falla, OAuth JWT para
    FCM HTTP v1.

### 3.2. F13 Realtime (5/12 repos)

- **`RealtimeChannelManager`** compartido en `lib/data/sync/` —
  multiplexa canales con `Supabase.channel().onPostgresChanges()`,
  reconexión con backoff exponencial + jitter, dispose limpio
  via `ref.onDispose`.
- Usado por: `stop`, `route`, `incident`, `route_feedback`.
- **`BusPositionChannelManager`** dedicado para `bus_location` (filtro
  por `route_id` específico).
- `notification_stream_provider` tiene Realtime propio para el feed de
  notificaciones del usuario actual (`autoDispose` para cerrar canal al
  detach).

### 3.3. Auth + roles

- `AuthRepositorySupabase` con email/password, magic link y resend.
- **Modelo de usuario unificado:** `userProfileFromSupabaseProvider`
  lee `profiles.role` de Supabase con `.maybeSingle()` y maneja
  `PostgrestException`; `currentUserProvider` usa el perfil real si
  hay sesión, mock si guest.
- **Guard del router** (`redirect_guards.dart:31`) consume el rol
  REAL de Supabase, no un `StateProvider` mutable.

### 3.4. NFC

- `NfcCardService` lee tarjeta Mifare Classic con claves
  reverse-engineered del Consorcio de Transportes de Andalucía
  (uso académico).
- Override por build: `--dart-define=NFC_KEY_SECTOR0=…
  --dart-define=NFC_KEY_SECTOR9=…`.
- i18n de errores en `nfc_l10n.dart`.

### 3.5. Mapa + offline

- `flutter_map 7.0` con `MapTiler` (con clave) + fallback CartoDB.
- `flutter_map_tile_caching 10.0` (FMTC) para tiles offline por región.
- Descarga gestionada en `features/offline/`.

### 3.6. Push (FCM)

- `firebase_messaging 16.2` para tokens y mensajes en foreground.
- `flutter_local_notifications 20.1` para presentación local.
- Edge Function `send_notification` envía vía FCM HTTP v1 con OAuth JWT
  RS256 firmado en Deno.

### 3.7. Telemetría con consent-gating GDPR

- **PostHog** arranca con `optOut=true` en `main.dart`;
  `analyticsServiceProvider` es default-deny (solo se construye con
  consentimiento explícito).
- **Sentry** no se inicializa para invitados; lee consent antes de
  arrancar; falla a opt-out si la lectura falla.
- **Revocación en caliente:** `privacy_screen._setConsent` llama
  `Posthog().disable()` / `SentrySetup.close()` y hace
  `ref.invalidate(privacyConsentsProvider)` para que el provider
  reconstruya como `NoopAnalyticsService`.

### 3.8. Astro Web (marketing)

- `astro/` con sitio SSR de ~10 páginas (landing, sobre, ciudades,
  rutas, privacidad, términos).
- Independiente del build de Flutter Web; rutas separadas
  (`/app/admin`, `/app/editor`, `/app/map` apuntan a Flutter como
  islands futuros).

### 3.9. Widgets nativos (home screen)

- `home_widget 0.7` integra widgets en pantalla de inicio de Android e
  iOS.
- `WidgetDataWriter` persiste en `SharedPreferences`.
- Refresco periódico desde la app (workmanager fue eliminado por
  incompatibilidad v1-embedding; refresco automático queda como
  trabajo futuro).

---

## 4. Pruebas

### 4.1. Suite actual

| Categoría | Tests | Foco |
|-----------|:-:|------|
| `data/operator/` | 8 | CRUD, helpers, error mapping de Postgrest |
| `data/incident/`, `data/route_feedback/` | 8 | Repositorios mock + helpers |
| `data/mock/` | 8 | MockDataService, MockRealtimeService, parser robusto |
| `data/nfc/` | 4 | NFC card service (parser, errores) |
| **`data/sync/`** | 5 | **`RealtimeChannelManager` con `fake_async`** |
| `shared/models/` | 12 | Serialización freezed |
| `shared/providers/` | 30+ | Theme, user, NFC, local feedback, derivados, schedule |
| `features/admin/` | 13 | Admin users + operator CRUD + manager inbox |
| `features/auth/` | 5 | Pantallas signin / signup / magic link / activate driver |
| `features/bus_estimation/` | 6 | Estimación pura con tiempos fijos |
| `features/driver/route_editor/` | 4 | RecordedSession y validaciones |
| `widgets compartidos` | 15 | Design system, GlassCard, TransitAppBar |
| `router` | 8 | Deeplinks, shell branches, redirect guards |
| `widget/accessibility` | 5 | Settings screen + semantics |
| `widget/home_tabs` | 12 | Tabs, perfil, card |
| `smoke` | 5 | Offline queue, app boot |
| **Total** | **175** | Verificado `master @ 3a31fb3` |

### 4.2. Cobertura

`flutter test --coverage` produce `coverage/lcov.info` con:

- **24,30 %** de líneas cubiertas (4 004 / 16 476).
- **Lever principal:** la capa `lib/data/*/remote/*` (Supabase) está a
  casi 0 % — son los repositorios que se prueban con mocks. Tests con
  `SupabaseClient` mockeado son el siguiente paso (P2-4 en el plan
  vivo).

### 4.3. CI

GitHub Actions con 4 jobs ejecutados en cada push y PR a `master`:

1. **Flutter Analyze** — `flutter analyze` (debe ser 0 issues).
2. **Flutter Test** — `flutter test --coverage` + upload de `lcov.info`
   como artifact.
3. **Build Web (release)** — `flutter build web --release`.
4. **Build Android APK** — `flutter build apk --release` con keystore
   provisionado desde secrets (cuando se configure).

Configuración en `.github/workflows/ci.yml`. CI verde verificado.

### 4.4. Decisiones de testing

- **No pixel goldens** — `google_fonts` resolvía por red al principio;
  ahora con fuentes locales sería viable, pero la decisión de no
  introducirlos se mantiene para no añadir ruido a los tests visuales.
- **`disableAnimations: true`** por defecto en `pumpApp` para evitar
  futures pendientes de animaciones.
- **`fake_async`** en tests de lógica con tiempos
  (`RealtimeChannelManager`, `bus_estimator`).
- **`mocktail`** para mocks limpios sin generación de código.

---

## 5. Documentación del código

### 5.1. AppLogger

Wrapper en `lib/core/utils/app_logger.dart` con 4 niveles (`debug`,
`info`, `warn`, `error`) y formato consistente
`[Tag] mensaje (key=value)`. Reglas:

- **No PII en logs** (UUID truncado a 8 chars en auth, sin email,
  sin lat/lng exactos).
- Tags por capa (`[NfcCardService]`, `[Provider:Theme]`, `[Router]`).
- **No `print()`** en `lib/` (lint `avoid_print` activo).

### 5.2. Codegen

- `freezed_annotation 3.x` + `json_annotation 4.14` para modelos.
- `tool/build.sh` ejecuta `dart run build_runner build
  --delete-conflicting-outputs`.
- `tool/build_watch.sh` para sesiones largas de edición de modelos.
- Los `.freezed.dart` y `.g.dart` **se commitean**.

### 5.3. Comentarios en código

- **Por defecto, sin comentarios.** Los identificadores explican qué.
- Solo se comenta el **porqué** no obvio: invariantes ocultos, *workarounds*
  con referencia al bug, decisiones contraintuitivas
  (p.ej. `bus_position_channel_manager.dart` con backoff jitter).

### 5.4. Manuales

- `docs/tfg/06_manual_tecnico.md` — instalación, configuración,
  mantenimiento.
- `docs/tfg/07_manual_usuario.md` — uso del producto.
- `docs/ARCHITECTURE.md` — reglas de arquitectura.
- `docs/PLATFORM_SETUP.md`, `docs/FCM_SETUP.md`, `docs/FONTS_F26.md`,
  `docs/HOME_WIDGETS.md`, `docs/WEB_SETUP.md`,
  `docs/SECURITY_PAT_ROTATION.md`, `android/README.md` — guías técnicas
  específicas.

---

## 6. Iteraciones y remediación post-cierre (Workstream R)

Tras el cierre formal F27 (2026-05-15) entraron varios **ciclos de
remediación** descubiertos en revisiones críticas independientes
(`docs/historico/REVISION_INDEPENDIENTE_2026_05_17.md`,
`docs/historico/REVISION_CRITICA.md`). Sin estos ciclos, el proyecto
"funcionaba" pero ocultaba deuda importante. Lo cerrado en esos ciclos
(con verificación) está en `docs/PENDIENTE_PARA_CERRAR.md §5` y
en el cuadro de mando del plan vivo.

Lo más notable:

- **Hallazgo grave:** el APK release **nunca había compilado** en Flutter
  3.x. Tres causas encadenadas (workmanager con API v1-embedding
  removida, `flutter_local_notifications` exigía core library
  desugaring, daemon Gradle se quedaba sin memoria). Cerrado con
  eliminación de workmanager (dependencia muerta), `coreLibraryDesugaring`
  + `desugar_jdk_libs:2.1.4`, y `gradle.properties` con `-Xmx4G` +
  `daemon=false`.
- **Kotlin DSL en `build.gradle.kts`** — un commit posterior introdujo
  sintaxis Groovy mezclada y ternario C-style (no existen en Kotlin DSL);
  detectado por CI Android rojo, arreglado en commit dedicado.
- **CI nunca había pasado** hasta corregir un asset `.env` ausente y
  alinear versión Flutter (3.32.x → 3.35.x para SDK Dart `^3.9.2`).

Esos hallazgos están documentados con honestidad en los históricos —
muestran que el rigor de las verificaciones independientes fue tan
importante como el desarrollo en sí.

---

## 7. Conclusión del desarrollo

El producto entregado es **funcional, verificado y trazable**: cada
commit pasa por `flutter analyze` (0 issues), 175 tests, CI con 4 jobs
verdes, y un APK release que compila. La cobertura de pruebas
(24,30 %) está reconocida como deuda con palanca identificada (P2-4 del
plan). Las decisiones de arquitectura están documentadas y respetadas
(verificable con grep). La asistencia IA queda declarada con
transparencia. El siguiente documento (`05_evaluacion_documentacion.md`)
recopila los procedimientos de seguimiento y los indicadores reales.
