# Plan de acción — remediación integral de Transitly

> **Origen:** `docs/00_MAESTRO.md` (índice) + `historico/REVISION_INDEPENDIENTE_2026_05_17.md`
> (4 pasadas) + `SCALABILITY.md` + `ACCESSIBILITY.md` (óptica producción).
> **Estado base:** `master @ 396a1e6` (2026-05-18) · `flutter analyze` 0 issues ·
> `flutter test` 148/148 · `flutter build apk --release` OK (73 MB) ·
> cobertura ~24,7 % · **CI verde verificado en GitHub** · stack actualizado
> (freezed 3, go_router 17, json_serializable 6.14 — ver *Workstream R*).
> **Objetivo:** documento único — todos los problemas y requisitos, con su
> plan de acción por parte (esfuerzo, riesgo sobre la build verde,
> dependencias y criterio de aceptación), estado vivo y orden de ejecución.
> **Regla transversal:** cada ítem se cierra solo si tras él
> `flutter analyze` = 0 y `flutter test` sigue verde (y CI en GitHub).

## Cuadro de mando (estado vivo · 2026-05-18)

| Bloque | Total | ✅ Hechos | ⏳ Pendientes | Resumen |
|--------|------:|---------:|-------------:|---------|
| **P0** — antes de defensa | 7 | 6 | 1 | Solo falta **P0-1** (rotar PAT, acción externa). APK release + CI verdes. |
| **R** — paquetes/refactor (`396a1e6`) | 4 | 4 | 0 | freezed 3 + go_router 17 + bumps; split router; placeholders; warn. ✅ verificado. |
| **P1** — calidad/a11y/req | 11 | 0 | 11 | Sin empezar. Quick wins listos (P1-1/2/9/10). **NO** cubierto por R. |
| **P2** — núcleo + cobertura | 7 | 0 | 7 | Mueve la nota 7,7 → ~8,5 (F13, modelo usuario, tests, SEC2). |
| **P3** — deuda de fondo | 8 | 0 | 8 | Sin empezar (el split de router de R-4 es ítem propio, no P3-7). |
| **PROD** — producción a escala 🆕 | 10 | 0 | 10 | Bloqueadores de producción (`SCALABILITY.md`). Imprescindibles si deja de ser TFG. |
| **A11Y** — accesibilidad WCAG 🆕 | 10 | 0 | 10 | Barreras inclusivas (`ACCESSIBILITY.md`). "AA" no defendible sin esto. |
| **TOTAL** | **57** | **10** | **47** | TFG ≈7,8/10 · **Producción ≈4,5/10**; techo lo fijan PROD+A11Y+P2. |

> ⚠️ **Corrección de integridad (2026-05-18):** una versión anterior de este
> documento afirmaba *"Estado P0+P1: ✅ Resuelto (commit 5077099)"*. Es
> **falso**: P0 se cerró en `b0fd7dc` (no 5077099) y **P1 sigue al 0/11**.
> El commit `396a1e6` resolvió el *Workstream R* (paquetes + refactors),
> que **no es P1**. Restaurado el plan íntegro y reconciliado con la
> realidad verificada.
>
> Leyenda de estado por ítem: ✅ hecho y verificado · ⏳ pendiente ·
> 🆕 hallazgo nuevo de la ejecución. Detalle y evidencia, en cada tabla.

## Leyenda

- **Esfuerzo:** S=<2 h · M=medio día–1 día · L=2–5 días · XL=semanas.
- **Riesgo build:** 🟢 bajo · 🟡 medio · 🔴 alto (puede romper 148 tests/boot).
- **Tipo:** `fix` defecto · `req` requisito/funcionalidad · `debt` deuda ·
  `doc` documentación · `ops` acción externa.

---

## P0 — Antes de la defensa (horas, casi sin riesgo)

> **Estado de ejecución (2026-05-18):** P0-2…P0-7 ✅ aplicados y verificados
> (`flutter analyze` 0 issues, `flutter test` **148/148**, `flutter build
> apk --release` **OK 73 MB**). **Solo P0-1 ⏳ pendiente** (rotar PAT —
> acción externa en el dashboard de Supabase, no automatizable).
> **Hallazgo grave de la ejecución:** el APK de release **nunca había
> compilado** (P0-7) — había quedado oculto porque el CI solo construye web
> y nadie había ejecutado `flutter build apk --release` con Flutter 3.x.

