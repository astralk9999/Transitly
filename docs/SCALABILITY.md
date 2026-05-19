# Transitly — Dossier de escalabilidad (óptica de producción)

> Evaluado como **servicio real para decenas/cientos de miles de usuarios en
> toda España**, no como TFG. Estado: `master @ 6f26725`.
> Severidad = riesgo a escala: 🔴 Crítico · 🟠 Alto · 🟡 Medio.
> Evidencia marcada `[V]` = verificada directamente en esta auditoría;
> `[R]` = verificada en pasadas previas de esta revisión; `[?]` = a confirmar.

## Nota de preparación para producción a escala: **4 / 10**

Arquitectura de capas correcta y disciplinada, pero **diseñada y probada solo
para un operador con datos mock**. Las piezas que definen "escala" (tiempo
real, paginación, multi-tenant, release, observabilidad) están ausentes o son
prototipo.

---

## A. Arquitectura de datos y multi-tenant

- 🔴 **Sin "tiempo real" (F13).** `[R]` 0/12 repos `remote/` con suscripción
  Supabase; `bus_location_remote_repository.dart:34` hace
  `async* { yield await latestForRoute(...); }`. El "bus en vivo" es
  `MockRealtimeService` con `Timer.periodic`. A escala, además, abrir un canal
  Realtime por ruta/usuario sin multiplexar dispara coste y límites de
  conexiones de Supabase. **Recomendación:** suscripción única por
  operador/área con *fan-out* en cliente; backpressure; reconexión con
  jitter.
- 🔴 **Sin paginación.** `[?]` los repos `remote/` y las pantallas de listas
  (rutas, paradas, incidencias, sugerencias) cargan colecciones completas. Con
  10 operadores y miles de paradas/rutas → payloads enormes, OOM en cliente,
  coste de egress. **Recomendación:** `range()`/keyset pagination en todos los
  `select`, listas virtualizadas, prefetch por viewport.
- 🟠 **Multi-operador no demostrable.** Solo COMUJESA mock; los ~9 operadores
  dependen de un Supabase no poblado. No hay partición por `operator_id` en
  caché ni estrategia de *tenant isolation* más allá de RLS.
- 🟠 **Doble modelo de usuario.** `[R]` `currentUserProvider` (mock +
  `StateProvider isDriverMode`) desacoplado de `AuthRepositorySupabase`; el
  guard de rol del router no es fiable. A escala = riesgo de autorización.
- 🟡 **7 modelos manuales fuera de freezed** `[R]` → inconsistencia de
  serialización/igualdad; fricción de mantenimiento al crecer el equipo.

## B. Backend Supabase

- 🟠 **Proyecto único, sin multi-región.** Un solo project-ref; latencia para
  usuarios lejanos; sin DR/HA documentado. Plan free tiene cuotas duras
  (conexiones, Realtime, egress) incompatibles con "toda España".
- 🟠 **Edge Functions best-effort.** `[R]` `send_notification`: rate-limit con
  TOCTOU (no atómico); `import_gtfs`: anti-SSRF best-effort (DNS rebinding
  mitigado parcialmente). Cold starts no medidos. Sin idempotencia fuerte.
- 🟡 **Sin connection pooling explícito** (PgBouncer/`pgbouncer` mode) ni
  límites de concurrencia documentados para los triggers `pg_net`.
- 🟡 **GTFS in-memory.** `[R]` `import_gtfs` parsea ZIP/CSV en memoria con
  tope 50 MB → OOM con feeds reales grandes; sin streaming ni troceado.
- 🟢 **RLS default-deny coherente** `[R]` (punto fuerte); falta FORCE RLS y
  auditoría de accesos `service_role`.

## C. Estado, memoria y rendimiento cliente

- 🟠 **0 `autoDispose`** `[R]` en ~73 providers (streams, futures,
  `.family`). A escala = fugas de memoria y canales/timers vivos tras salir
  de pantalla. **Recomendación:** `autoDispose` selectivo + `keepAlive`
  explícito donde haga falta.
- 🟠 **Mapa sin clustering.** `flutter_map` + `MarkerLayer` con todas las
  paradas/buses → jank y memoria con miles de markers. Falta clustering por
  zoom, `RepaintBoundary` y degradación por LOD.
