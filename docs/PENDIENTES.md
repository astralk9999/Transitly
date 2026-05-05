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
- [F10] **`1.3` — Wizard del editor sin guardar/publicar.** `L`. Cierra con persistencia real de rutas comunitarias.
- [F14] **`1.6a` — `DriverHistoryScreen` placeholder.** `L`. Cierra con driver real en vivo.
- [F19] **`1.6b` — `DriverStatsScreen` placeholder.** `L`. Cierra con reputación visible.
- [F15] **`1.8` — `SuggestionDetailScreen` y `SuggestionContributeScreen` placeholders.** `L`. Cierran con consolidación de contribuciones.
- [F19] **`1.10a` — `FilterPresetsScreen` placeholder.** `L`. Necesita reputación + UX avanzada de filtros.
- [F44+] **`1.10b` — `PlannedTripsScreen` placeholder.** `L`. Planificación de viajes — feature post-MVP.
- [F8] **`1.13` — Zona principal sin handler en `home_tab` / perfil.** `L`. Cierra con city picker + detección geográfica.

### Wirings y handlers diferidos

- [F12] **`1.16c` — Acción "Compartir" en `stop_detail_screen.dart`.** `L`. Cierra con F12 "Compartir + oficializar".
- [F15] **`1.16d` — Acción "Mejorar" en `stop_detail_screen.dart`.** `L`. Cierra con F15 "Contribuciones consolidadas".
- [F8] **`1.16e` — Acción "Cómo llegar" en `stop_detail_screen.dart`.** `L`. Cierra con búsqueda + ruta en F8.
- [F16] **`1.18` — `ManagerInboxScreen` handlers `SnackBar` en `manager_inbox_screen.dart:87-91, :156-160`.** `L`. Cierra con panel admin (F16).
- [F9] **`1.19` — `MapTab` filtros + búsqueda inertes en `map_tab.dart:173-183`.** `M` · `posponer`. Cierra con filtros del mapa (F9), que ya depende de `RouteRepository` real (F3).

### Deuda técnica estructural

- ✅ [F1] **`3.1`** — 13 modelos críticos migrados a `freezed` (lote 1: User, Route, Stop, Schedule, Incident, RouteFeedback, RouteSuggestion en `d09852a`; lote 2: ActiveTrip, Operator, UserCard, RouteStop, Zone, Alert en `ddd2156`). 7 modelos nuevos (BusLocation, FeatureRequest, OfflineRegion, RouteShare, DriverInvitationCode, UserPreferences, AppNotification) en `5429f28`. 7 modelos auxiliares se conservan plain-Dart por decisión consciente. `L` · `cerrar` · F1 cerrado.
- [F26] **`3.5` — Huecos de cobertura por feature.** `L`. 0 tests sobre editor de rutas (manual/live/post/AI), realtime trip simulation, `MapDataCache`, `MapTab` con gestos, `RouteDetailScreen`, golden tests. Se aborda feature a feature en F26.

### Riesgos del runtime y empaquetado

- [SIN ASIGNAR] **`3.6.1` — `MockRealtimeService` no pausa los `Timer.periodic` en `AppLifecycleState.paused`.** `M`. CPU/wakelocks pequeños 24/7 mientras la app esté viva en build release. Revisar antes de cualquier release público.
- [F8 / F26] **`3.6.2` — `assets/mock/comujesa_data.json` ~1.2 MB sin minificar en el APK.** `M`. Resuelto naturalmente cuando F8 saque los datos del bundle a Supabase + cache local. Si no, minificar en F26.
- [F17 / F26] **`3.6.3` — `google_fonts` con fetch en runtime.** `M`. Bundle obligatorio antes de release público; bloqueador adicional para golden tests. Cierre natural en F17 (apariencia) o F26 (QA).
- [F26] **`3.6.4` — `SmokeBackground` con `Ticker` permanente.** `S`. Impacto solo en testing (obliga a `disableAnimations: true`). Cierre cosmético en F26.
- [F9] **`3.6.5` — `_findClosestRoute` sin early return en polylines vacías.** `S`. `map_tab.dart:60-91` no valida `lodData.values.last` no vacío. Cerrar al pasar por F9 (mismo archivo).
- [F26] **`3.6.6` — Sin CI, sin pre-commit, sin format check.** `M`. `flutter analyze` y `flutter test` se ejecutan a mano. F26 añade GitHub Actions + pre-commit.

### Modelos huérfanos a evaluar (audit §1.C)

- [F1] **`UserCardModel`, `ZoneModel`, `OperatorModel`, `HabitualTripModel`, `FeedbackMessageModel`, `RouteChangelogModel`** — 6 modelos en `lib/shared/models/` sin un solo consumidor. `RouteChangelogModel` se cierra al resolver `1.15`. El resto: evaluar en F1 si migrar a `freezed` o borrar. Probable destino:
    - `UserCardModel` → vivirá tras F4 (auth + perfil).
    - `ZoneModel`, `OperatorModel` → F8 (multi-operador).
    - `HabitualTripModel` → F44+ (planificación).
    - `FeedbackMessageModel` → F15 (threading de feedback).

### Migraciones programadas (creadas durante F0.5)

- [F3] **Migrar `live_recorder_draft` de `shared_preferences` a Hive con cifrado AES.** `M`. Generado por F0.5.C como solución temporal.
- [F15] **Migrar `local_feedback_drafts` de `shared_preferences` al `RouteFeedbackRepository` real + cola `pending_actions`.** `M`. Generado por F0.5.C.

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

**Última actualización:** 2026-05-05 · post F0.5 (A+B+C+D). 15 items cerrados + 2 huérfanos borrados + 1 cierre parcial. F0.5 cerrado completo.