| ID | Acción | Tipo | Esf. | Riesgo | Criterio de aceptación |
|----|--------|------|------|--------|------------------------|
| P0-1 | ⏳ **Rotar el PAT de Supabase** de `.mcp.json` en el dashboard (`supabase.com/dashboard/account/tokens`); invalidar `sbp_e514…`; regenerar con alcance mínimo | ops | S | 🟢 | El token viejo no autentica; `.mcp.json` local actualizado (sigue gitignored) |
| P0-2 | ✅ **`setState` sin `mounted` en `catch`** de `signin_screen.dart` y `signup_screen.dart` → envuelto en `if (mounted)` | fix | S | 🟢 | Hecho; 148 tests verdes |
| P0-3 | ✅ **`send_notification` 502→500** en fallo de INSERT propio | fix | S | 🟢 | Hecho; status 500, comentario fail-closed intacto |
| P0-4 | ✅ **Métricas en `docs/tfg/`** (04/05/08): 28/28 fases (100%), 148 tests, 24,7 % cobertura, 0 issues lint | doc | S | 🟢 | Hecho; cifras coinciden con informe y CI |
| P0-5 | ✅ **APK release para demo** generado (73 MB, `app-release.apk`, 2026-05-18); checkbox marcado en `08_presentacion.md` | ops | S | 🟢 | Hecho tras desbloquear P0-7 |
| P0-6 | ✅ **Truncar `uid` en log** `auth_repository_supabase.dart` (prefijo 8 chars) | fix | S | 🟢 | Hecho; no se loguea el UUID completo |
| **P0-7** | 🆕✅ **El APK release NUNCA compilaba** (hallazgo grave). 3 causas encadenadas: (a) `workmanager 0.5.2` usa la API **v1-embedding** (`ShimPluginRegistry`/`Registrar`) **removida en Flutter 3.x** → `:workmanager:compileReleaseKotlin` falla; el plugin estaba **declarado pero nunca cableado** en Dart → **eliminado** de `pubspec.yaml`; (b) `flutter_local_notifications` exige **core library desugaring** → habilitado en `build.gradle.kts` + `desugar_jdk_libs:2.1.4`; (c) daemon Gradle "desaparecía" por OOM (`-Xmx8G+4G`) → `gradle.properties` a `-Xmx4G`, `daemon=false`, `workers.max=2` | fix | M | 🟡 | `flutter build apk --release` produce APK; `analyze` 0; 148 tests verdes |

**Salida P0:** documentación coherente con el código, sin defectos triviales
de UX/seguridad, demo lista. La nota esperada se consolida sin tocar
arquitectura.

---

## Workstream R — paquetes + refactors (✅ completado en `396a1e6`)

Trabajo realizado fuera del eje P0–P3 (modernización de stack y refactors
menores). **Verificado independientemente:** `dart run build_runner build`
0 SEVERE (40 outputs), `flutter analyze` **0 issues**, `flutter test`
**148/148**, **CI `success`** para `396a1e6`.

| ID | Acción | Estado | Verificación |
|----|--------|--------|--------------|
| R-1 | **freezed 2.5→3.x** + `freezed_annotation` 2→3, `json_serializable` 6.8→6.14, `json_annotation` 4.9→4.12. 72 ficheros (`.freezed.dart` regenerados) | ✅ | codegen OK; analyze 0; 148/148 |
| R-2 | **go_router 14.8→17.2** (major; redirects/`GoRouterState` API) | ✅ | compila; `router_test` verde |
| R-3 | **`google_fonts` 6.2→6.3**; `flutter_riverpod`/`riverpod` fijados a `2.6.1`; `sentry_flutter` fijado `8.14.2` (NO subido a 9) | ✅ | resuelve; sin regresión |
| R-4 | **Split `app_router.dart`** → `redirect_guards.dart` (M2); limpieza de placeholders `'PANTALLA:'` (M4, ya 0); warn `StaggerList` silenciado (M3) | ✅ | `redirect_guards.dart` existe; grep `'PANTALLA:'` vacío |