- 🟡 **`ListView(` no-builder** `[R]` en varias pantallas → materializa listas
  largas de golpe. Migrar a `.builder`/`.separated` + `itemExtent`.
- 🟡 **Sin presupuesto de rendimiento** (no hay perf tests, ni medición de
  TTI/jank/SkSL warmup). Shaders y `SmokeBackground` razonables `[R]`.

## D. Caché y offline a escala

- 🟠 **Hive sin estrategia de tamaño/evicción/cifrado** documentada; con
  multi-operador la caché crece sin límite. `live_recorder_draft` en
  `shared_preferences` sin cifrar `[R]` (datos GPS sensibles).
- 🟡 **Cola offline** `OfflineSyncService` con backoff y dead-letter `[R]`,
  pero sin límites de tamaño de cola ni métricas; con miles de acciones puede
  degradar el arranque.

## E. Release y operación

- 🔴 **APK release firmado con DEBUG keystore.** `[V]`
  `android/app/build.gradle.kts:39` →
  `signingConfig = signingConfigs.getByName("debug")`. **No publicable** en
  Play Store, sin garantías de integridad. Bloqueador absoluto de producción.
  **Recomendación:** keystore real + Play App Signing + secrets en CI.
- 🔴 **`.env` empaquetado como asset** (SEC2) `[R]` (`pubspec.yaml`); claves
  extraíbles del binario. Pasar a `--dart-define`/secret manager.
- 🔴 **PAT de Supabase vivo** (SEC1) `[R]` en `.mcp.json` (alcance de cuenta).
  **Rotar inmediatamente**; no es solo deuda, es exposición activa.
- 🟠 **CI insuficiente.** `[R]` solo `build web`; sin build Android/iOS, sin
  gate de cobertura, sin firma, sin smoke E2E, sin escaneo de dependencias
  (Dependabot/Renovate) ni SAST. `.env` se materializa con
  `cp .env.example .env` (workaround, no fix de SEC2).
- 🟡 **Versionado/observabilidad de releases:** sin changelog automatizado,
  sin feature flags, sin rollout gradual.

## F. Observabilidad

- 🟠 **Sin observabilidad de producto.** Sentry/PostHog con consent-gating
  `[R]` (bien para GDPR) pero **no hay** métricas de negocio, tracing
  distribuido cliente↔Edge↔DB, dashboards, SLO/SLA ni alertas. Sin esto, a
  escala se opera a ciegas.
- 🟡 **Logs no estructurados para agregación** (AppLogger es texto plano);
  falta correlación por request/usuario (con PII fuera, ya respetado `[R]`).

## G. Dependencias y evolución

- 🟡 **Pins regresivos.** `[R]` `flutter_riverpod`/`riverpod` fijados 2.6.1,
  `sentry_flutter` 8.14.2 — congela migraciones futuras (riverpod 3, sentry 9)
  y acumula deuda. Documentar plan de actualización.
- 🟢 Stack modernizado parcialmente (freezed 3, go_router 17) `[R]` — buen
  paso; mantener cadencia con Dependabot.

---

## Top-10 bloqueadores de escalabilidad (priorizados)

1. 🔴 F13 Realtime real (multiplexado, con backpressure).
2. 🔴 Paginación/keyset en todos los `remote/` + listas virtualizadas.
3. 🔴 Firma de release real (keystore + Play App Signing + CI secrets).
4. 🔴 SEC2 (`.env`→`--dart-define`) y SEC1 (rotar PAT).
5. 🟠 `autoDispose` selectivo (fugas de memoria/streams).
6. 🟠 Clustering + `RepaintBoundary` en el mapa.
7. 🟠 Unificar modelo de usuario (rol fiable server-side).
8. 🟠 Observabilidad: SLO, tracing, alertas, métricas de negocio.
9. 🟠 CI producción: build móvil, gate de cobertura, SAST, Dependabot.
10. 🟡 Estrategia de caché/tenant (tamaño, evicción, cifrado, partición por operador).

> Estos ítems se incorporan al plan como bloque **PROD** en
> `docs/PLAN_ACCION_REMEDIACION.md`.
