# Pendientes

> **Origen.** Lista derivada de `docs/AUDIT_2026_04.md` §4 "Propuesta de cierre". Cada item conserva su numeración del audit (`1.x` para puntos a medias, `3.x` para riesgos). Cuando el audit se actualice, este documento se sincroniza.
>
> **Convención de buckets.**
> - **Bloqueantes** = items marcados S/M con decisión `cerrar` o `borrar`. Se resuelven en F0.5 (higiene previa al backend) antes de tocar `freezed` o Supabase.
> - **Mejora** = items marcados L *o* items S/M con decisión `posponer`. Se cierran como parte de su fase natural en el plan v2.
> - **Ideas para v3** = caja vacía para entradas que surjan durante v2 sin encajar en ninguna fase actual.
>
> **Tag de fase.** `[F<n>]` si el item está mapeado a una fase del plan; `[SIN ASIGNAR]` si no.

---

## Bloqueantes

> Se cierran en F0.5. Esfuerzo previsto ≈ 1 día. Orden ejecutado: F0.5.A → F0.5.B → F0.5.C.

### ✅ Cerrados en F0.5 (15 items + 2 huérfanos + 1 parcial)

> Cada entrada referencia el commit donde se cerró el item. Fechas en formato ISO. Convención de hash: 7 chars.

#### F0.5.A · routing y wirings (commits 2026-05-04)

- ✅ [F0.5.A] **`1.17`** — Bug de routing en `driver_panel.dart:72`. Bandeja de gestión ahora enlaza a `/management/inbox`. `S` · `cerrar` · `e4af39e`.
- ✅ [F0.5.A] **`1.5`** — "Elegir otra" en `start_route_screen.dart:111` hace `Scrollable.ensureVisible` a la lista de rutas. `S` · `cerrar` · `fa531e1`.
- ✅ [F0.5.A] **`1.7`** — `SearchResultsScreen` placeholder + huérfana eliminada. Ruta `/search/results` retirada. `S` · `borrar` · `456b0a0`.
- ✅ [F0.5.A] **`1.11`** — "Cerrar sesión" abre `AlertDialog` con `SnackBar` "Sesión cerrada (demo)". F4 lo reemplaza por `authRepository.signOut()`. `S` · `cerrar` · `a60a263`.
- ✅ [F0.5.A] **`1.14`** — Botón "INCIDENCIA" en `active_route_screen.dart` invoca `showReportIncidentSheet` con `route` y `nextStop` precargados. `S` · `cerrar` · `0491f79`.
- ✅ [F0.5.A] **`1.15`** — `RouteDetailChangelog` ahora consume `RouteChangelogModel` vía `MockDataService.getChangelogForRoute(routeId)`. JSON ganó `routeChangelogs` con 8 entradas seed. `S` · `cerrar` · `5f295d6`.
- ✅ [F0.5.A] **`1.16` (parcial)** — Acción "Reportar" en `stop_detail_screen.dart` invoca `showReportIncidentSheet` con `stop` precargado. Las otras 3 (Compartir, Mejorar, Cómo llegar) → ver "Mejora". `S` · `cerrar` · `1a0b8bc`.

#### F0.5.B · calidad estructural (commits 2026-05-04)

- ✅ [F0.5.B] **`3.2`** — `MockDataException` tipada con `MockDataError`. `MockDataService.init({AssetBundle? bundle})` inyectable. `M` · `cerrar` · `1f16f12`.
- ✅ [F0.5.B] **`3.4.1`** — `home_tab.dart:54-80` movido a `homeFavRouteIdsProvider`, `homeHabitualStopProvider`, `homeNearbyStopsProvider.family`, `homeFavAlertsProvider`. `M` · `cerrar` · `d087fcd`.
- ✅ [F0.5.B] **`3.4.2`** — Inverted index `home_tab._buildNearbyStop` y `stop_detail_screen` consolidados en `stopToRouteCodesProvider`. `M` · `cerrar` · `9329089`.
- ✅ [F0.5.B] **`3.4.3`** — `start_route_screen.dart:44-60` consume `upcomingDeparturesForRouteProvider.family`. `M` · `cerrar` · `7d89293`.
- ✅ [F0.5.B] **`3.4.4`** — `active_route_screen.dart:32-78` consume `activeTripDetailProvider.family<ActiveTripDetail?, String>`. `M` · `cerrar` · `ae0c738`.

