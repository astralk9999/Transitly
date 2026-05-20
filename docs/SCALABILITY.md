# Transitly — Dossier de escalabilidad (óptica de producción)

> Evaluado como **servicio real para decenas/cientos de miles de usuarios
> en toda España**, no como TFG. Estado: `master @ 3a31fb3`.
> Severidad = riesgo a escala: 🔴 Crítico · 🟠 Alto · 🟡 Medio.
> Notación: ✅ cerrado · ⚠️ avanzado/parcial · ❌ pendiente.

## Nota de preparación para producción a escala: **6 / 10**

> Sube desde 4/10 del dossier anterior. La arquitectura ha pasado de
> "prototipo demostrable de operador único" a "MVP con capa de tiempo
> real funcional, modelo de usuario unificado y release verificable". Lo
> que sigue impidiendo el 8+ son piezas de operabilidad real
> (observabilidad, firma, multi-tenant, mapa a escala) que ningún ciclo
> documental cierra.

---

## A. Arquitectura de datos y multi-tenant

- ✅ **F13 Realtime en repos críticos.** `lib/data/sync/realtime_channel_manager.dart`
  multiplexa canales Supabase con backoff exponencial + jitter, usado por
  `stop`, `route`, `incident`, `route_feedback`. `bus_location` mantiene
  `bus_position_channel_manager.dart` dedicado (filtro por `route_id`).
  **5/12 repos** con `Stream` real; los 7 restantes deciden caso a caso si
  necesitan vivo o snapshot.
- ✅ **Paginación completa en 11/11 repos de lista**: todos los
  `remote/*_repository.dart` que devuelven colecciones aceptan `offset`/
  `limit` y aplican `range(offset, offset+limit-1)`. `user_preferences`
  queda fuera por diseño (objeto singular por usuario, no colección).
- ✅ **Modelo de usuario unificado.** `currentUserProvider` ahora deriva
  de `userProfileFromSupabaseProvider` (lectura de `profiles.role` con
  `.maybeSingle()` y manejo de `PostgrestException`) con fallback gradual
  al mock para guest. El guard del router consume el rol **real**, no el
  derivado de un `StateProvider isDriverMode`. El control de acceso por
  rol pasa a ser fiable server-side.
- 🟠 **Multi-operador limitado.** Solo COMUJESA poblado en mock; los ~9
  operadores adicionales dependen de un Supabase no rellenado. La
  partición por `operator_id` en caché Hive **no existe**: una sesión que
  cambia de operador puede dejar datos cruzados en el storage local.
- 🟡 **7 repos sin Realtime aún:** `route_suggestion`, `feature_request`,
  `operator`, `schedule`, `user_preferences`, `offline_region`,
  `notification` (Realtime fuera del repo, en
  `notification_stream_provider`). Decidir cuáles necesitan vivo.

## B. Backend Supabase

- ✅ **RLS default-deny coherente** (verificado en ciclos previos);
  `search_path` fijado en todas las `SECURITY DEFINER`.
- 🟠 **Proyecto único, sin multi-región.** Un solo project-ref;
  latencia para usuarios lejanos; sin DR/HA documentado.
- 🟠 **Edge Functions: anti-SSRF y rate-limit best-effort.**
  `import_gtfs` valida hostname textual + DNS A/AAAA (mitiga rebinding
  parcialmente) + `redirect:"manual"`; rate-limit en `send_notification`
  con TOCTOU (documentado como deuda conocida) + fail-closed si el INSERT
  falla. Cold starts no medidos.
- 🟡 **Sin FORCE RLS ni auditoría de accesos `service_role`.** Cualquier
  bug en una Edge con `service_role` implica acceso total.
- 🟡 **Sin connection pooling explícito** (PgBouncer/`pgbouncer` mode) ni
  límites de concurrencia documentados para los triggers `pg_net`.
- 🟡 **GTFS in-memory.** `import_gtfs` parsea ZIP/CSV en memoria con tope
  50 MB → OOM con feeds reales grandes. Sin streaming.

## C. Estado, memoria y rendimiento cliente

- ⚠️ **`autoDispose` parcial (6 providers cerrados):** `home_providers`,
  `nfc_provider`, `notificationStreamProvider` (cierra canal Supabase via
  `ref.onDispose` al detach), `realtimeTripsProvider`,
  `realtimeClockProvider`, `privacyConsentsProvider`. **Pendiente sweep
  en providers `.family`** (no acumular instancias por parámetro).
- ✅ **`MockRealtimeService` reacciona al lifecycle** del SO:
  `WidgetsBindingObserver` cableado en `main.dart:154-173`;
  `Timer.periodic` se pausa en `AppLifecycleState.paused` y reanuda en
  `resumed`.
- 🟠 **Mapa sin clustering.** `flutter_map` + `MarkerLayer` con todas las
  paradas/buses → jank y memoria con miles de markers. Falta clustering
  por zoom, `RepaintBoundary` aislando el mapa del shader de fondo, y LOD
  por zoom.