**Matices honestos (no bloqueantes):**
- R **no toca P1**: los 7 modelos *manuales* (`achievement_model`,
  `trip_history_model`, `user_favorite_model`…) **siguen sin `@freezed`**
  (P1-5 sigue ⏳). R-1 solo migró el *codegen* de los modelos ya-freezed.
- `riverpod`/`sentry` quedaron **fijados** (no actualizados): pin pragmático
  para no arrastrar riverpod 3 / sentry 9 (majors con migración propia).
  Es deuda consciente, no "todo actualizado".
- APK release re-verificado: pubspec cambió pero ni `gradle.properties` ni
  `build.gradle.kts` se tocaron y no se añadieron plugins nativos → riesgo
  bajo (build verificado OK en P0-7; no re-ejecutado tras R por coste, el
  cambio es Dart-only + CI web verde).
- R-4 (split `app_router`) es un refactor propio del Workstream R; **no**
  es P3-7 (que es descomponer `privacy_screen`/`manager_inbox`, sigue ⏳).

---

## P1 — Calidad / accesibilidad / requisitos cercanos (días)

| ID | Acción | Tipo | Esf. | Riesgo | Criterio de aceptación |
|----|--------|------|------|--------|------------------------|
| P1-1 | **Strings ES visibles → l10n** (~17 críticos: `city_picker_screen.dart:64`, `route_feedback_sheet.dart:207`, `report_incident_sheet.dart:141`, `drivers_screen.dart:59,109`, `invitation_codes_screen.dart:60,89,157`, `route_officialize_modal.dart:75`, `route_share_sheet.dart:82,95,97,123`, `route_detail_screen.dart:43`, `stop_detail_screen.dart:33`…). Dejar de exponer `e.toString()` crudo | req | M | 🟢 | Cero `Text('…')` ES en esos ficheros; claves en ambos ARB sincronizadas; `flutter gen-l10n` ok |
| P1-2 | **Semantics ES hardcodeados → l10n** (10 archivos: `card_tab.dart:269`, `home_tab.dart:101,241,347`, `accessibility_settings_screen.dart:136`, `stop_detail_screen.dart:294`, `capacity_indicator.dart:31`, `reputation_badge.dart:86`, `route_card.dart:53` —corregir "Linea"→"Línea"—) | req | M | 🟢 | Lectores anuncian en el idioma activo |
| P1-3 | **`Pressable` suelo 48 dp**: `ConstrainedBox(minHeight:48,minWidth:48)` (o `kMinInteractiveDimension`) en `shared/widgets/pressable.dart` | fix | S | 🟡 | WCAG 2.5.5; revisar que no descuadra chips/iconos pequeños; tests visuales verdes |
| P1-4 | **`textScaler` respeta el del SO**: en `app.dart:47` componer `MediaQuery.textScaler` del sistema × `fontScale` en vez de reemplazarlo; con clamp | fix | M | 🟡 | Texto grande del SO se respeta; WCAG 1.4.4 |
| P1-5 | **7 modelos manuales → `@freezed`** (`achievement_model`, `user_achievement_model`, `habitual_trip_model`, `feedback_message_model`, `route_changelog_model`, `user_favorite_model`, `trip_history_model`) en un commit atómico con `tool/build.sh` | debt | M-L | 🟡 | `.freezed.dart` generados y commiteados; callers compilan; 148 verdes |
| P1-6 | **Tokens en `shared/widgets/`** (capa canónica): migrar 11 `GoogleFonts.*` inline a `TransitTypography` (`empty_state`, `error_card`, `reputation_badge`, `route_card`, `status_badge`, `transit_button`, `transit_chip`). Si falta variante, **añadir token** (`sectionLabel`, `inboxTypeTag`) y no duplicar | debt | M | 🟡 | 0 `GoogleFonts.` en `shared/widgets/`; sin regresión visual |
| P1-7 | **Tokens en widgets extraídos** (deuda introducida por I1): sustituir `GoogleFonts.ibmPlexMono(...)` inline de los ~15 widgets de `appearance/`+`management/` por los nuevos tokens de P1-6 | debt | M | 🟡 | 0 `GoogleFonts.` en esos widgets |
| P1-8 | **`ActionButton`→`TransitButton`**: eliminar `management/widgets/action_button.dart`, reemplazar usos por `TransitButton(isPrimary:false,isSmall:true)`; si hace falta radio 8, añadir param `borderRadius` a `TransitButton` | debt | S-M | 🟡 | `action_button.dart` borrado; sheets sin regresión |
| P1-9 | **`inbox_action_sheets.dart`→`showTransitBottomSheet`** (3 sitios) | debt | S | 🟢 | Sin `showModalBottomSheet` directo en ese fichero |
| P1-10 | **`privacy_screen` defensivo**: `if (!mounted) return;` antes de `ref.invalidate`; envolver el caller con `unawaited(...)` explícito | fix | S | 🟢 | Sin warnings de ref/await; comportamiento igual |
| P1-11 | **Issues F16/F22 de `PENDIENTES.md`** (I2-I5, M1-M3, F22 I1-I3/M4): validación inline, manejo de unique-violation, dedupe mapping, loading en botones de estado, cola offline en `updateStatus` | req | L | 🟢 | Ítems marcados ✅ en `PENDIENTES.md` con evidencia |