#### F0.5.C · flujos para demo continua (commits 2026-05-04)

- ✅ [F0.5.C] **`1.4`** — Post-recording editor recibe `trace` y `stops` reales desde `LiveRecorderController.getCurrentSession()`. Persistencia en `shared_preferences:live_recorder_draft:<userId>`. `M` · `cerrar` · `688539a`.
- ✅ [F0.5.C] **`1.9`** — Categorías de feedback activas: selección + envío real vía `LocalFeedbackNotifier` con `shared_preferences:local_feedback_drafts`. `MyContributions` hidrata desde el notifier. `M` · `cerrar` · `222c647`.
- ✅ [F0.5.C] **`feedback_detail_screen.dart`** — huérfana eliminada junto con la ruta `/feedback/detail`. `S` · `borrar` · `222c647`.

#### F0.5.D · pasada extra de cierre (commits 2026-05-05)

- ✅ [F0.5.D] **`1.1`** — `ScheduleEditor` placeholder + ruta `/driver/editor/schedule` eliminados. Solapaba con `StepSchedules` del wizard. `S` · `borrar` · `1ad92c7`.
- ✅ [F0.5.D] **Wiring olvidado de `OfflineDataScreen`** — `ProfileLocationSection` gana subsección "DATOS OFFLINE" con `context.push('/profile/offline')`. `S` · `cerrar` · `e7527ab`.
- ✅ [F0.5.D] **`3.4.5`** — Cálculo de frecuencia en `route_detail_screen` movido a `routeFrequencyProvider.family<int?, String>` con 6 tests. `M` · `cerrar` · `ba6cd74`.

---

## Mejora

> Items L (los grandes) más S/M con decisión `posponer`. Se cierran como parte de la feature natural en su fase. Aquí solo se listan para no olvidarlos.

### Pantallas placeholder grandes

- [F44+] **`1.2` — `AiScheduleImport` placeholder.** `L`. Feature post-MVP, post-Play-Store.
- ✅ [F10] **`1.3` — Wizard del editor sin guardar/publicar.** `L`. Cerrado con serialización toJson/fromJson + autosave Hive + validación. `8341490`.
- ✅ [F14] **`1.6a` — `DriverHistoryScreen` placeholder.** `L`. Cerrado con DriverDashboard + live tracking GPS. `a0055dd`.
- [F19] **`1.6b` — `DriverStatsScreen` placeholder.** `L`. Cierra con reputación visible.
- ✅ [F15] **`1.8` — `SuggestionDetailScreen` y `SuggestionContributeScreen` placeholders.** `L`. `SuggestionDetailScreen` rebuit with live data + vote. `SuggestionContributeScreen` pospuesto post-MVP. `252a422`.
- [F19] **`1.10a` — `FilterPresetsScreen` placeholder.** `L`. Necesita reputación + UX avanzada de filtros.
- [F44+] **`1.10b` — `PlannedTripsScreen` placeholder.** `L`. Planificación de viajes — feature post-MVP.
- ✅ [F8] **`1.13` — Zona principal sin handler en `home_tab` / perfil.** `L`. Cerrado con LocationService + currentLocationProvider + city picker + active operator. `75d56cb`.

### Wirings y handlers diferidos

- ✅ [F12] **`1.16c` — Acción "Compartir" en `stop_detail_screen.dart`.** `L`. Cerrado con share sheet + officialize request modal. `d856cfc`.
- ✅ [F15] **`1.16d` — Acción "Mejorar" en `stop_detail_screen.dart`.** `L`. Cerrado con `showRouteFeedbackSheet` → `RouteFeedbackRepository`. `252a422`.
- ✅ [F8] **`1.16e` — Acción "Cómo llegar" en `stop_detail_screen.dart`.** `L`. Cerrado con búsqueda + ruta en F8 (city picker + active operator). `75d56cb`.
- ✅ [F16] **`1.18` — `ManagerInboxScreen` handlers `SnackBar` en `manager_inbox_screen.dart:87-91, :156-160`.** `L`. Cerrado con F16-004 (handlers reales para approve/reject/resolve). `d09706a`.
- ✅ [F9] **`1.19` — `MapTab` filtros + búsqueda inertes en `map_tab.dart:173-183`.** `M` · `posponer`. Cerrado con MapFilterState + filter controller + filter bottom sheet. `2c52f25`.

