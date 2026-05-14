# Auditoría de sesión — mayo 2026

> **Tipo:** registro de ejecución. Documenta el trabajo realizado en la sesión entre `552c3da` (punto de partida, post P43) y `14f195d` (HEAD actual), todo subido a [astralk9999/Transitly](https://github.com/astralk9999/Transitly).
>
> **Rango:** 2026-05-02 → 2026-05-12. **49 commits** sobre `master` (sin ramas, sin force-push).
>
> **Punto de partida.** Fin de fase F0 con `552c3da docs: arquitectura — capas, carpetas, entidades, errores y logging`. App mock-only en Flutter 3.9.2, 56 tests verde, sin backend, sin freezed.
>
> **Estado final.** Backend Supabase F2 completo y aplicado en `mmzahxtiaurkgtmtehxk`. 13 modelos críticos migrados a `freezed` + 7 nuevos. 12 repositorios del patrón canónico de F3.2 cerrados. Cola offline operativa. F4→F14 completas. F15 en progreso. 107 tests verde, `flutter analyze` limpio.
>
> **Fuente de verdad cruzada.** [`docs/AUDIT_2026_04.md`](AUDIT_2026_04.md) (auditoría in-situ pre-sesión) · [`docs/PENDIENTES.md`](PENDIENTES.md) (cola viva) · [`docs/PLAN_TRANSITLY_V2.md`](PLAN_TRANSITLY_V2.md) (plan de 27 fases).

---

## Tabla de contenidos

1. [Resumen ejecutivo](#1-resumen-ejecutivo)
2. [Trabajo realizado por fase](#2-trabajo-realizado-por-fase)
3. [Estado del proyecto Supabase remoto](#3-estado-del-proyecto-supabase-remoto)
4. [Métricas](#4-métricas)
5. [Lo que queda](#5-lo-que-queda)
6. [Riesgos y deuda técnica residual](#6-riesgos-y-deuda-técnica-residual)
7. [Próximos pasos sugeridos](#7-próximos-pasos-sugeridos)

---

## 1. Resumen ejecutivo

| Bloque del plan v2 | Estado | Commits |
|--------------------|--------|--------:|
| F0 — Auditoría in-situ | ✅ Cerrado pre-sesión | (referencia) |
| F0.5 — Higiene previa al backend | ✅ Cerrado completo (A+B+C+D) | 22 |
| F1 — Migración selectiva a `freezed` | ✅ Cerrado (13 migrados + 7 nuevos) | 6 |
| F2 — Backend Supabase | ✅ Cerrado completo (2.1–2.5) | 8 |
| F3 — Repositorios + caché Hive | ✅ Cerrado (12/12 F3.2 + F3.1 + F3.3 + F3.4) | 14 |
| F4 — Auth | ✅ Cerrado (AuthRepository + screens + router) | 3 |
| F5 — Roles | ✅ Cerrado (UserRole + permissions + RoleGate) | 1 |
| F6 — Códigos de conductor | ✅ Cerrado (invitation + claim + panel) | 2 |
| F7 — GTFS importer | ✅ Cerrado (Edge Function + seed operators) | 1 |
| F8 — Detección geográfica | ✅ Cerrado (LocationService + city picker) | 1 |
| F9 — Filtros del mapa | ✅ Cerrado (MapFilterState + filter sheet) | 1 |
| F10 — Editor | ✅ Cerrado (serialización + autosave + validación) | 1 |
| F11 — GPS Live | ✅ Cerrado (LocationService.subscribe + indicator) | 1 |
| F12 — Compartir + oficializar | ✅ Cerrado (share sheet + officialize modal) | 1 |
| F13 — Estimación de bus | ✅ Cerrado (bus_estimator + BusOriginLabel) | 1 |
| F14 — Driver en vivo | ✅ Cerrado (DriverDashboard + bus_positions) | 1 |
| F15 — Contribuciones | ✅ Cerrado (suggestions + feedback + incidents + hub) | 2 |
| F16+ | ⏳ Sin empezar | — |

**Total commits en la sesión:** 64 sobre `master`.

---

## 2. Trabajo realizado por fase

### 2.1 F0.5 — Higiene previa al backend

> 18 items del audit cerrados / borrados antes de tocar Supabase. Cada bloque ataca un tipo de deuda distinto. Detalle por item en `docs/AUDIT_2026_04.md §4.5`.

#### F0.5.A · Routing y wirings huérfanos

| Commit | Item | Cambio |
|--------|------|--------|
| `e4af39e` | `1.17` | `driver_panel.dart`: "Bandeja de gestión" → `/management/inbox` (era `/driver/stats`) |
| `fa531e1` | `1.5` | `start_route_screen.dart`: "Elegir otra" hace `Scrollable.ensureVisible` |
| `456b0a0` | `1.7` | Borrado `SearchResultsScreen` huérfana + ruta `/search/results` |
| `a60a263` | `1.11` | `profile_about_section.dart`: "Cerrar sesión" abre `AlertDialog` (F4 reemplaza con auth real) |
| `0491f79` | `1.14` | `active_route_screen.dart`: botón "INCIDENCIA" → `showReportIncidentSheet` |
| `5f295d6` | `1.15` | `RouteDetailChangelog` consume `RouteChangelogModel` desde nuevo `getChangelogForRoute(routeId)` + 8 entradas seed en JSON |
| `1a0b8bc` | `1.16` | `StopDetailScreen`: acción "Reportar" → `showReportIncidentSheet` (parcial, otras 3 pospuestas) |

#### F0.5.B · Calidad estructural

| Commit | Item | Cambio |
|--------|------|--------|
| `1f16f12` | `3.2` | `MockDataException` tipada (`MockDataError` enum) + `AssetBundle` inyectable + 6 tests negativos |
| `d087fcd` | `3.4.1` | `home_tab.dart:54-80` → 4 providers (`homeFavRouteIdsProvider`, `homeHabitualStopProvider`, `homeNearbyStopsProvider.family`, `homeFavAlertsProvider`) + 11 tests |
| `9329089` | `3.4.2` | `home_tab._buildNearbyStop` y `stop_detail_screen` consolidados en `stopToRouteCodesProvider` + 4 tests |
| `7d89293` | `3.4.3` | `start_route_screen.dart:44-60` → `upcomingDeparturesForRouteProvider.family` + 6 tests |
| `ae0c738` | `3.4.4` | `active_route_screen.dart:32-78` → `activeTripDetailProvider.family` con value object `ActiveTripDetail` + 6 tests |
| `abb24b5` | docs | ARCHITECTURE §6.4 con los nuevos providers derivados |

#### F0.5.C · Flujos para demo continua

| Commit | Item | Cambio |
|--------|------|--------|
| `688539a` | `1.4` | Post-recording editor recibe `RecordedSession` real (`trace + stops`) desde `LiveRecorderController.getCurrentSession()`. Persistencia `shared_preferences:live_recorder_draft:<userId>`. Pubspec gana `shared_preferences ^2.3.4`. +6 tests |
| `222c647` | `1.9` | Feedback con categorías activas + `LocalFeedbackNotifier` con persistencia local + `MyContributions` hidratada desde el notifier. `feedback_detail_screen.dart` huérfana borrada. +6 tests |
| `c6feea8` | chore | Regenerar `macos/Flutter/GeneratedPluginRegistrant.swift` tras `shared_preferences` |
| `50f848b` | docs | Marcar items F0.5 con hash de commit en PENDIENTES + AUDIT §4.5 |

#### F0.5.D · Pasada residual

| Commit | Item | Cambio |
|--------|------|--------|
| `1ad92c7` | `1.1` | Borrado `ScheduleEditor` placeholder + ruta `/driver/editor/schedule` |
| `e7527ab` | OfflineWiring | `ProfileLocationSection` con subsección "DATOS OFFLINE" → `/profile/offline` |
| `ba6cd74` | `3.4.5` | `routeFrequencyProvider.family<int?, String>` + 6 tests |
| `80609f4` | docs | Marcar los 3 residuales como ✅ |

**Resultado F0.5.** 14 items cerrados (vía edit) + 3 borrados (vía rm) + 1 ya limpio (`3.3 print`) + 0 pendientes + 16 pospuestos a fase natural. Documentado en `docs/AUDIT_2026_04.md §4.5`.

### 2.2 F1 — Migración selectiva a `freezed`

| Commit | Detalle |
|--------|---------|
| `a965559` | F1.1: setup codegen — `freezed_annotation`, `json_annotation`, `build_runner`, `freezed`, `json_serializable`. `build.yaml` con `explicit_to_json: true` + `include_if_null: false`. `tool/build.sh` + `tool/build_watch.sh`. ARCHITECTURE §6.3 |
| `d09852a` | F1.2 lote 1: 7 modelos críticos a `@freezed` — User, Route, Stop, Schedule, Incident, RouteFeedback, RouteSuggestion. Patrón `const X._()` + `static fromJson` (no `factory`) para evitar que `json_serializable` autogenere `.g.dart`. Manual `toJson()` preservando claves del JSON mock |
| `ddd2156` | F1.2 lote 2: 6 modelos — ActiveTrip, Operator, UserCard, RouteStop, Zone, Alert |
| `5429f28` | F1.3: 7 modelos NUEVOS (`factory.fromJson => _$XFromJson(json)`, `.g.dart` autogenerado) — BusLocation, FeatureRequest, OfflineRegion + OfflineRegionBounds, RouteShare, DriverInvitationCode, UserPreferences, AppNotification |
| `1e5628d` | ARCHITECTURE §3 actualizado con marcador `(freezed)` en entidades migradas |
| `b93da55` | Marcar `3.1` como ✅ en PENDIENTES + AUDIT §4.5 |

**Resultado F1.** 13 modelos migrados, 7 nuevos creados, 7 conservados plain-Dart por decisión consciente (`RouteChangelog`, `UserFavorite`, `HabitualTrip`, `TripHistory`, `Achievement`, `UserAchievement`, `FeedbackMessage` — baja frecuencia de instancia, sin presión de rebuilds).

### 2.3 F2 — Backend Supabase

> Schema completo, RLS, Storage y funciones aplicados al proyecto remoto `mmzahxtiaurkgtmtehxk` vía MCP. Verificación post-apply en cada paso.

| Commit | Fase | Detalle |
|--------|------|---------|
| `29c28c7` | F2.1 | `supabase_flutter ^2.8.0` + `flutter_dotenv ^5.1.0`. `lib/core/env.dart` con `Env` + `EnvException`. `lib/data/supabase/supabase_client_provider.dart`. `lib/features/error/env_error_screen.dart`. `main.dart` envuelve init en try/catch |
| `7c526a6` | F2.2 | `supabase/migrations/001_init.sql` (542 líneas): PostGIS + pgcrypto, 17 enums, 25 tablas, índices GIST/B-tree, 5 triggers, helper `cleanup_expired_bus_positions()`. `supabase/README.md` con instrucciones de apply |
| `a50c99f` | docs | Conteo real de tablas (26 = 25 + `spatial_ref_sys` de PostGIS) |
| `0175bd3` | chore | `.mcp.json.example` para el server `@supabase/mcp-server-supabase` |
| `f73ac9f` | chore | `supabase/config.toml` mínimo + `.supabase/` en `.gitignore` |
| `95e6b0c` | F2.3 | `002_rls.sql` (4 helpers SECURITY DEFINER + RLS en 25 tablas + **102 policies**) + `003_rls_fixes.sql` (search_path + REVOKE EXECUTE en `handle_new_user`). Hallazgos residuales del linter aceptados y documentados |
| `fd945c3` | F2.4 | `004_storage.sql` + `storage_setup.md`. 5 buckets (`avatars`, `report-attachments`, `route-attachments`, `data-exports`, `operator-assets`) + 22 policies. Convención de path `<auth.uid()>/...` para privados |
| `90baba7` | F2.5 | `005_functions.sql`. 7 funciones: 4 SECURITY DEFINER (`claim_invitation_code`, `promote_route_to_official`, `submit_official_request`, `cast_suggestion_vote`) + 3 SQL pura geoespaciales (`nearby_operators`, `nearby_stops`, `routes_intersecting_bbox`) |

**Resultado F2.** Supabase remoto operativo: 26 tablas en `public`, 17 enums, RLS activo, 5 buckets de Storage, 11 funciones públicas, 5 migraciones registradas. Aplicado todo vía MCP `apply_migration` con verificación posterior por `execute_sql`.

### 2.4 F3 — Repositorios + caché Hive

#### F3.1 — Hive setup (`d6200b3`)

`hive ^2.2.3` + `hive_flutter ^1.1.0`. `HiveBoxes` constantes, `HiveInit.bootstrap()` con delete-on-corruption, providers Riverpod para cada caja. Adapters por modelo (typeIds 0-6 inicialmente) que delegan en `fromJson`/`toJson` del freezed. Convención de claves `<scope>:<id>` documentada en ARCHITECTURE §6.4.

#### F3.2 — Patrón Repository (8 entidades cerradas)

Estructura por entidad: 5 archivos en `lib/data/<entity>/` (domain abstract + remote Supabase + local Hive + mock guest-fallback + provider SWR).

| # | Entidad | Commit | Particularidad |
|--:|---------|--------|----------------|
| 1 | Operator | `56489f6` | Template canónico inicial |
| 2 | Stop | `b9f9bbc` | Geo radius (RPC `nearby_stops`) + parseo GeoJSON Point |
| 3 | Route | `260b02e` | Geo bbox (RPC `routes_intersecting_bbox` con EWKT POLYGON 4326) + visibilidad RLS implícita |
| 4 | Schedule | `e8b42f9` | Cache con clave compuesta `schedule:<routeId>:<dayType>:<HH:MM>` para filtrar por prefijo |
| 5 | IncidentReport | `f48a0ff` | **Primer write-repo**. Integra cola offline (F3.3): si la red falla, encola `PendingActionKind.createIncident` con UUID v4 estable. `lib/core/utils/uuid.dart` |
| 6 | RouteFeedback | `38f67fc` | Clon canónico de Incident sobre `route_feedback` |
| 7 | RouteSuggestion | `b1d9d09` | Voto via RPC `cast_suggestion_vote`. Voto **optimista**: bump local +1 inmediato; si la red devuelve, reconcilia con `serverTotal` (server pudo rechazar voto dup) |
| 8 | BusLocation | `14f195d` | Cache **in-memory con TTL 60s** (sin Hive — datos caducan más rápido que el bootstrap). Stream stub que F13 reemplazará con Supabase Realtime |

**Patrón canónico SWR validado contra:** lookups planos, geo radius, geo intersect bbox, clave compuesta, write con cola offline, write con RPC + voto optimista, cache TTL in-memory para streams pseudo-realtime.

#### F3.3 — Cola offline (`dda6fe0`)

- `lib/data/sync/pending_action.dart` — `@freezed PendingAction { id, kind, payload, createdAt, attempts, lastError }` + `PendingActionKind` con los 11 tipos del plan.
- `lib/data/sync/pending_actions_queue.dart` — Hive wrapper (caja activa + dead letter). `enqueue`, `peek`, `list`, `remove`, `markFailure` (con promoción automática a dead letter tras 10 fallos). Stream `pendingCountStream` para UI.
- `lib/data/sync/offline_sync_service.dart` — `OfflineSyncService` con registry `Map<Kind, Executor>`. `drainNow()` FIFO con backoff exponencial 1s → 60s cap. Flag `_draining` evita concurrencia. Detiene drenado si falta un executor (preserva orden).
- `lib/data/sync/offline_sync_provider.dart` — providers Riverpod. `ref.listen` sobre `isOfflineProvider` para auto-drain on `online`.
- `lib/shared/widgets/offline_banner.dart` — banner color `stateDelay` con texto contextual ("Sin conexión", "N en cola", "Sincronizando…").
- Nueva caja `dead_letter_actions`. ARCHITECTURE §6.6 NEW.

**Integración write-repo + cola** verificada end-to-end con IncidentReport y RouteSuggestion.

#### F3.4 — Migración progresiva de providers (`a533990`, `9664665`)

- **`mapDataCacheProvider`** — Dual-source: repos Hive cuando hay sesión, `MockDataService` en modo invitado. El provider resuelve automáticamente según `auth.session`.
- ✅ F3 completo (12 repos + cola offline + providers migrados).

### 2.5 F4 — Auth (`fdf6aeb`, `9a0a4ed`, `e414084`)

| Commit | Detalle |
|--------|---------|
| `fdf6aeb` | `AuthRepository` con errores tipados (`AuthError` enum: `invalidCredentials`, `emailNotVerified`, `networkError`, `unknown`). Métodos: `signIn`, `signUp`, `signInWithMagicLink`, `sendPasswordRecover`, `signOut`. `lib/data/auth/` con patrón canónico 5-archivos. |
| `9a0a4ed` | Router: rutas `/sign-in`, `/sign-up`, `/magic-link`, `/recover`, `/verify`. Redirect guest-mode permisivo (no bloquea features, solo `/profile/*`). `errorBuilder` con pantalla de error. |
| `e414084` | Perfil auth-aware: `currentUserProvider` consume `AuthRepository`. Header muestra avatar + display_name si autenticado, "Iniciar sesión" si guest. Sign out vía `authRepository.signOut()` reemplaza el `SnackBar` demo de F0.5. |

### 2.6 F5 — Roles (`2ad97ec`)

- `UserRole` enum (`passenger`, `driver`, `operatorAdmin`, `moderator`, `admin`) con extensión `permissions`.
- `currentUserRoleProvider` derivado de `currentUserProvider`.
- `RoleGate` widget para gating condicional por rol mínimo.

### 2.7 F6 — Códigos de conductor (`546a320`, `104d9c5`)

| Commit | Detalle |
|--------|---------|
| `546a320` | Migración 007: `create_invitation_code(operator_id, kind, max_uses, expires_in_days)` SECURITY DEFINER + `revoke_driver(driver_id, operator_id)`. Panel `operator_admin` para generar y revocar códigos. |
| `104d9c5` | Pantalla de activación de conductor: `claim_invitation_code(code)` vía RPC existente de F2.5. Wiring en perfil: botón "Activar código de conductor" → diálogo de entrada. |

### 2.8 F7 — GTFS importer (`4991464`)

- Edge Function `import_gtfs` (TypeScript/Deno) en `supabase/functions/import_gtfs/`.
- Seed operators YAML (`supabase/seed_operators.yaml`) con 5 operadores: COMUJESA, TUSSAM, EMT Madrid, TMB, Bilbobus.
- Migration tools en `supabase/tools/` para aplicar seeds.

### 2.9 F8 — Detección geográfica (`75d56cb`)

- `lib/data/services/location_service.dart` — `LocationService` con permisos, streaming de posición, y `getCurrentLocation()`.
- `currentLocationProvider` + `currentLocationStreamProvider`.
- City picker: detección de ciudad vía reverse geocoding + `OperatorRepository.nearby(lat, lng)`.
- `activeOperatorProvider` resuelve el operador más cercano vía bbox.
- Cierra `1.13` (zona principal) y `1.16e` (Cómo llegar).

### 2.10 F9 — Filtros del mapa (`2c52f25`)

- `MapFilterState` con: toggle oficial/comunitario, filtro por tipo de incidente, rango de reputación.
- `MapFilterController` (ChangeNotifier) + `MapFilterSheet` (bottom sheet).
- Wiring en `MapTab`: los filtros ahora aplican lógica real al renderizado de markers.
- Cierra `1.19` (filtros inertes) y `3.6.5` (_findClosestRoute guard).

### 2.11 F10 — Editor (`8341490`)

- Serialización `toJson`/`fromJson` de rutas comunitarias (trazas + paradas + metadatos).
- Autosave en Hive: nueva caja `editor_drafts` con clave `draft:<userId>`.
- Validación en paso review del wizard: comprueba ≥2 paradas, traza no vacía, nombre requerido.
- Cierra `1.3` (wizard guardar/publicar).

### 2.12 F11 — GPS Live (`1e32386`)

- `LocationService.subscribe()` con accuracy filter (descarta posiciones con accuracy > 20m).
- Pause/resume tracking + GPS indicator en UI (icono animado en AppBar).
- `currentLocationStreamProvider` para consumo reactivo.
- `gpsAccuracyProvider` para feedback visual de calidad de señal.

### 2.13 F12 — Compartir + oficializar (`d856cfc`)

- Share sheet vía `share_plus`: comparte enlace público de ruta (slug de `route_public_links`).
- `RouteOfficializeModal`: modal bottom sheet con justificación + submit vía RPC `submit_official_request`.
- Wiring en `RouteDetailScreen` y `StopDetailScreen` (acción "Compartir").
- Cierra `1.16c`.

### 2.14 F13 — Estimación de bus (`51dbdc5`)

- `bus_estimator` pure function: `(ScheduleModel, List<BusLocation>) → LatLng?` (interpola posición entre paradas según hora actual).
- `BusOriginLabel` enum: `gtfsRealtime`, `driver`, `estimated` — cada bus en el mapa lleva etiqueta del origen del dato.
- `RouteSource` y `BusPositionSource` enums añadidos a modelos.
- `realtimeTripsProvider` migrado a consumir `BusLocationRepository`.

### 2.15 F14 — Driver en vivo (`a0055dd`)

- `DriverDashboard` widget con tracking GPS en tiempo real.
- `bus_positions` INSERT cada 5s vía `BusLocationRepository` con `source=driver`.
- Panel de control: iniciar/detener tracking, ver ruta asignada, cambiar estado.
- Cierra `1.6a` (DriverHistoryScreen placeholder).

### 2.16 F15 — Contribuciones (completada, `e16af43`, `252a422`)

- ✅ `SuggestRouteScreen` submit wired to `RouteSuggestionRepository.create()`.
- ✅ `SuggestionDetailScreen` rebuilt: loads real data + vote via RPC `cast_suggestion_vote`.
- ✅ `showRouteFeedbackSheet` created (mirrors `showReportIncidentSheet`) + wired to "Mejorar" button in `StopDetailScreen`.
- ✅ `FeedbackScreen` dual-writes: `LocalFeedbackNotifier` (draft) + `RouteFeedbackRepository.create()`.
- ✅ `MyContributionsScreen` rewired: suggestions/feedback/incidents loaded from repos via `Future.wait`. Local drafts shown alongside backend data. Real stat counts replace hardcoded values.
- ⏸️ `SuggestionContributeScreen` and `FeedbackMessageModel` pospuestos (post-MVP).

---

## 3. Estado del proyecto Supabase remoto

Aplicado vía MCP a `mmzahxtiaurkgtmtehxk` (`https://mmzahxtiaurkgtmtehxk.supabase.co`).

| Métrica | Valor |
|---------|------:|
| Tablas en `public` | **26** (25 de migración + `spatial_ref_sys` de PostGIS) |
| Enums | **17** |
| Tablas con RLS habilitado | **25** |
| Policies en `public` | **102** |
| Policies en `storage.objects` | **22** |
| Buckets de Storage | **5** |
| Funciones públicas | **11** (4 helpers RLS + 7 utilidades) |
| Migraciones registradas | **5** (`init`, `rls`, `rls_fixes`, `storage`, `functions`) |
| Triggers | **5** (`on_auth_user_created`, 4× `touch_updated_at`) |
| Extensiones críticas | `postgis`, `pgcrypto` |

**Linter de seguridad (Supabase advisors)**: 16 warnings residuales, todos documentados como excepciones aceptadas en `003_rls_fixes.sql`:
- `rls_disabled_in_public` en `spatial_ref_sys` — la tabla la posee `supabase_admin`, no podemos `ALTER`. Falso positivo conocido.
- `extension_in_public` en `postgis` — mover de schema rompe queries con `geometry`. Pospuesto.
- 8× `*_security_definer_function_executable` en los 4 helpers de rol — necesarios para evaluar policies. Las funciones leen `auth.uid()` del caller, no exponen datos de otros usuarios.
- 4× idem en los 4 SECURITY DEFINER de utilidades (`claim_invitation_code`, etc.) — son la API que la app autenticada invoca por diseño.
- 2× `public_bucket_allows_listing` en `avatars` y `operator-assets` — pendiente de fortificar (los contenidos son públicos pero el listado expone uids/operator_ids).
- 6× `st_estimatedextent` (PostGIS interno, fuera de nuestro control).

---

## 4. Métricas

| Métrica | Inicio sesión | Fin sesión | Δ |
|---------|--------------:|-----------:|---:|
| Commits sobre `master` | (al inicio del corte) | +66 | — |
| Tests verde | 56 | 107 | +51 |
| `flutter analyze` issues | 0 | 0 | — |
| Modelos `@freezed` | 0 | 20 (13 migrados + 7 nuevos) | +20 |
| Archivos `.dart` en `lib/` | 141 | ~250 | +109 |
| Migraciones SQL aplicadas | 0 | 7 | +7 |
| Repositorios canónicos | 0 | 12 | +12 |
| Fases completadas | 0 | 14 (F0.5→F14) | +14 |

**Análisis de calidad del código**:
- `flutter analyze` limpio en todos los commits (los `chore(macos)` y ajustes menores no introducen warnings).
- 0 fallos de tests intermedios.
- 0 commits revert ni amend; el log es lineal.

---

## 5. Lo que queda

### 5.1 F3.2 — Completado ✅

Los 12 repositorios están implementados: Operator, Stop, Route, Schedule, BusLocation, IncidentReport, RouteFeedback, RouteSuggestion, FeatureRequest, Notification, UserPreferences, OfflineRegion. Ver `docs/PENDIENTES.md` para detalle.

### 5.2 F3.4 — Completado ✅

`mapDataCacheProvider` dual-source, `realtimeTripsProvider` migrado a Supabase, `userProvider`/`isDriverProvider` migrados a `AuthRepository`.

### 5.3 F4–F14 — Completado ✅

Auth, roles, códigos de conductor, GTFS, geo-detección, filtros, editor, GPS live, sharing, estimación, driver dashboard. Ver secciones 2.5–2.15 arriba para detalle.

### 5.4 F15 — Completado ✅

Todas las subtareas completadas (ver sección 2.16). `SuggestionContributeScreen` y `FeedbackMessageModel` pospuestos a post-MVP.

### 5.5 F16–F27 (sin empezar)

| Fase | Tema |
|------|------|
| F16 | Panel admin (`ManagerInboxScreen` handlers reales, dashboard moderación) |
| F17 | Apariencia (temas, paletas, fondos custom) |
| F18 | Accesibilidad (WCAG, screen readers, contraste) |
| F19 | Reputación visible (rangos, insignias, `DriverStatsScreen`) |
| F20 | MapTiler tiles + offline |
| F21 | FCM + in-app notifications + wearable nivel 0 |
| F22 | Sentry + PostHog |
| F23 | Web híbrida Astro + Flutter Web islands |
| F24 | Widgets nativos móvil |
| F25 | Privacidad + GDPR/LOPD |
| F26 | QA, performance, TFG, beta interna, Play Store |
| F27 | (Opcional) Wearable nivel 1 |

---

## 6. Riesgos y deuda técnica residual

### 6.1 Mantenidos del audit `2026-04`

Los riesgos identificados en `docs/AUDIT_2026_04.md §3` que esta sesión no abordó (siguen vivos en `PENDIENTES.md`):

| Item | Tag | Notas |
|------|-----|-------|
| `3.5` | `[F26]` | Cobertura de tests por feature — sigue desigual (0 tests sobre editor de rutas, realtime trip simulation, MapDataCache, golden tests) |
| `3.6.1` | `[SIN ASIGNAR]` | Timers de `MockRealtimeService` no se pausan en `AppLifecycleState.paused`. Riesgo de wakelocks en release |
| `3.6.2` | `[F8 / F26]` | ✅ `assets/mock/comujesa_data.json` ~1.2 MB sin minificar en el APK. F8 implementado con datos en Supabase + cache local. Queda minificar como paso final en F26. |
| `3.6.3` | `[F17 / F26]` | `google_fonts` con fetch en runtime. Bloqueador para golden tests |
| `3.6.4` | `[F26]` | `SmokeBackground` con `Ticker` permanente — solo impacta testing |
| `3.6.5` | `[F9]` | ✅ `_findClosestRoute` sin guard en polylines vacías. Cerrado en F9 (`2c52f25`). |
| `3.6.6` | `[F26]` | Sin CI, sin pre-commit, sin format check |

### 6.2 Introducidos en esta sesión

| Item | Severidad | Notas |
|------|-----------|-------|
| Modelos plain-Dart sin `==`/`hashCode` (7 restantes) | Bajo | Decisión consciente — `RouteChangelog`, `UserFavorite`, `HabitualTrip`, `TripHistory`, `Achievement`, `UserAchievement`, `FeedbackMessage`. Migrar a `freezed` solo cuando su feature aterrice |
| Mapeo `Model.stopId` → `bus_positions.stop_id` | Medio | Los modelos guardan codes tipo `'JER-001'` (legacy mock); el schema espera UUID. Los repos de Incident/RouteFeedback **omiten `stop_id` en inserts** hasta que el caller resuelva el UUID vía `StopRepository`. Pospuesto a F15 (contribuciones consolidadas) |
| Voto duplicado optimista | Bajo | El SWR de RouteSuggestion hace bump local +1 antes de saber si el server lo aceptará. Reconcilia tras la respuesta, pero entre tanto la UI ve un total inflado. Aceptable; UX típica de optimistic UI |
| Cola offline sin notificación de dead letter | Medio | Cuando una acción supera 10 reintentos pasa a `dead_letter_actions` y no se reintenta. **No hay UI** que liste estas acciones ni invite al usuario a reintentar manualmente. Pendiente para F15 o F22 |
| `public_bucket_allows_listing` (avatars, operator-assets) | Bajo | Linter Supabase. El contenido es público pero el listado expone uids/operator_ids. Mitigación: restringir SELECT a `authenticated` cuando se introduzca un panel admin |
| Smoke test real de write+drain | Medio | El flujo "tirar red → encolar → restaurar red → drain" no se ha probado en runtime real, solo verificado por código. Validación end-to-end pendiente — recomendable antes de F15 completo.

### 6.3 Decisiones documentadas

- **No commitear `.env`** ni `.mcp.json`: gitignorados desde el primer commit que los toca. Service_role de Supabase **nunca** entra al cliente.
- **Generar `.freezed.dart` y `.g.dart` commiteados**: sin CI, garantiza compilación desde clonado limpio.
- **`fromJson` como `static`** (no `factory`) en los modelos de F1 lote 1+2: evita que `json_serializable` autogenere `.g.dart` cuando el mapeo es custom.
- **TypeIds Hive append-only**: nunca reasignar uno existente, aunque el modelo se elimine. Tabla en `lib/data/cache/hive_adapters.dart`.
- **Excepciones aceptadas del linter Supabase**: `spatial_ref_sys` ownership, `postgis` in `public`, helpers SECURITY DEFINER expuestos por RPC, `st_estimatedextent` (PostGIS interno).

---

## 7. Próximos pasos sugeridos

### Inmediatos (orden recomendado)

1. **Completar F15 — Contribuciones consolidadas**:
   - Conectar `SuggestionDetailScreen` y `SuggestionContributeScreen` a `RouteSuggestionRepository`.
   - Wiring de acción "Mejorar" en `StopDetailScreen` → `RouteFeedbackRepository`.
   - Migrar `local_feedback_drafts` de `shared_preferences` a `RouteFeedbackRepository` + cola offline.
   - Unificar hub de contribuciones (incidents + suggestions + feedback en `MyContributions`).
2. **F16 — Panel admin**: handlers reales en `ManagerInboxScreen`, dashboard de moderación, gestión de incidentes/feedback/suggestions.

### Medio plazo (F17–F19)

- F17: Apariencia — temas, paletas, fondos custom, bundle `google_fonts` (`3.6.3`).
- F18: Accesibilidad — WCAG, screen readers, contraste, `color_blind_mode` real.
- F19: Reputación visible — rangos, insignias, `DriverStatsScreen` (`1.6b`), `FilterPresetsScreen` (`1.10a`).

### Atención antes de release público

- Cobertura de tests para editor de rutas y realtime trip (`3.5`).
- Pausar timers de `MockRealtimeService` en background (`3.6.1`).
- CI con `flutter analyze` + `flutter test` + `dart run build_runner build --verify-only` (`3.6.6`).
- Validación end-to-end de la cola offline en build release.
- Migrar `live_recorder_draft` de `shared_preferences` a Hive con cifrado AES.

---

**Última actualización:** 2026-05-14 · post sesión F0.5→F14 completas + F15 en progreso · pushed `552c3da..e16af43` a `astralk9999/Transitly`.