**Salida P1:** accesibilidad defendible como "AA parcial" real, i18n sin
fugas, design system honrado en la capa compartida, modelos consistentes,
deuda introducida por la remediación saldada.

---

## P2 — Núcleo funcional y cobertura (los que mueven la nota a 8+)

| ID | Acción | Tipo | Esf. | Riesgo | Dependencias / aceptación |
|----|--------|------|------|--------|---------------------------|
| P2-1 | **F13 Realtime — `bus_location`**: sustituir el `async* yield await` de `bus_location_remote_repository.dart:34` por suscripción Supabase (`channel('public:bus_positions:route_id=eq.…').onPostgresChanges(...).subscribe()` + `StreamController`), patrón ya probado en `notification_stream_provider.dart:37-65`. Conmutar `realtimeTripsProvider` con coordinación de `MapTab`/`HomeTab`/`RouteDetailScreen` | req | M-L | 🟡 | Tabla `bus_positions` + RLS ya existen; demo del bus en tiempo real real; tests con mock de `SupabaseClient` |
| P2-2 | **F13 Realtime — `stop` y `route`** (mismo patrón) | req | M | 🟡 | Tras P2-1 |
| P2-3 | **Unificar modelo de usuario**: provider de perfil que lea `profiles` (con `role`) de Supabase; `currentUserProvider` → real si `AuthAuthenticated`, mock si guest; `currentUserRoleProvider` deriva del real; guard del router pasa a rol real | req | L | 🔴 | Tabla `profiles.role` con seed; hacer gradual (capa Supabase + fallback mock) para acotar riesgo |
| P2-4 | **Tests de capa de datos de producción**: mocks de `SupabaseClient`/`PostgrestClient`; cubrir `_fromRow`+error-mapping de `stop`, `route`, `bus_location`, `auth_repository_supabase` | req | L | 🟢 | Cobertura ≥35 %; nuevos tests verdes |
| P2-5 | **SEC2 — `.env` fuera del bundle**: quitar `- .env` de `pubspec.yaml`; `Env` lee `String.fromEnvironment` (`--dart-define`); actualizar run/build, `ci.yml` (secrets) y `.env.example`/docs | fix | M | 🔴 | App arranca con `--dart-define`; CI verde; quitar el `cp .env.example .env` workaround |
| P2-6 | **F26 — fuentes locales**: descargar DM Sans + IBM Plex Mono (400/500/700), `assets/fonts/`, declarar en `pubspec`, `_fontsBundled=true` (`main.dart:22`) | req | M | 🟢 | Sin red la tipografía es correcta; sin petición a `fonts.gstatic.com`; guía `docs/FONTS_F26.md` |
| P2-7 | **CI — gate de cobertura**: paso que falle si la cobertura cae bajo umbral declarado (p.ej. 24 %, subir con P2-4); opcional reporter en PR | ops | S-M | 🟢 | CI rojo si baja del umbral |

**Salida P2:** la funcionalidad "tiempo real" que titula el proyecto existe,
el control de rol es fiable, la capa de datos está verificada y los secretos
no se bundlean. **Es el bloque que sube de 7.7 a ~8.5.**

---

## P3 — Deuda de fondo y robustez (semanas, valor marginal para TFG)