### Deuda técnica estructural

- ✅ [F1] **`3.1`** — 13 modelos críticos migrados a `freezed` (lote 1: User, Route, Stop, Schedule, Incident, RouteFeedback, RouteSuggestion en `d09852a`; lote 2: ActiveTrip, Operator, UserCard, RouteStop, Zone, Alert en `ddd2156`). 7 modelos nuevos (BusLocation, FeatureRequest, OfflineRegion, RouteShare, DriverInvitationCode, UserPreferences, AppNotification) en `5429f28`. 7 modelos auxiliares se conservan plain-Dart por decisión consciente. `L` · `cerrar` · F1 cerrado.
- [F26] **`3.5` — Huecos de cobertura por feature.** `L`. 0 tests sobre editor de rutas (manual/live/post/AI), realtime trip simulation, `MapDataCache`, `MapTab` con gestos, `RouteDetailScreen`, golden tests. Se aborda feature a feature en F26.

### Riesgos del runtime y empaquetado

- [SIN ASIGNAR] **`3.6.1` — `MockRealtimeService` no pausa los `Timer.periodic` en `AppLifecycleState.paused`.** `M`. CPU/wakelocks pequeños 24/7 mientras la app esté viva en build release. Revisar antes de cualquier release público.
- [F8 / F26] **`3.6.2` — `assets/mock/comujesa_data.json` ~1.2 MB sin minificar en el APK.** `M`. Resuelto naturalmente cuando F8 saque los datos del bundle a Supabase + cache local. Si no, minificar en F26.
- [F17 / F26] **`3.6.3` — `google_fonts` con fetch en runtime.** `M`. Bundle obligatorio antes de release público; bloqueador adicional para golden tests. Cierre natural en F17 (apariencia) o F26 (QA).
- [F26] **`3.6.4` — `SmokeBackground` con `Ticker` permanente.** `S`. Impacto solo en testing (obliga a `disableAnimations: true`). Cierre cosmético en F26.
- ✅ [F9] **`3.6.5` — `_findClosestRoute` sin early return en polylines vacías.** `S`. `map_tab.dart:60-91` no valida `lodData.values.last` no vacío. Cerrado al pasar por F9 (mismo archivo). `2c52f25`.
- ✅ [F26] **`3.6.6` — Sin CI, sin pre-commit, sin format check.** `M`. Cerrado con `.github/workflows/ci.yml`: `flutter analyze` en PR, `flutter test` en push a main/master.

### Modelos huérfanos a evaluar (audit §1.C)

- [F1] **`UserCardModel`, `ZoneModel`, `OperatorModel`, `HabitualTripModel`, `FeedbackMessageModel`, `RouteChangelogModel`** — 6 modelos en `lib/shared/models/` sin un solo consumidor. `RouteChangelogModel` se cierra al resolver `1.15`. El resto: evaluar en F1 si migrar a `freezed` o borrar. Estado actual:
    - ✅ `UserCardModel` — vive tras F4 (auth + perfil).
    - ✅ `ZoneModel`, `OperatorModel` — viven tras F8 (multi-operador + city picker).
    - `HabitualTripModel` → F44+ (planificación).
    - `FeedbackMessageModel` → F15 (threading de feedback).

### F3.2 — Repositorios pendientes (canónico ya en `lib/data/operator/`)

Cada entidad necesita el mismo conjunto de 5 archivos: interfaz abstracta + remoto Supabase + local Hive + mock guest-fallback + provider con stale-while-revalidate. Modelo: `lib/data/operator/`.