- 🟡 **`ListView(` no-builder** en pocas pantallas restantes; migrar a
  `.builder` con `itemExtent`.
- 🟡 **Sin presupuesto de rendimiento** (no hay perf tests, ni medición
  de TTI/jank/SkSL warmup).

## D. Caché y offline a escala

- 🟠 **Hive sin estrategia de tamaño/evicción/cifrado** documentada;
  con multi-operador la caché crece sin límite. `live_recorder_draft` en
  `shared_preferences` sin cifrar (datos GPS sensibles).
- 🟡 **Cola offline** `OfflineSyncService` con backoff y dead-letter, pero
  sin límites de tamaño de cola ni métricas; con miles de acciones puede
  degradar el arranque.
- ✅ **Resilencia de Realtime:** `RealtimeChannelManager` aplica backoff
  exponencial con jitter en reconexión, evita avalancha al volver online.

## E. Release y operación

- ✅ **Build APK release funcional.** `build.gradle.kts` distingue
  release/debug correctamente (Kotlin DSL puro: `if-else` expression);
  `flutter build apk --release` produce `app-release.apk` 73,5 MB.
- ✅ **SEC2 cerrado.** `Env` lee `String.fromEnvironment`
  (`--dart-define`); `.env` ya no se bundlea como asset.
- ✅ **Core library desugaring** habilitado para
  `flutter_local_notifications`.
- 🔴 **Keystore real ausente** (`android/key.properties` no existe). El
  APK release se firma con la keystore de **debug** → **no publicable en
  Play Store**. Único bloqueador absoluto de release. Pasos en
  `android/README.md` + `docs/PENDIENTE_PARA_CERRAR.md §1.1`.
- 🟠 **CI parcial pero ya con Android.** 4 jobs verdes (Analyze, Test,
  Build Web, **Build Android APK firmado**). Faltan: build iOS firmado,
  gate de cobertura con umbral, SAST/dependency scan, Dependabot/Renovate,
  smoke E2E. Detalle en `android/README.md` para secrets de keystore.
- ✅ **Stack modernizado:** freezed 2→3, go_router 14→17, json_serializable
  6.8→6.14. Resolución y codegen estables.
- 🟡 **Pins regresivos** `flutter_riverpod`/`riverpod` 2.6.1 y
  `sentry_flutter` 8.14.2 — congela migraciones futuras (riverpod 3,
  sentry 9). Documentado como deuda consciente.

## F. Observabilidad

- ✅ **Consent-gating de telemetría real.** PostHog arranca con
  `optOut=true`; `analyticsServiceProvider` default-deny, exige
  consentimiento explícito. Sentry no se inicializa para invitados.
  Revocación efectiva en caliente (llama `Posthog().disable()` y
  `SentrySetup.close()` al revocar).
- 🟠 **Sin observabilidad de producto.** No hay métricas de negocio
  (acciones por usuario, viajes, conversión), no hay tracing distribuido
  cliente↔Edge↔DB, no hay dashboards de SLO/SLA, no hay alertas. A escala
  se opera a ciegas.
- 🟡 **Logs no estructurados para agregación** (AppLogger es texto plano).
  Buena disciplina de PII (UUID truncado en auth), falta correlación por
  request/usuario.

## G. Dependencias y evolución

- ✅ Stack puesto al día (freezed 3, go_router 17). Workmanager eliminado
  como dependencia muerta. `flutter_dotenv` eliminado tras SEC2.
- 🟡 Sin Dependabot/Renovate ni gate de actualización. Pins regresivos a
  documentar plan de upgrade.

---

## Top-10 bloqueadores de escalabilidad (priorizados)

1. 🔴 **Keystore real + Play App Signing** (15 min, manual del usuario).
   Desbloquea release publicable.
2. 🟠 **Observabilidad mínima**: SLO + alertas + tracing cliente↔Edge↔DB.
3. 🟠 **Mapa a escala**: clustering por zoom, `RepaintBoundary`, LOD.
4. 🟠 **autoDispose `.family` sweep** + auditoría caso a caso.
5. 🟠 **Tests de la capa `remote/`** (auth_supabase, stop, route,
   bus_location, etc.) con mocks de `SupabaseClient` → habilita gate de
   cobertura en CI.
6. 🟠 **CI producción**: build iOS firmado, gate de cobertura, SAST,
   Dependabot/Renovate, smoke E2E.
7. 🟠 **Caché/tenant a escala**: tamaño/evicción/cifrado Hive; partición
   por `operator_id`; cifrar `live_recorder_draft`.
8. 🟠 **Backend a escala**: FORCE RLS + auditoría, connection pooling,
   idempotencia Edge, GTFS streaming, plan no-free / multi-región.
9. 🟡 **F13 Realtime en repos secundarios** según necesidad real.
10. 🟡 **Migración futura** riverpod 3 / sentry 9.

Detalle accionable y orden en `docs/PLAN_ACCION_REMEDIACION.md` (bloques
PROD/A11Y/P1-P3) y `docs/PENDIENTE_PARA_CERRAR.md` (playbook táctico).