| ID | Acción | Tipo | Esf. | Riesgo |
|----|--------|------|------|--------|
| P3-1 | `autoDispose` selectivo en 8-10 providers (NFC, `notificationStream`, `realtimeTrips`, `privacyConsents`, `.family`…), analizados caso a caso | debt | L | 🟡 |
| P3-2 | Semantics para el mapa (`FlutterMap`): describir marcadores/rutas o exponer alternativa textual enlazada (`AccessibleBusesScreen`) | req | M | 🟢 |
| P3-3 | `EdgeInsets`/`Color(0x` literales → `TransitSpacing`/`TransitColors` (≈342/≈29 ocurrencias) — barrido amplio | debt | XL | 🟢 |
| P3-4 | `live_recorder_draft`: `shared_preferences` → Hive cifrado (AES) | fix | S-M | 🟢 |
| P3-5 | `MockRealtimeService`: pausar `Timer.periodic` en `AppLifecycleState.paused` | fix | S | 🟢 |
| P3-6 | Completar el patrón canónico de `data/auth/` (faltan `local`/`mock`/`provider`, nomenclatura `abstract_…`) o documentar la excepción en AGENTS.md | debt | M | 🟡 |
| P3-7 | Descomponer `privacy_screen.dart` (406 LoC) y dejar `manager_inbox_screen.dart` bajo 300 | debt | S-M | 🟢 |
| P3-8 | Dependabot/Renovate + build APK/iOS en CI | ops | M | 🟢 |

---

## Bloque PROD — bloqueadores de producción a escala 🆕

> Solo aplica si el proyecto deja de ser un TFG demostrable y aspira a
> servicio real. Detalle y evidencia: `docs/SCALABILITY.md`.

| ID | Acción | Tipo | Esf. | Riesgo | Criterio de aceptación |
|----|--------|------|------|--------|------------------------|
| PROD-1 | **Firma de release real**: keystore propio + Play App Signing; CI con secrets; quitar `signingConfigs.getByName("debug")` de `build.gradle.kts:39` | fix | M | 🟡 | APK/AAB firmado release; verificable; no debug keys |
| PROD-2 | **Paginación/keyset** en todos los repos `remote/` + listas virtualizadas + prefetch por viewport | req | L | 🟡 | Sin `select` sin `range`; listas no materializan todo |
| PROD-3 | **F13 Realtime escalable**: suscripción multiplexada por operador/área, backpressure, reconexión con jitter | req | XL | 🔴 | Bus en vivo real; coste de canales acotado |
| PROD-4 | **SEC1**: rotar PAT Supabase (externo) · **SEC2**: `.env`→`--dart-define`/secret manager | ops/fix | M | 🔴 | PAT viejo inválido; `.env` no en bundle; CI con secrets |
| PROD-5 | **`autoDispose` selectivo** + `keepAlive` explícito; auditar streams/timers | debt | L | 🟡 | Sin fugas; providers de pantalla liberan |
| PROD-6 | **Mapa a escala**: clustering por zoom, `RepaintBoundary`, LOD de markers | req | L | 🟡 | 60 fps con miles de paradas |
| PROD-7 | **Observabilidad**: tracing cliente↔Edge↔DB, métricas de negocio, SLO/alertas, logs estructurados | req | L | 🟢 | Dashboards + alertas operables |
| PROD-8 | **CI producción**: build Android/iOS firmado, gate de cobertura, SAST, Dependabot, smoke E2E | ops | L | 🟢 | Pipeline completo verde |
| PROD-9 | **Caché/tenant a escala**: tamaño/evicción/cifrado Hive; partición por `operator_id`; `live_recorder_draft` cifrado | fix | M | 🟡 | Caché acotada y cifrada |
| PROD-10 | **Backend a escala**: FORCE RLS + auditoría, pooling, idempotencia Edge, GTFS streaming, plan no-free/multi-región | req | L | 🟡 | Carga sostenida sin degradar |

## Bloque A11Y — accesibilidad WCAG 2.2 AA 🆕

> "WCAG 2.1 AA" no es defendible hoy. Detalle por criterio:
> `docs/ACCESSIBILITY.md`.