- ✅ [F3.2] **Stop** — `nearby(LatLng, radiusM, limit)` vía RPC `nearby_stops`, `byId`, `watch(id)`, `byOperator`. Cache `Box<StopModel>` con clave `stop:<id>`. SWR + mock guest fallback. Cerrado en `b9f9bbc`.
- ✅ [F3.2] **Route** — `byOperator`, `byId`, `watch`, `community(ownerId)`, `intersectingBbox` (RPC `routes_intersecting_bbox` con EWKT POLYGON 4326). RLS filtra visibilidad. Cache `Box<RouteModel>` clave `route:<id>`. SWR + mock guest fallback. Cerrado en `260b02e`.
- ✅ [F3.2] **Schedule** — `forRoute(routeId, dayType)`, `nextDepartures(routeId, n)` (server filtra `departure_time >= now()` + day_type del weekday actual). Cache `Box<ScheduleModel>` clave `schedule:<routeId>:<dayType>:<HH:MM>` para filtrar por prefijo. Cerrado en `e8b42f9`.
- ✅ [F3.2] **BusLocation** — `latestForRoute(routeId)`, `streamForRoute(routeId)` (stub: emite cache + snapshot remoto y cierra; F13 sustituye por suscripción Realtime sobre `public:bus_positions:route_id=eq.<id>`). Cache in-memory con TTL 60s (sin Hive — datos caducan más rápido que cualquier bootstrap). Mock sintetiza posición desde `MockDataService.activeTrips`.
- ✅ [F3.2] **IncidentReport** — `byAuthor(uid)`, `forRoute(routeId)`, `create(IncidentModel)`. Si red falla, `create` encola `PendingAction(kind=createIncident)` y devuelve copia optimista con UUID v4 estable; `core/utils/uuid.dart` genera el id. Provider registra el executor `createIncident` al instanciarse para drenar cuando vuelva la red. Cache `Box<IncidentModel>` (typeId 7) clave `incident:<id>`.
- ✅ [F3.2] **RouteFeedback** — `byAuthor(uid)`, `forRoute(routeId)`, `create(RouteFeedbackModel)` con encolado offline (`PendingActionKind.createRouteFeedback`). Cache `Box<RouteFeedbackModel>` (typeId 8) clave `feedback:<id>`. Mapeo FeedbackType (12) → feedback_kind DB (4) + FeedbackStatus (6) → feedback_status DB (4) en remote impl.
- ✅ [F3.2] **RouteSuggestion** — `list()`, `byId`, `create(...)`, `castVote` (RPC `cast_suggestion_vote`). Encolado offline para `createRouteSuggestion` y `voteSuggestion`. Voto optimista: bump local +1 inmediato; reconcilia con `serverTotal` cuando vuelve (incluso si el server detectó duplicado). Cache `Box<RouteSuggestionModel>` (typeId 9) clave `suggestion:<id>`. Mapeo origin/destination_geom EWKT POINT 4326 + SuggestionStatus (7) → suggestion_status DB (4).
- ✅ [F3.2] **FeatureRequest** — `list()`, `byId`, `create(...)`, `castVote` (RPC `cast_feature_request_vote`). Voto optimista igual que RouteSuggestion. Cache `Box<FeatureRequest>` (typeId 10) clave `featurerequest:<id>`. Cerrado en `e85925f`.
- ✅ [F3.2] **Notification** — `forUser(uid)`, `markRead(id)`, `unreadCount`. Encolado offline para `markNotificationRead`. Cache `Box<AppNotification>` (typeId 11) clave `notif:<uid>:<id>`. Stream con Supabase Realtime cuando F21 se active. Cerrado en `36d890a`.
- ✅ [F3.2] **UserPreferences** — `getMine()`, `update(prefs)`. Encolado offline para `updateUserPrefs`. Cache singleton `user:<uid>:pref` (typeId 4). **Bloquea F4.** Cerrado en `c2d8fe8`.
- ✅ [F3.2] **OfflineRegion** — `forUser(uid)`, `add(region)`, `delete(id)`. **Patrón local-first**: cache primaria local; remoto solo para sincronizar. Cache `Box<OfflineRegion>` (typeId 5) clave `region:<uid>:<id>`. Cerrado en `83d83a1`.

✅ F3.2 cerrada — 12/12 repositorios implementados.

### F3.4 — Migración progresiva de providers

- ✅ [F3.4] **`mapDataCacheProvider`** — Dual-source: repos Hive cuando hay sesión, MockDataService en modo invitado. Cerrado en `9664665`.
- ✅ [F13] **`realtimeTripsProvider`** — Migrado a Supabase Realtime vía `BusLocationRepository` + `bus_estimator`. `51dbdc5`.
- ✅ [F4] **`userProvider`, `isDriverProvider`** — Migrados a `AuthRepository`. `fdf6aeb`.
- ✅ Providers derivados (`stopToRouteCodes`, etc.) se mantienen como están — derivados puros.

### Migraciones programadas (creadas durante F0.5)

