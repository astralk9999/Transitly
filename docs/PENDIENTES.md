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

> Se cierran en F0.5. Esfuerzo total ≈ 1 día (7×S + 4×M en serie). Orden recomendado: F0.5.A → F0.5.B → F0.5.C.

### F0.5.A — Routing y wirings huérfanos

- [F0.5.A] **`1.17` — Bug de routing en `driver_panel.dart:72`.** `S` · `cerrar`. "Bandeja de gestión" enlaza a `/driver/stats`; debe ir a `/management/inbox`.
- [F0.5.A] **`1.5` — `onTap: () {}` "Elegir otra" en `start_route_screen.dart:111`.** `S` · `cerrar`. Sustituir por `ScrollController.ensureVisible` hacia la lista de rutas disponibles del mismo screen.
- [F0.5.A] **`1.7` — `SearchResultsScreen` placeholder + huérfana.** `S` · `borrar`. Eliminar archivo y ruta `/search/results`. Verificar `flutter analyze` limpio.
- [F0.5.A] **`1.11` — `onTap: () {}` "Cerrar sesión" en `profile_about_section.dart:69-73`.** `S` · `cerrar`. Abrir `AlertDialog` "¿Cerrar sesión?"; en OK, `SnackBar` "Sesión cerrada (demo)" hasta que F4 lo reemplace por `authRepository.signOut()`.
- [F0.5.A] **`1.14` — Botón "INCIDENCIA" en `active_route_screen.dart:243-247` solo lanza `SnackBar`.** `S` · `cerrar`. Sustituir por `showReportIncidentSheet` con contexto del trip activo (`route_id`, `stop_id` si aplica).
- [F0.5.A] **`1.15` — Changelog hardcoded en `route_detail_changelog.dart` (3 entradas literales).** `S` · `cerrar`. Consumir `RouteChangelogModel` desde provider del route detail (existe o derivar de `mapDataCacheProvider`).
- [F0.5.A] **`1.16` — Acción "Reportar" inerte en `stop_detail_screen.dart:270-273`.** `S` · `cerrar` parcial. Solo la primera de las cuatro acciones; cablear a `showReportIncidentSheet` con `stop_id` precargado. Las otras tres → bloque "Mejora".
- [F0.5.A] **`1.1` — `ScheduleEditor` placeholder solapando `StepSchedules`.** `S` · `borrar`. Eliminar archivo `lib/features/driver/route_editor/schedule_editor.dart` y ruta `/driver/editor/schedule`.
- [F0.5.A] **Wiring olvidado de `OfflineDataScreen`** *(detectado en `AUDIT §2.6`)*. `S` · `cerrar`. P40 cerró el contenido pero olvidó el `context.push` en `ProfileTab` u origen equivalente. Añadir entry-point.

### F0.5.B — Calidad estructural

- [F0.5.B] **`3.2` — `MockDataException` tipada.** `M` · `cerrar`. Crear `enum MockDataError { assetNotFound, parseError, unexpectedSchema, unknown }` + `class MockDataException implements Exception` siguiendo patrón `NfcCardError` documentado en `ARCHITECTURE.md §4.3`. Tests negativos con asset bundle mock.
- [F0.5.B] **`3.4` — Lógica de negocio en 5 widgets.** `M` · `cerrar`. Mover a providers derivados en `lib/shared/providers/derived/`:
    - `home_tab.dart:54-80` → `homeFavRouteIdsProvider`, `homeHabitualStopProvider`, `homeNearbyStopsProvider.family<LatLng>`, `homeFavAlertsProvider`.
    - `home_tab.dart:264-274` y `stop_detail_screen.dart:35-40` → reutilizar `stopToRouteCodesProvider` (ya existente) o crear selector encima.
    - `start_route_screen.dart:44-60` → `upcomingDeparturesForRouteProvider.family<RouteId>`.
    - `active_route_screen.dart:32-78` → `activeTripDetailProvider.family<TripId, ActiveTripDetail>` con value object inmutable.
    - `route_detail_screen.dart:34-43` → `routeFrequencyProvider.family<RouteId>` con cálculo de frecuencia (map + sort + fold).
    - Cada provider con test unitario `ProviderContainer` (vacío / normal / edge).

### F0.5.C — Cierre de flujos para demo continua

- [F0.5.C] **`1.4` — Post-recording editor con `_trace` y 5 paradas hardcoded.** `M` · `cerrar`. `post_recording_editor.dart`: eliminar `const _trace` y stops literales (líneas 23-35, 44-50). Recibir `final List<LatLng> trace` y `final List<RecordedStop> stops` por constructor desde `LiveRecorderController.getCurrentSession() → RecordedSession`. Persistir vía `shared_preferences` con clave `live_recorder_draft:<userId-or-guest>` hasta F3 (Hive).
- [F0.5.C] **`1.9` — Categorías de feedback inertes en `feedback_screen.dart:126-130`.** `M` · `cerrar`. Cada categoría abre el flujo correspondiente (sheet/pantalla) en lugar de `SnackBar 'próximamente'`. Persistencia local en `LocalFeedbackNotifier` nuevo (`shared/providers/local_feedback_provider.dart`) con `shared_preferences` (`local_feedback_drafts`). `MyContributions` se hidrata desde aquí.
- [F0.5.C] **`feedback_detail_screen.dart` huérfana.** `S` · `borrar`. Eliminar archivo y ruta `/feedback/detail` durante el cierre de C2.

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

- [F1] **`3.1` — 22 modelos plain-Dart sin `==` ni `hashCode`.** `L`. Migración selectiva a `freezed` priorizando `RouteModel`, `StopModel`, `ScheduleModel`, `IncidentModel`, `RouteFeedbackModel`, `RouteSuggestionModel`, `UserModel`, `ActiveTripModel`. Resto puede esperar.
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

**Última actualización:** 2026-05-02 · sincronizado con `AUDIT_2026_04.md` (items 1.1-1.19, 3.1-3.5, 3.6.1-3.6.6 + 6 huérfanos + 1 wiring olvidado).