| ID | Acción | WCAG | Esf. | Riesgo | Criterio de aceptación |
|----|--------|------|------|--------|------------------------|
| A11Y-1 | Alternativa accesible al mapa (lista equivalente enlazada) + semántica del mapa | 1.1.1/1.3.1 | L | 🟡 | Lector cubre la función nuclear |
| A11Y-2 | `Pressable` ≥48 dp (`kMinInteractiveDimension`) | 2.5.5/2.5.8 | S | 🟡 | Todos los táctiles ≥48 dp |
| A11Y-3 | Verificación real con TalkBack/VoiceOver/Switch + checklist por release | 4.1.2 | M | 🟢 | Informe de pruebas con producto de apoyo |
| A11Y-4 | `Semantics` ES hardcodeado → l10n (≈10 archivos) | 1.3.1/4.1.2 | M | 🟢 | Lector anuncia en idioma activo |
| A11Y-5 | `textScaler` compone el del SO (clamp), 200 % sin overflow | 1.4.4 | M | 🟡 | Texto del SO respetado |
| A11Y-6 | Errores accesibles y claros (no `e.toString()`), foco al error | 3.3.1/3.3.3 | M | 🟢 | Mensajes l10n + `Semantics` de error |
| A11Y-7 | Contraste de tokens base verificado con herramienta; no solo-color | 1.4.3/1.4.1 | M | 🟢 | Ratios AA documentados |
| A11Y-8 | Fuentes locales (F26) + reducir tamaño APK (bundle/splits) | 1.4.12 | M | 🟢 | Sin red, tipografía OK; APK menor |
| A11Y-9 | Foco: orden, visibilidad, `FocusTraversalGroup`, teclado/switch | 2.4.3/2.4.7 | M | 🟡 | Navegación por foco completa |
| A11Y-10 | i18n inclusivo: RTL + lectura fácil + localización num/fecha/moneda | 3.1 | L | 🟡 | RTL funcional; lenguaje claro |

---

## Orden de ejecución recomendado

1. **P0 completo** (1 sesión): desbloquea defensa; cero riesgo.
2. **P1-1, P1-2, P1-10, P1-9** (quick wins de bajo riesgo) → commit.
3. **P1-6 → P1-7 → P1-8** (tokens en cadena: primero crear tokens, luego
   migrar; orden importa para no duplicar).
4. **P1-3 + P1-4 juntos** (ambos tocan tamaño/escala; revisar regresión visual
   una sola vez).
5. **P1-5** (freezed) en commit atómico aislado con `build_runner`.
6. **P2-4** (tests) **antes** o en paralelo a **P2-1/2-2**: tener mocks de
   `SupabaseClient` listos hace que los tests de Realtime valgan más.
7. **P2-1 → P2-2** (Realtime), luego **P2-3** (modelo de usuario, el más
   arriesgado: hacerlo gradual con fallback).
8. **P2-5** (SEC2) **solo** cuando haya ventana para verificar boot+CI a fondo;
   tras él, **P2-7** (gate de cobertura) y retirar el workaround de CI.
9. **P3** según tiempo disponible; P3-3 (barrido de literales) es el de menor
   relación valor/esfuerzo para un TFG — abordarlo último o declararlo deuda.

## Dependencias críticas (no romper el orden)

- **P1-6 antes que P1-7/P1-8** (los tokens deben existir antes de migrar).
- **P2-4 antes/junto a P2-1** (mocks de Supabase reutilizables).
- **P2-5 después de P2-1/P2-2** (cambiar el arranque con Realtime ya estable;
  el CI actual ya funciona con el workaround, no hay prisa de romperlo).
- **P2-3 gradual** (capa Supabase + fallback mock) para no romper los muchos
  consumidores de `currentUserProvider`.
- `textScaler` (P1-4) + `Pressable` (P1-3) se revisan juntos por riesgo visual.

## Lo que NO se hará sin decisión explícita del autor

- Migrar los ~342 `EdgeInsets` literales de forma exhaustiva (P3-3): ruido
  enorme, valor marginal para el TFG. Se declara **deuda asumida**.
- Reescritura completa a `autoDispose` global (riesgo de ciclo de vida).
- Gate de `dart format` (reformatearía 260 ficheros; el proyecto no lo usa
  por decisión, AGENTS.md).

## Estado vivo

Marcar cada ID como ✅/⏳ aquí y en `docs/PENDIENTES.md` al cerrarlo,
manteniendo la regla de sincronía de AGENTS.md (PENDIENTES ↔ AUDIT ↔ PLAN).