- [SIN ASIGNAR] **Migrar `live_recorder_draft` de `shared_preferences` a Hive con cifrado AES.** `M`. Generado por F0.5.C como solución temporal. F3 ya cerrado; esta migración quedó fuera del scope de F3.
- ✅ [F15] **Migrar `local_feedback_drafts` de `shared_preferences` al `RouteFeedbackRepository` real + cola `pending_actions`.** `M`. `FeedbackScreen` ahora hace dual-write: `LocalFeedbackNotifier` + `RouteFeedbackRepository.create()`. `252a422`.

---

## Fases completadas (post F0.5 · sesión mayo 2026)

> Trabajo realizado del 02 al 14 de mayo 2026, documentado en commits `fdf6aeb..e16af43`.

### ✅ F4 — Auth (`fdf6aeb`, `9a0a4ed`, `e414084`)
- `AuthRepository` con errores tipados (`signIn`, `signUp`, `magicLink`, `recover`, `signOut`)
- Pantallas: sign-in, sign-up, magic-link, recover, verify
- Router: rutas auth + redirect guest-mode permisivo
- Perfil: auth-aware (sign out vía AuthRepository, "Iniciar sesión" cuando guest)

### ✅ F5 — Roles (`2ad97ec`)
- `UserRole` enum con `permissions` extension
- `RoleGate` widget para gating condicional
- `currentUserRoleProvider`

### ✅ F6 — Códigos de conductor (`546a320`, `104d9c5`)
- Migración 007: `create_invitation_code` RPC + `revoke_driver`
- Panel `operator_admin` para gestión de códigos
- Pantalla de activación (`claim_invitation_code`) + wiring en perfil

### ✅ F7 — GTFS importer (`4991464`)
- Edge Function `import_gtfs` (TypeScript/Deno)
- Seed operators YAML + migration tools
- 5 operadores seed: COMUJESA, TUSSAM, EMT Madrid, TMB, Bilbobus

### ✅ F8 — Detección geográfica (`75d56cb`)
- `LocationService` con permisos y streaming
- `currentLocationProvider`
- City picker + detección de operador activo vía bbox

### ✅ F9 — Filtros del mapa (`2c52f25`)
- `MapFilterState` con toggle comunitario/oficial, tipo de incidente, etc.
- Filter controller + filter bottom sheet
- Cierra `1.19` + `3.6.5`

### ✅ F10 — Editor (`8341490`)
- Serialización `toJson`/`fromJson` de rutas comunitarias
- Autosave en Hive (`editor_drafts` box)
- Validación en paso review del wizard
- Cierra `1.3`

### ✅ F11 — GPS Live (`1e32386`)
- `LocationService.subscribe` con accuracy filter
- Pause/resume + GPS indicator en UI
- `currentLocationStreamProvider`

### ✅ F12 — Compartir + oficializar (`d856cfc`)
- Share sheet vía `share_plus`
- `RouteOfficializeModal` para solicitar promoción a oficial
- Wiring en route detail + stop detail
- Cierra `1.16c`

### ✅ F13 — Estimación de bus (`51dbdc5`)
- `bus_estimator` pure function: schedule + posición → posición estimada
- `BusOriginLabel` enum (`gtfsRealtime`, `driver`, `estimated`)
- `RouteSource` y `BusPositionSource` enums en modelos
- Cierra providers `realtimeTripsProvider`

### ✅ F14 — Driver en vivo (`a0055dd`)
- `DriverDashboard` con tracking GPS en tiempo real
- `bus_positions` insert cada 5s vía Supabase
- Cierra `1.6a`

### ✅ F15 — Contribuciones consolidadas (completada)
- ✅ Incident report wired a `IncidentRepository` + cola offline (`e16af43`)
- ✅ `SuggestRouteScreen` wired to `RouteSuggestionRepository.create()` (`252a422`)
- ✅ `SuggestionDetailScreen` built with real data + vote via RPC `cast_suggestion_vote` (`252a422`)
- ✅ Acción "Mejorar" en `stop_detail_screen.dart` wired to `showRouteFeedbackSheet` → `RouteFeedbackRepository` (`252a422`)
- ✅ `FeedbackScreen` dual-writes to `LocalFeedbackNotifier` + `RouteFeedbackRepository` (`252a422`)
- ✅ `MyContributionsScreen` rewired: suggestions/feedback/incidents from repos + local drafts (`252a422`)
- ⏸️ `SuggestionContributeScreen` — pospuesto (enriquecimiento de sugerencias post-MVP)
- ⏸️ `FeedbackMessageModel` threading — pospuesto (mensajería gestor↔usuario post-F16)

### ⏳ F16 — Panel admin (en progreso)

#### F16-003 — CRUD de operadores (`852ef25`)

✅ Completado — CRUD de operadores con remote/local/mock repository y admin UI.

#### F16-004 — ManagerInboxScreen handlers reales (`d09706a`)

✅ Completado — Botones de approve/reject/resolve en ManagerInboxScreen con llamadas reales a repositorios y feedback visual.

##### Issues de revisión de código (F16-003)

> Registrados desde el Review Agent. Prioridad: I = importante, M = menor.

- [F16] **I2 — Form missing inline validation.** `lib/features/admin/widgets/operator_form_dialog.dart`. Campos sin validación en tiempo real.
- [F16] **I3 — No unique constraint violation handling.** `lib/data/operator/remote/operator_remote_repository.dart`. Errores de slug duplicado no se capturan con mensaje amigable.
- [F16] **I4 — Row-to-model mapping duplicated.** `operator_remote_repository.dart` y `admin_operators_screen.dart`. Extraer helper compartido.
- [F16] **I5 — Local repo has redundant create/update alongside upsert.** Simplificar API en `lib/data/operator/`.
- [F16] **M1 — Unused `_mockData` field.** `lib/data/operator/local/operator_mock_repository.dart`.
- [F16] **M2 — `shortName` derivation duplicated in 4 places.** Extraer a método helper.
- [F16] **M3 — `phone` field always hardcoded to empty string.** Asignar desde modelo o UI.

##### Issues de revisión de código (F16-004)

> Registrados desde el Tracker Agent. Prioridad: I = importante, M = menor.

- [F22] **I1 — `updateStatus` lacks offline queue.** `manager_inbox_screen.dart`. Los cambios de estado (approve/reject/resolve) no se encolan cuando no hay conexión.
- [F22] **I2 — No loading on status update buttons.** `manager_inbox_screen.dart`. Los botones de cambio de estado no muestran indicador de carga durante la operación.
- [F22] **I3 — Full `_loadData()` after each status update.** `manager_inbox_screen.dart`. Se recargan todos los datos tras cada cambio de estado en lugar de hacer actualización optimista.
- [F22] **M1 — `_feedbackStatusFromString` duplicated.** `manager_inbox_screen.dart`. Método duplicado; extraer a helper compartido en `data/route_feedback/`.
- [F22] **M2 — 3 l10n keys unused.** Claves de localización definidas en ARB pero sin consumidor en la UI.
- [F22] **M3 — `Color.mix` should be in `core/theme`.** Uso de `Color.mix` inline en la UI; mover a helper de tokens de diseño.
- [F22] **M4 — Suggestions tab lacks resolve/reject.** La pestaña de sugerencias en `ManagerInboxScreen` no tiene acciones de resolver/rechazar como feedback e incidents.

---

## Ideas para v3

> Caja vacía para ideas que surjan durante v2 y no encajen en ninguna fase actual del plan. Convención: cada entrada con fecha y una línea de contexto.

<!-- _aún sin entradas_ -->

---

## Notas operativas

- **`1.12` reservado.** Hueco histórico del draft del audit; sin item asignado. No reutilizar la numeración para items nuevos — usar `1.20+`.
- **`3.3` ya limpio.** El lint `avoid_print` (P37) hace su trabajo: cero `print()` en `lib/`. No requiere acción.
- **Cuándo actualizar este documento.** Cada vez que se cierre un item, marca `✅` aquí y en `AUDIT_2026_04.md`. Cada vez que un prompt destape un nuevo pendiente, añádelo con su tag de fase. Al final de cada fase, F0.5 → F26, hacer un barrido y mover lo pospuesto a la siguiente fase relevante.
- **Sincronía con el audit.** Al actualizar items aquí, sincronizar **a la vez** `docs/AUDIT_2026_04.md §4` y `docs/PLAN_TRANSITLY_V2.md` cuando cambie la decisión o el tag de fase. Las tres fuentes deben coincidir; la divergencia produce silenciosamente trabajo perdido.

---

**Última actualización:** 2026-05-15 · F26 en progreso (CI creado, docs TFG actualizados, RELEASE_CHECKLIST creado). F0→F25 completadas (26/28 fases, 92.9%). 137 tests pasando. F27 pendiente (opcional).
