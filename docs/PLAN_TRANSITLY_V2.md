# Plan de acción — Transitly · v2

**Versión:** 2.3 · **Fecha:** 15-may-2026

> **Cambios v2.2 → v2.3** (post-F26): F16→F25 marcadas como completadas en roadmap visual. CI creado. 26/28 fases (92.9%). 137 tests.
**Repo:** [astralk9999/Transitly](https://github.com/astralk9999/Transitly)
**Documento de arquitectura de referencia:** `docs/ARCHITECTURE.md` (post P43, commit `b91fc25`).

> **Cambios v2.0 → v2.1** (post-auditoría F0): se inserta **F0.5 — Higiene previa al backend** entre F0 y F1, recogiendo los items "S" del informe de auditoría que se cierran en medio día / un día. F9 queda recortada (solo filtros del mapa y revisión de pendientes acumulados) porque el resto del trabajo de "cerrar lo a medias" se adelanta a F0.5.

> Este plan **evoluciona** la arquitectura existente; no la reescribe. Cada prompt empieza con `Lee primero docs/ARCHITECTURE.md y respeta sus reglas de oro`. Si un prompt te pide tocar algo que ya existe, primero lo localiza, luego lo cambia.

---

## 0. Decisiones cerradas

| Eje | Decisión |
|---|---|
| Backend | Supabase (Postgres + Auth + Storage + Realtime + RLS + PostGIS + Edge Functions) |
| Alcance | Producto comercial — TFG primero, Play Store después |
| Cobertura | España entera, multi-operador, todo tipo de buses |
| Importación de datos | GTFS desde el día 1 |
| Mapas | MapTiler (cambio trivial de tile URL al pasar a producción) |
| Push | FCM |
| Realtime | Supabase Realtime |
| Analítica | PostHog |
| Crash reporting | Sentry |
| NFC | Solo lectura (ya completo) |
| Driver | Códigos de invitación por operador + asignación manual del admin de fallback |
| Rutas comunitarias vs oficiales | Toggle visual en filtros; autoría visible al pinchar la ruta |
| Reputación | Visible y con rangos; decorativa por ahora |
| Trazas GPS | Locales en el dispositivo hasta publicar |
| Plataformas | iOS 16+, Android API 24+, Web (híbrido Astro + Flutter Web islands), wearables nivel 0 ahora · nivel 1 al final si sobra tiempo |
| Modelos | Migración gradual a `freezed` (selectiva, según impacto) |
| Equipo | Solo tú con Claude Code |
| Datos oficiales | Fuentes públicas + sistema comunitario crítico |

### Matices aprobados

- **Códigos de conductor:** cada `OperatorModel` genera códigos de un solo uso (ej. `JZS-7K2P-9R`) que el conductor canjea en la app. Tabla `driver_assignments` para la relación n:m con operadores. Revocación posible desde panel del operador, invalida tokens vía RLS.
- **Lazy loading geoespacial:** al arrancar, Supabase devuelve `operators` con `bbox`. Se detecta ubicación, se precarga el operador local y se cargan otros bajo demanda. Búsqueda global vía PostGIS con índice GIST.
- **GTFS-Realtime con fallback en cascada:** prioridad `gtfs_realtime` → `driver` (comunidad o asignado) → `estimated`. Cada bus en el mapa lleva etiqueta del origen del dato: **oficial · vivo**, **oficial · estimado**, **comunidad · driver**, **comunidad · estimado**.

---

## 1. Cómo usar este documento

Cada fase tiene **objetivo, dependencias, prompts numerados, checklist de "hecho cuando"**. Los prompts son copiables a Claude Code en orden. Si abres una sesión nueva, empieza por:

```
Estoy ejecutando el Plan v2 de Transitly, fase <N>. Ya está hecho:
<lista>. Vamos con el prompt <N.x>:

<pega el prompt>

Antes de tocar nada lee docs/ARCHITECTURE.md y docs/PLAN_V2.md.
```

Cada fase termina con `Hecho cuando`. **No avances a la siguiente sin tener todos los checks.** Si algo falla, anótalo en `docs/PENDIENTES.md` con su decisión.

---

## 2. Roadmap visual

```
✅ BLOQUE I · Cimientos (COMPLETO)
   ✅ F0 Auditoría → ✅ F0.5 Higiene previa → ✅ F1 freezed selectivo
   → ✅ F2 Supabase → ✅ F3 Repositorios+Hive

✅ BLOQUE II · Identidad (COMPLETO)
   ✅ F4 Auth → ✅ F5 Roles tipados → ✅ F6 Códigos de conductor

✅ BLOQUE III · Datos a escala España (COMPLETO)
   ✅ F7 Importador GTFS → ✅ F8 Detección geográfica + lazy multi-operador

✅ BLOQUE IV · Experiencia core (COMPLETO)
   ✅ F9 Filtros + revisión → ✅ F10 Editor manual → ✅ F11 LiveRecorder GPS real
   → ✅ F12 Compartir + oficializar

✅ BLOQUE V · Ojos del bus (COMPLETO)
   ✅ F13 GTFS-Realtime + estimador + etiquetas → ✅ F14 Driver en vivo

✅ BLOQUE VI · Comunidad y moderación (COMPLETO)
   ✅ F15 Contribuciones consolidadas → ✅ F16 Panel admin

✅ BLOQUE VII · Pulido visual y accesibilidad (COMPLETO)
   ✅ F17 Apariencia → ✅ F18 Accesibilidad → ✅ F19 Reputación visible

✅ BLOQUE VIII · Infraestructura de producto (COMPLETO)
   ✅ F20 Tiles MapTiler + offline → ✅ F21 FCM + in-app + wearable nivel 0
   → ✅ F22 Sentry + PostHog

✅ BLOQUE IX · Plataformas extra (COMPLETO)
   ✅ F23 Web híbrida Astro + Flutter Web islands → ✅ F24 Widgets nativos móvil

✅ BLOQUE X · Cierre (EN PROGRESO)
   ✅ F25 Privacidad + GDPR/LOPD → 🟨 F26 QA, performance, TFG, beta interna,
   Play Store → ⏳ F27 (opcional) Wearable nivel 1
```

Los bloques I → II → III son **bloqueantes**. El IV depende de los tres anteriores. V, VI son razonablemente independientes entre sí. VII, VIII, IX se pueden paralelizar pero VIII tiene que estar antes de cualquier release público.

---

# BLOQUE I — Cimientos

## FASE 0 — Auditoría in situ

**Objetivo:** Tener una foto exacta de qué queda por cerrar dentro de `lib/`. El `ARCHITECTURE.md` da la estructura, pero los `// TODO`, los filtros que renderizan sin aplicarse, las pantallas huérfanas y los bugs sutiles solo se ven leyendo el código. Esta es la única fase del plan que no produce código de producción; produce el documento que guía las siguientes 26 fases.

**Dependencias:** ninguna.

### Prompt 0.1 — Mapa real del código

```
Lee docs/ARCHITECTURE.md primero. Luego haz una auditoría completa de
lib/ y devuélveme un informe en docs/AUDIT_2026_04.md con estas
secciones:

1. ARQUITECTURA OBSERVADA
   - Tabla de cada feature en lib/features/: ruta de go_router que
     resuelve, archivo *_screen.dart de entrada, controllers locales
     que tiene, y dependencias hacia data/ y shared/providers/.
   - Lista de TODOS los providers globales en lib/shared/providers/
     con: tipo (Provider, StateNotifier, FutureProvider, StreamProvider),
     dependencias, y si está consumido o no.
   - Lista de TODOS los modelos en lib/shared/models/ con: campos,
     factory fromJson, si tiene == y hashCode, y si lo usan ≥2 features
     o solo una.

2. PUNTOS A MEDIAS (esto es crítico)
   Localiza y enumera, con file:line:
   - Comentarios `// TODO`, `// FIXME`, `// XXX`, `// HACK`.
   - Métodos que devuelven datos placeholder, listas vacías hardcoded,
     `throw UnimplementedError`, o `if (kDebugMode) ...` con lógica
     real dentro.
   - Filtros en UI (chips, switches, sliders) que renderizan pero NO
     conectan con un provider o no aplican lógica al estado.
   - Pantallas a las que no se llega desde la navegación (búsqueda
     inversa: cualquier *_screen.dart que no aparezca como destino
     en core/router/).
   - Imports no usados, getters dead, providers definidos sin
     consumidores.

3. RIESGOS Y DEUDA TÉCNICA
   - Modelos plain-Dart que se comparan por referencia y se pasan a
     Riverpod (rebuild bugs).
   - Servicios que no propagan errores tipados (incumplen sección 4
     del ARCHITECTURE.md).
   - Llamadas a print() restantes (lint avoid_print activo desde P37,
     debería ser cero).
   - Lógica de negocio en widgets en lugar de en controllers.
   - Tests existentes y huecos de cobertura por feature.

4. PROPUESTA DE CIERRE
   Para cada item de "A medias", una línea con:
   - Decisión sugerida (cerrar, borrar, posponer a F<N>).
   - Estimación de esfuerzo (S, M, L).

NO modifiques código. Solo el informe.
```

### Prompt 0.2 — Inventario de assets y datos

```
Lee docs/ARCHITECTURE.md. Inventario completo de datos:

1. assets/mock/comujesa_data.json — devuelve un esquema (jq estilo) con
   todos los caminos JSON, tipos y conteos por colección.
2. assets/branding/ — lista los archivos y para qué los usa la app.
3. shaders/ — qué shader hay y desde qué widget se usa.
4. comujesa_data.json (raíz) y generate_enriched_data.js — explica el
   pipeline: input, transformaciones, output. Decide si generate_*.js
   queda en el repo o se mueve a tools/.

Devuelve un docs/DATA_INVENTORY.md.
```

### Prompt 0.3 — Documento PENDIENTES vivo

```
Crea docs/PENDIENTES.md con esta estructura:

# Pendientes
## Bloqueantes
## Mejora
## Ideas para v3

A partir de docs/AUDIT_2026_04.md, mete en "Bloqueantes" todo lo que
esté marcado como S/M con decisión "cerrar" o "borrar". En "Mejora"
todo lo L. Vacío "Ideas para v3" para irlo rellenando.

Convención: cada entrada lleva [F<fase>] al inicio si ya está mapeada
a una fase del plan; [SIN ASIGNAR] si no.
```

### Hecho cuando

- [ ] Existe `docs/AUDIT_2026_04.md` y lo has leído entero.
- [ ] Existe `docs/DATA_INVENTORY.md`.
- [ ] Existe `docs/PENDIENTES.md` con bloqueantes, mejoras y caja de ideas.
- [ ] Sabes nombrar de memoria las features actuales y los providers globales.

---

## FASE 0.5 — Higiene previa al backend

**Objetivo:** Cerrar los items "S" (pequeños) del informe de auditoría — bugs de routing, controles inertes, lógica de negocio en widgets, errores tipados de `MockDataService` — antes de tocar `freezed` o Supabase. Es medio día / un día de trabajo, en tres bloques pequeños que se ejecutan en orden A → B → C. Los items grandes del informe (placeholders de IA, history, planned trips, etc.) NO se tocan aquí: se quedan en `docs/PENDIENTES.md` con tag `[F<N>]` apuntando a la fase del plan donde su feature aterriza naturalmente.

Por qué insertarla ahora y no dejarla en F9: dos de estos arreglos (`MockDataException` tipada y mover lógica fuera de widgets) son **referencia directa para F1 y F3**. Hacerlos antes evita reescribir trabajo. Y los wirings huérfanos (`showReportIncidentSheet` ya implementado, `RouteChangelogModel` parseado pero no consumido) son código gratis que cierra flujos sin lógica nueva.

**Dependencias:** F0 (necesitas el `AUDIT_2026_04.md` y `PENDIENTES.md`).

### Prompt 0.5.A — Bloque A: routing y wiring trivial

```
Lee docs/ARCHITECTURE.md y docs/AUDIT_2026_04.md.

Cierra los siguientes items del informe en commits independientes con
conventional commits. Trabaja sobre el repo actual (mocks; nada de
Supabase aún — eso es F2).

A1. Bug routing 1.17:
    En lib/features/driver/driver_panel.dart:72, "Bandeja de gestión"
    debe enlazar a /management/inbox, no a /driver/stats.

A2. Item 1.5 "Elegir otra" en lib/features/driver/start_route_screen.dart:111:
    sustituye onTap: () {} por un scroll-to la lista de rutas
    disponibles del propio screen. ScrollController + ensureVisible.

A3. Item 1.7 SearchResultsScreen huérfana:
    Borra lib/features/search/search_results_screen.dart y la ruta
    /search/results en core/router/app_router.dart. Verifica que
    flutter analyze sigue limpio.

A4. Item 1.11 "Cerrar sesión" en
    lib/features/home/widgets/profile_about_section.dart:69-73:
    onTap abre un AlertDialog "¿Cerrar sesión?" con dos botones.
    En el OK, por ahora un SnackBar "Sesión cerrada (demo)".
    En F4 esto se reemplaza por authRepository.signOut().

A5. Item 1.14 ActiveRoute botón "INCIDENCIA"
    (lib/features/driver/active_route_screen.dart:243-247):
    en lugar del SnackBar, llama a showReportIncidentSheet con el
    contexto del trip activo (route_id, stop_id si aplica).
    No olvides el import.

A6. Item 1.15 RouteDetail changelog hardcoded
    (lib/features/route_detail/widgets/route_detail_changelog.dart):
    consume el RouteChangelogModel desde el provider del route detail
    (búscalo en shared/providers/ — debe existir o derivarlo de
    mapDataCacheProvider). Quita las 3 entradas hardcoded.

A7. Item 1.16 StopDetailScreen acciones
    (stop_detail_screen.dart:270-273):
    sustituye SOLO la acción "Reportar" por una llamada a
    showReportIncidentSheet con stop_id precargado. Las otras tres
    acciones (Mejorar/Compartir/Cómo llegar) déjalas como están —
    se posponen a sus fases respectivas (Compartir → F12, Mejorar →
    F15, Cómo llegar → F8 con búsqueda + ruta).

Tras A1-A7:
  - flutter analyze limpio.
  - Tests existentes en verde.
  - Resumen de qué quedó cerrado y qué se movió a docs/PENDIENTES.md
    (las 3 acciones del Stop Detail con su tag [F<N>]).
```

### Prompt 0.5.B — Bloque B: calidad estructural

```
Lee docs/ARCHITECTURE.md secciones 4 y 6 y docs/AUDIT_2026_04.md.

B1. Item 3.2 MockDataException:
    Crea en lib/data/mock/:
      mock_data_error.dart:
        enum MockDataError {
          assetNotFound, parseError, unexpectedSchema, unknown
        }
      mock_data_exception.dart:
        class MockDataException implements Exception {
          final MockDataError error;
          final String message;
          final Object? cause;
          final StackTrace? stackTrace;
          const MockDataException(...);
          @override
          String toString() => '...';
        }

    Refactoriza MockDataService para envolver:
      - rootBundle.loadString FormatException → assetNotFound o parseError.
      - PlatformException → unknown con cause.
      - Schema validation (campos faltantes en el JSON) → unexpectedSchema.

    Tag de logger: '[MockData]'.
    Tests: añade lib/test/data/mock/mock_data_service_test.dart con
    al menos:
      - asset existente, parseo OK.
      - asset inexistente → MockDataException(assetNotFound).
      - JSON malformado → MockDataException(parseError).
      - JSON con schema incorrecto → MockDataException(unexpectedSchema).
    Para los tests negativos, usa un asset bundle mock que devuelva
    contenido controlado.

B2. Item 3.4 Lógica de negocio en widgets — 5 sitios.
    Cada uno en commit independiente. Patrón: el cómputo se mueve
    a un provider derivado en lib/shared/providers/derived/<nombre>.dart.
    El widget pasa a hacer ref.watch puro.

    B2.1 home_tab.dart:54-80
         Crea:
           homeFavRouteIdsProvider           → Set<String>
           homeHabitualStopProvider          → StopModel?
           homeNearbyStopsProvider.family<LatLng, List<StopModel>>
           homeFavAlertsProvider             → List<AlertModel>
         Hidrátalos desde currentUserProvider y mapDataCacheProvider.

    B2.2 home_tab.dart:267-274 y stop_detail_screen.dart:35-40
         Ambos hacen el mismo inverted-index. Refactoriza ambos para
         usar el ya-existente stopToRouteCodesProvider. Si el provider
         actual no devuelve el formato esperado por alguno de los
         dos sitios, crea un selector derivado encima en lugar de
         duplicar el cálculo.

    B2.3 start_route_screen.dart:44-60
         Crea upcomingDeparturesForRouteProvider.family<RouteId,
         List<ScheduleModel>> con el cómputo de "próximos N" (N=3
         por defecto, configurable).

    B2.4 active_route_screen.dart:32-78
         Crea activeTripDetailProvider.family<TripId, ActiveTripDetail>
         que devuelva un value object inmutable:
           class ActiveTripDetail {
             final ActiveTripModel trip;
             final int currentIdx;
             final StopModel? nextStop;
             final StopModel firstStop;
             final StopModel lastStop;
           }
         El widget solo lee los campos que necesita.

Tras B1+B2:
  - Ningún provider derivado tira de mockData en build() de un widget.
  - Cada provider creado tiene un test unitario con ProviderContainer
    y datos sintéticos (caso vacío, caso normal, caso edge).
  - flutter analyze limpio.
  - Documenta los nuevos providers en docs/ARCHITECTURE.md sección 2
    (lista de providers globales).
```

### Prompt 0.5.C — Bloque C: cerrar dos flujos para demo continua

```
Lee docs/ARCHITECTURE.md y docs/AUDIT_2026_04.md.

C1. Item 1.4 Post-recording editor recibe trace real:
    En lib/features/driver/route_editor/post_recording_editor.dart,
    elimina:
      - el const _trace.
      - las 5 paradas hardcoded (líneas 23-35, 44-50 según informe).

    Conecta con LiveRecorderController:
      - La pantalla recibe en su constructor:
          final List<LatLng> trace;
          final List<RecordedStop> stops;
        donde RecordedStop es un value object con name, position,
        arrivalOffset.
      - El LiveRecorderController, al pasar a "review", expone
        getCurrentSession() → RecordedSession { trace, stops }.
      - El navigator de la wizard pasa la sesión a PostRecordingEditor
        en lugar de los datos const.

    Persistencia local:
      - Cuando LiveRecorderController termina (stop()), serializa
        la sesión a almacenamiento local. Como Hive aún no está
        instalado (eso es F3), usa shared_preferences temporalmente
        con clave 'live_recorder_draft:<userId-or-guest>'.
      - Documenta en docs/PENDIENTES.md como
        [F3] migrar live_recorder_draft a Hive con cifrado AES.

    Validación: tras grabar simulado y pasar al post-recording, los
    waypoints visibles son los reales, no los hardcoded.

C2. Item 1.9 Feedback categorías inertes:
    En feedback_screen.dart:126-129, cada categoría debe abrir el
    flujo correspondiente (sheet o pantalla de envío) en lugar del
    SnackBar 'próximamente'.

    Por ahora, el envío del feedback se persiste en memoria a través
    de un StateNotifier nuevo:
      lib/shared/providers/local_feedback_provider.dart
      class LocalFeedbackNotifier extends StateNotifier<List<FeedbackEntry>>
    El StateNotifier guarda en shared_preferences con clave
    'local_feedback_drafts'. La lista visible en MyContributions
    se hidrata desde aquí.

    En F15 esto se conectará al RouteFeedbackRepository real y la
    cola de pending_actions. Documenta el plan de migración en
    docs/PENDIENTES.md como [F15] migrar local_feedback a backend.

    Borra:
      - lib/features/feedback/feedback_detail_screen.dart (huérfana).
      - La ruta /feedback/detail en app_router.dart.

Tras C1+C2:
  - La demo soporta: grabar ruta simulada → ir a post-recording con
    datos reales.
  - La demo soporta: reportar feedback que aparece en una lista
    persistente local.
  - flutter analyze limpio, tests en verde.
  - Resumen de qué quedó cerrado, qué se movió a docs/PENDIENTES.md
    con sus tags [F<N>].
```

### Items que NO se tocan en F0.5 (referencia para `docs/PENDIENTES.md`)

Estos placeholders del informe se quedan **explícitamente** en `docs/PENDIENTES.md` con tag de la fase donde aterrizan:

| Item informe | Decisión | Tag |
|---|---|---|
| 1.1 ScheduleEditor independiente | borrar (solapa con StepSchedules) | `[BORRAR en 0.5.A]` |
| 1.2 AiScheduleImport | placeholder | `[F44+]` (futuro lejano) |
| 1.3 Wizard guardar/publicar | se cierra con persistencia real | `[F10]` |
| 1.6 Driver history/stats | se cierra con driver real | `[F14]` para history, `[F19]` para stats |
| 1.8 Suggestion detail/contribute | se cierra con contributions | `[F15]` |
| 1.10 PlannedTrips/FilterPresets | se cierra con UX avanzada | `[F19]` reputación + `[F44+]` para planificación |
| 1.13 Zona principal sin handler | se cierra con city picker | `[F8]` |
| 3.1 Modelos sin == | freezed selectivo | `[F1]` |
| 3.5 Cobertura de tests | feature a feature | `[F26]` |

### Hecho cuando

- [ ] Bloque A cerrado: routing fix, 5 wirings huérfanos cableados, 1 archivo borrado.
- [ ] Bloque B cerrado: `MockDataException` tipada con tests, 5 sitios de lógica de widget movidos a providers derivados con tests.
- [ ] Bloque C cerrado: post-recording recibe traza real, feedback persiste local, 2 huérfanos eliminados.
- [ ] `flutter analyze` limpio.
- [ ] Tests pasan en verde, cobertura nueva sumada.
- [ ] `docs/PENDIENTES.md` actualizado con todos los items del informe que se posponen, cada uno con su tag de fase.
- [ ] Resumen final en chat: qué cambió, conteo de commits, snapshot de estado.

---

## FASE 1 — Migración selectiva a `freezed`

**Objetivo:** Pasar a `freezed` los modelos cuya igualdad por valor importa para Riverpod (rebuilds eficientes, comparación con `==` correcta) y los que vamos a tocar pesadamente en las fases siguientes. **No** migrar todo: el `ARCHITECTURE.md` deja claro que los modelos auxiliares pueden quedarse plain-Dart. Migrar selectivo evita un PR gigante y reduce riesgo.

**Dependencias:** F0.

### Prompt 1.1 — Setup de codegen

```
Lee docs/ARCHITECTURE.md. Añade la cadena de codegen a Transitly:

1. Añade al pubspec.yaml:
     dependencies: freezed_annotation, json_annotation
     dev_dependencies: build_runner, freezed, json_serializable
   Versiones compatibles con dart sdk ^3.9.2.

2. Crea build.yaml en la raíz del proyecto con la config recomendada
   de freezed (line_length 100, generated en parte misma carpeta).

3. Añade scripts de Make-style en tool/build.sh:
     dart run build_runner build --delete-conflicting-outputs
     dart run build_runner watch
   Y documenta su uso en docs/ARCHITECTURE.md sección 6 ("Tokens y
   patrones que ya están escritos") añadiendo un sub-apartado "Codegen".

4. Verifica que `dart run build_runner build` corre sin errores en un
   árbol vacío (sin modelos migrados aún).
```

### Prompt 1.2 — Migración de modelos críticos

```
Migra a freezed los siguientes modelos de lib/shared/models/, en este
orden:

PRIMER LOTE (alta prioridad — los que más rebuilds causan)
1. UserModel
2. RouteModel
3. StopModel
4. ScheduleModel
5. IncidentModel
6. RouteFeedbackModel
7. RouteSuggestionModel

SEGUNDO LOTE (los que vamos a tocar en fases 4-12)
8. ActiveTripModel
9. OperatorModel
10. UserCardModel
11. RouteStopModel
12. ZoneModel
13. AlertModel

NO MIGRES (los dejamos plain-Dart por ahora):
RouteChangelogModel, UserFavoriteModel, HabitualTripModel,
TripHistoryModel, AchievementModel, UserAchievementModel,
FeedbackMessageModel.

Para cada migración:
- Mantén EXACTAMENTE los mismos campos públicos y nombres.
- Conserva las factories `fromJson` y añade `toJson` si no la tenían.
- Mantén firmas de cualquier método estático actual.
- Si el modelo tenía constantes/enums internos (ej. RouteStatus en
  RouteModel), NO los muevas, déjalos donde están.
- Re-genera con build_runner y verifica que la app compila tras CADA
  modelo migrado (no migres los 13 de golpe; commit por modelo o por
  lote pequeño).

Cuando termines, actualiza docs/ARCHITECTURE.md sección 3, marcando
los migrados con un sufijo "(freezed)".
```

### Prompt 1.3 — Modelos nuevos requeridos

```
Crea estos modelos NUEVOS en lib/shared/models/, todos con freezed,
incluyendo el archivo .freezed.dart y .g.dart generados:

1. BusLocation
   campos: lat (double), lng (double), bearing (double?),
   recordedAt (DateTime), accuracy (double?)
   uso futuro: extraer de ActiveTripModel.currentLat/lng/bearing.

2. FeatureRequest
   campos: id (String), title (String), description (String),
   submittedBy (String userId), category (FeatureRequestCategory enum:
     newRoute, routeOfficial, appFeature, dataCorrection, other),
   priority (FeatureRequestPriority enum: low, normal, high),
   status (FeatureRequestStatus enum: open, inReview, accepted,
     rejected, scheduled, done),
   votes (int), payload (Map<String,dynamic>?), createdAt, updatedAt,
   adminNotes (String?), assigneeId (String?).

3. OfflineRegion
   campos: id, label, bounds (LatLngBounds-like — define un value
   object propio: northLat, southLat, eastLng, westLng), zoomMin,
   zoomMax, downloadedAt, sizeBytes, status (downloading, ready,
   stale, error).

4. RouteShare
   campos: routeId, sharedWithId, sharedById, permission (view, edit),
   createdAt, expiresAt (nullable, para enlaces con caducidad).

5. DriverInvitationCode
   campos: code (String, formato XXX-XXXX-XX), operatorId, createdBy,
   maxUses (int, default 1), uses (int), expiresAt, kind (driver,
   operatorAdmin).

6. UserPreferences
   campos: userId, themePaletteId, customColors (Map<String,String>?),
   backgroundId, backgroundEnabled (bool), backgroundOpacity (double),
   fontScale (double), colorBlindMode (none, protanopia,
   deuteranopia, tritanopia), dyslexiaFontEnabled (bool),
   reduceMotion (bool).

7. AppNotification
   campos: id, userId, type (incidentResolved, routePromoted,
   shareReceived, featureRequestReplied, busApproachingFavorite,
   custom), payload (Map), read (bool), createdAt.

Cada uno con su factory fromJson/toJson y == por valor (gratis con
freezed).

Actualiza docs/ARCHITECTURE.md sección 3 marcando estos modelos como ✅.
```

### Hecho cuando

- [ ] `dart run build_runner build` corre limpio.
- [ ] Los 13 modelos del primer y segundo lote son `freezed`.
- [ ] Los 7 modelos nuevos existen.
- [ ] La app compila y los tests existentes pasan.
- [ ] `docs/ARCHITECTURE.md` sección 3 actualizado.

---

## FASE 2 — Backend Supabase

**Objetivo:** Tener Supabase funcionando con auth, esquema completo, RLS desde el primer día, PostGIS para geoespacial, y storage configurado para avatares y adjuntos. Toda escritura del cliente pasará por aquí en las siguientes fases.

**Dependencias:** F1 (los modelos definen el esquema).

### Prompt 2.1 — Conexión y env

```
Lee docs/ARCHITECTURE.md.

1. Añade al pubspec.yaml:
     supabase_flutter: ^2.x
     flutter_dotenv: ^5.x
     postgrest: (transitivo, no añadir explícito)

2. Crea .env y .env.example en la raíz con:
     SUPABASE_URL=
     SUPABASE_ANON_KEY=
     SUPABASE_FUNCTIONS_URL=
     POSTHOG_API_KEY=
     POSTHOG_HOST=https://eu.posthog.com
     SENTRY_DSN=
     MAPTILER_API_KEY=

3. Añade .env al .gitignore (NUNCA commitear).

4. Crea lib/core/env.dart con una clase Env que cargue las variables
   en main.dart antes de runApp(). Errores tipados:
   enum EnvError { missing, malformed }
   class EnvException implements Exception ...
   Si falta una variable crítica (SUPABASE_URL, ANON_KEY) la app
   muestra una pantalla de error explicativa, no crashea silenciosamente.

5. Inicializa Supabase en main.dart después de WidgetsFlutterBinding y
   antes de runApp(ProviderScope). NO toques el resto del bootstrap
   (MockDataService etc.), solo añade Supabase al pipeline.

6. Crea lib/data/supabase/supabase_client_provider.dart con:
     final supabaseClientProvider = Provider<SupabaseClient>((ref) {
       return Supabase.instance.client;
     });
   Ningún otro archivo accede a Supabase.instance directamente; todos
   pasan por este provider. Lo justificas como una nota en el archivo.

7. Crea cuenta de Supabase (proyecto "transitly-dev") y déjame el
   .env relleno como variable de entorno o como instrucción para que
   yo lo rellene.

Tag para AppLogger: '[Supabase]'.
```

### Prompt 2.2 — Esquema completo (migración 001_init.sql)

```
Lee docs/ARCHITECTURE.md sección 3 y los modelos en lib/shared/models/.

Crea supabase/migrations/001_init.sql con TODO el esquema. Habilita
PostGIS al inicio. Estructura:

-- 1. EXTENSIONES
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS pgcrypto; -- para gen_random_uuid()

-- 2. ENUMS
user_role: passenger, driver, operator_admin, moderator, admin
route_source: official, community
route_status: official, draft, pendingVerification, verified, suspended
incident_kind: delay, no_show, congestion, accident, other
incident_status: open, in_review, resolved, rejected
feedback_kind: stop_change, schedule_error, info_correction, other
feedback_status: open, in_review, applied, rejected
feature_request_kind: newRoute, routeOfficial, appFeature,
                     dataCorrection, other
feature_request_status: open, inReview, accepted, rejected, scheduled, done
suggestion_status: open, considered, accepted, rejected
share_permission: view, edit
bus_position_source: gtfs_realtime, driver, estimated
notification_type: incident_resolved, route_promoted, share_received,
                  feature_request_replied, bus_approaching_favorite, custom
color_blind_mode: none, protanopia, deuteranopia, tritanopia
invitation_kind: driver, operator_admin
gtfs_import_status: queued, running, success, failed
day_type: weekday, saturday, sunday_holiday

-- 3. TABLAS

-- Operadores (COMUJESA, TUSSAM, EMT Madrid, TMB, ...)
CREATE TABLE operators (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'ES',
  region TEXT,
  contact_email TEXT,
  website TEXT,
  gtfs_url TEXT,
  gtfs_realtime_url TEXT,
  bbox geometry(POLYGON, 4326),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_operators_bbox ON operators USING GIST (bbox);

-- Perfiles (espeja auth.users)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  role user_role NOT NULL DEFAULT 'passenger',
  primary_zone_id UUID,
  reputation_score INT NOT NULL DEFAULT 0,
  reputation_level INT NOT NULL DEFAULT 0,
  email_verified BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Asignaciones de driver (n:m profiles ↔ operators)
CREATE TABLE driver_assignments (
  driver_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  operator_id UUID REFERENCES operators(id) ON DELETE CASCADE,
  granted_by UUID REFERENCES profiles(id),
  granted_at TIMESTAMPTZ DEFAULT NOW(),
  revoked_at TIMESTAMPTZ,
  active BOOLEAN GENERATED ALWAYS AS (revoked_at IS NULL) STORED,
  PRIMARY KEY (driver_id, operator_id)
);
CREATE INDEX idx_driver_assignments_active ON driver_assignments
  (driver_id) WHERE revoked_at IS NULL;

-- Códigos de invitación
CREATE TABLE invitation_codes (
  code TEXT PRIMARY KEY,
  operator_id UUID REFERENCES operators(id) ON DELETE CASCADE,
  kind invitation_kind NOT NULL DEFAULT 'driver',
  created_by UUID REFERENCES profiles(id),
  max_uses INT NOT NULL DEFAULT 1,
  uses INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Paradas
CREATE TABLE stops (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  code TEXT,
  name TEXT NOT NULL,
  geom geometry(POINT, 4326) NOT NULL,
  accessibility JSONB DEFAULT '{}'::jsonb,
  gtfs_stop_id TEXT,
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(operator_id, gtfs_stop_id)
);
CREATE INDEX idx_stops_geom ON stops USING GIST (geom);
CREATE INDEX idx_stops_operator ON stops (operator_id);

-- Rutas (oficiales y comunitarias en la misma tabla, distinguidas
-- por route_source. Esto resuelve el "dual marker" mencionado en
-- ARCHITECTURE.md sección 3 fila Route-comunitaria).
CREATE TABLE routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  source route_source NOT NULL,
  status route_status NOT NULL,
  code TEXT,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT, -- hex con o sin #
  owner_id UUID REFERENCES profiles(id),
  gtfs_route_id TEXT,
  geom geometry(LINESTRING, 4326),
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(operator_id, gtfs_route_id),
  CHECK (
    (source = 'official' AND owner_id IS NULL AND operator_id IS NOT NULL)
    OR (source = 'community')
  )
);
CREATE INDEX idx_routes_geom ON routes USING GIST (geom);
CREATE INDEX idx_routes_status ON routes (status, source);

-- Paradas dentro de una ruta (orden y dirección)
CREATE TABLE route_stops (
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  stop_id UUID REFERENCES stops(id) ON DELETE RESTRICT,
  sequence INT NOT NULL,
  direction SMALLINT NOT NULL DEFAULT 0, -- 0=ida, 1=vuelta
  PRIMARY KEY (route_id, stop_id, direction, sequence)
);

-- Horarios
CREATE TABLE schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  day_type day_type NOT NULL,
  direction SMALLINT NOT NULL DEFAULT 0,
  departure_time TIME NOT NULL,
  arrival_offsets JSONB, -- [{stopId, deltaSeconds}, ...]
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_schedules_route ON schedules (route_id, day_type);

-- Posiciones de bus (live + estimadas + reportadas por driver)
CREATE TABLE bus_positions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  driver_id UUID REFERENCES profiles(id),
  source bus_position_source NOT NULL,
  geom geometry(POINT, 4326) NOT NULL,
  bearing REAL,
  speed_mps REAL,
  trip_id TEXT, -- correlación con GTFS-Realtime cuando aplique
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ -- para limpieza automática
);
CREATE INDEX idx_bus_positions_route_recorded
  ON bus_positions (route_id, recorded_at DESC);
CREATE INDEX idx_bus_positions_geom ON bus_positions USING GIST (geom);

-- Incidentes (heredamos del IncidentModel: retraso, no presentado,
-- congestión, accidente, otro)
CREATE TABLE incidents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind incident_kind NOT NULL,
  status incident_status NOT NULL DEFAULT 'open',
  route_id UUID REFERENCES routes(id),
  stop_id UUID REFERENCES stops(id),
  description TEXT,
  geom geometry(POINT, 4326),
  attachments JSONB DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Feedback de información (cambio de parada, error de horario)
CREATE TABLE route_feedback (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID REFERENCES routes(id),
  stop_id UUID REFERENCES stops(id),
  kind feedback_kind NOT NULL,
  status feedback_status NOT NULL DEFAULT 'open',
  description TEXT NOT NULL,
  proposed_change JSONB, -- nueva posición, nuevo horario, etc.
  attachments JSONB DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

-- Sugerencias de nuevas rutas (RouteSuggestionModel)
CREATE TABLE route_suggestions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status suggestion_status NOT NULL DEFAULT 'open',
  origin_geom geometry(POINT, 4326) NOT NULL,
  destination_geom geometry(POINT, 4326) NOT NULL,
  motivation TEXT NOT NULL,
  desired_frequency TEXT,
  desired_operator_id UUID REFERENCES operators(id),
  votes INT NOT NULL DEFAULT 0,
  attachments JSONB DEFAULT '[]'::jsonb,
  author_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Votos de sugerencias (para evitar votar 2 veces)
CREATE TABLE route_suggestion_votes (
  suggestion_id UUID REFERENCES route_suggestions(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (suggestion_id, voter_id)
);

-- Solicitudes genéricas (incluye "convertir mi ruta comunitaria en
-- oficial", "nueva feature de la app", etc.)
CREATE TABLE feature_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  kind feature_request_kind NOT NULL,
  status feature_request_status NOT NULL DEFAULT 'open',
  priority TEXT NOT NULL DEFAULT 'normal',
  title TEXT NOT NULL,
  description TEXT,
  payload JSONB DEFAULT '{}'::jsonb,
  -- Para kind='routeOfficial', payload incluye {route_id, justification}
  votes INT NOT NULL DEFAULT 0,
  author_id UUID REFERENCES profiles(id),
  assignee_id UUID REFERENCES profiles(id),
  admin_notes TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  resolved_at TIMESTAMPTZ
);

CREATE TABLE feature_request_votes (
  request_id UUID REFERENCES feature_requests(id) ON DELETE CASCADE,
  voter_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (request_id, voter_id)
);

-- Compartir rutas
CREATE TABLE route_shares (
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  shared_with_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  shared_by_id UUID REFERENCES profiles(id),
  permission share_permission NOT NULL DEFAULT 'view',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  PRIMARY KEY (route_id, shared_with_id)
);

-- Enlaces públicos de rutas (slug corto)
CREATE TABLE route_public_links (
  slug TEXT PRIMARY KEY,
  route_id UUID REFERENCES routes(id) ON DELETE CASCADE,
  created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  revoked BOOLEAN DEFAULT false
);

-- Regiones offline
CREATE TABLE offline_regions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  bounds geometry(POLYGON, 4326) NOT NULL,
  zoom_min SMALLINT NOT NULL DEFAULT 12,
  zoom_max SMALLINT NOT NULL DEFAULT 16,
  size_bytes BIGINT,
  status TEXT NOT NULL DEFAULT 'queued',
  downloaded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Preferencias de usuario (apariencia + accesibilidad)
CREATE TABLE user_preferences (
  user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
  theme_palette_id TEXT NOT NULL DEFAULT 'default',
  custom_colors JSONB,
  background_id TEXT,
  background_enabled BOOLEAN NOT NULL DEFAULT true,
  background_opacity REAL NOT NULL DEFAULT 1.0,
  font_scale REAL NOT NULL DEFAULT 1.0,
  color_blind_mode color_blind_mode NOT NULL DEFAULT 'none',
  dyslexia_font_enabled BOOLEAN NOT NULL DEFAULT false,
  reduce_motion BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notificaciones in-app
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type notification_type NOT NULL,
  payload JSONB DEFAULT '{}'::jsonb,
  read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifications_user_unread
  ON notifications (user_id, created_at DESC) WHERE read = false;

-- Auditoría
CREATE TABLE audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES profiles(id),
  action TEXT NOT NULL,
  target_kind TEXT,
  target_id UUID,
  payload JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_audit_actor_time ON audit_log (actor_id, created_at DESC);

-- Importaciones GTFS
CREATE TABLE gtfs_imports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  operator_id UUID REFERENCES operators(id),
  gtfs_url TEXT NOT NULL,
  status gtfs_import_status NOT NULL DEFAULT 'queued',
  started_at TIMESTAMPTZ,
  finished_at TIMESTAMPTZ,
  errors JSONB DEFAULT '[]'::jsonb,
  stats JSONB DEFAULT '{}'::jsonb, -- {routes:n, stops:n, schedules:n}
  feed_version TEXT,
  triggered_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Consentimientos GDPR
CREATE TABLE privacy_consents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  consent_kind TEXT NOT NULL, -- 'analytics', 'marketing', 'crash_reporting'
  granted BOOLEAN NOT NULL,
  granted_at TIMESTAMPTZ,
  revoked_at TIMESTAMPTZ,
  policy_version TEXT NOT NULL
);

-- Solicitudes de exportación de datos
CREATE TABLE data_exports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'queued',
  file_url TEXT,
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

-- Solicitudes de borrado
CREATE TABLE data_deletion_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'requested',
  requested_at TIMESTAMPTZ DEFAULT NOW(),
  scheduled_at TIMESTAMPTZ, -- 30 días después
  completed_at TIMESTAMPTZ
);

-- 4. TRIGGERS

-- Auto-crear profile al registrarse
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO profiles (id, display_name, email_verified)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
    NEW.email_confirmed_at IS NOT NULL
  );
  INSERT INTO user_preferences (user_id) VALUES (NEW.id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- updated_at automático
CREATE OR REPLACE FUNCTION touch_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_routes_touch BEFORE UPDATE ON routes
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_operators_touch BEFORE UPDATE ON operators
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_profiles_touch BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();
CREATE TRIGGER trg_user_prefs_touch BEFORE UPDATE ON user_preferences
  FOR EACH ROW EXECUTE FUNCTION touch_updated_at();

-- Limpieza de bus_positions vencidas
CREATE OR REPLACE FUNCTION cleanup_expired_bus_positions()
RETURNS void AS $$
BEGIN
  DELETE FROM bus_positions
  WHERE expires_at IS NOT NULL AND expires_at < NOW() - INTERVAL '1 hour';
END;
$$ LANGUAGE plpgsql;
-- Programa esta función con pg_cron (si está habilitado en el plan
-- de Supabase) o llámala desde una Edge Function periódica.

Devuélveme el SQL completo y los pasos para aplicarlo (Supabase CLI
con `supabase db push` o copy/paste en el SQL Editor).
```

### Prompt 2.3 — Row-Level Security (migración 002_rls.sql)

```
Lee la matriz de roles × permisos del Anexo D del plan v2 (PLAN_V2.md
sección "Anexos") antes de escribir esto.

Crea supabase/migrations/002_rls.sql con RLS habilitado en TODAS las
tablas y políticas que implementen exactamente la matriz. Estructura:

ALTER TABLE <each> ENABLE ROW LEVEL SECURITY;

Políticas clave (no exhaustivo — el archivo SÍ debe ser exhaustivo):

profiles
  - SELECT: cualquiera autenticado lee profiles públicos.
  - UPDATE: el propio perfil (id = auth.uid()).
  - admin/moderator: SELECT y UPDATE de cualquiera.

operators
  - SELECT: anónimo y autenticado.
  - INSERT/UPDATE/DELETE: solo admin.

driver_assignments
  - SELECT: el driver lee las suyas; admin/operator_admin del operador
    leen las del operador.
  - INSERT: por función SQL `claim_invitation_code(code)` con
    SECURITY DEFINER (no INSERT directo).
  - UPDATE (revocar): operator_admin del mismo operador o admin.

invitation_codes
  - SELECT: solo el creador, el operator_admin del operador, o admin.
  - INSERT: operator_admin del operador o admin.
  - DELETE: el creador o admin.

routes
  - SELECT:
      source='official' OR
      (source='community' AND status IN ('verified','pendingVerification','draft'))
        si owner_id = auth.uid()
      OR existe en route_shares.
      [public visible para community con status='verified'].
  - INSERT: cualquiera autenticado, source='community',
    owner_id = auth.uid().
  - UPDATE:
      owner si source='community' y status no es 'official'.
      admin para promover a 'official' o cambiar source.
      operator_admin del operator_id si source='official'.

route_stops, schedules
  - SELECT: si la route es visible para el caller (regla anterior).
  - INSERT/UPDATE/DELETE: si la route es editable por el caller.

stops
  - SELECT: anónimo y autenticado.
  - INSERT: cualquiera autenticado (las paradas comunitarias se
    flaggean en metadata).
  - UPDATE/DELETE: admin o moderator.

bus_positions
  - SELECT: anónimo y autenticado (es la fuente del mapa público).
  - INSERT con source='driver': solo si auth.uid() está en
    driver_assignments con operator_id = (SELECT operator_id FROM routes
    WHERE id = NEW.route_id).
  - INSERT con source='gtfs_realtime' o 'estimated': solo desde
    Edge Functions (rol service_role).

incidents, route_feedback, route_suggestions, feature_requests
  - SELECT: el autor las suyas; moderator y admin todas.
  - INSERT: cualquiera autenticado, author_id = auth.uid().
  - UPDATE de campos status/admin_notes/assignee_id: moderator y admin.
  - UPDATE de campos del autor: solo el autor y solo si status='open'.

route_suggestion_votes, feature_request_votes
  - INSERT: cualquiera autenticado, voter_id = auth.uid().
  - DELETE: el votante.
  - SELECT: anónimo y autenticado (para count visible).

route_shares
  - SELECT: el owner de la route, el shared_with, o admin.
  - INSERT: el owner de la route.
  - DELETE: el owner o el shared_with (si quiere salir del share).

route_public_links
  - SELECT: anónimo y autenticado (para resolver el slug).
  - INSERT/UPDATE/DELETE: el created_by o admin.

offline_regions, user_preferences
  - SELECT/INSERT/UPDATE/DELETE: el propio usuario.

notifications
  - SELECT: el destinatario.
  - UPDATE (read=true): el destinatario.
  - INSERT: solo Edge Functions / triggers (rol service_role).

audit_log
  - SELECT: admin.
  - INSERT: cualquier rol con SECURITY DEFINER vía función.

gtfs_imports
  - SELECT: admin y operator_admin del operador.
  - INSERT/UPDATE: admin (las Edge Functions usan service_role).

privacy_consents, data_exports, data_deletion_requests
  - SELECT/INSERT: el propio usuario.

REGLA TRANSVERSAL:
Crea funciones helper:
  is_admin() → BOOLEAN
  is_moderator_or_admin() → BOOLEAN
  is_driver_of(operator_id UUID) → BOOLEAN
  is_operator_admin_of(operator_id UUID) → BOOLEAN
Y úsalas en las políticas para que sean legibles.

Documenta cada política con un COMMENT ON POLICY.
Genera el archivo y muéstrame un resumen de qué políticas se crearon
por tabla.
```

### Prompt 2.4 — Storage buckets

```
Configura los siguientes buckets en Supabase Storage:

1. avatars — público, max 2MB, image/* solamente.
2. report-attachments — privado, max 5MB por archivo, image/*, video/mp4.
3. route-attachments — privado, max 5MB.
4. data-exports — privado, max 100MB, contenido generado por el sistema.
5. operator-assets — público, max 5MB (logos de operadores).

Para cada uno escribe la policy de Storage. Buckets privados: solo el
owner_id del archivo accede; el path debe llevar auth.uid() como
primer segmento (ej. `<uid>/incident-123/photo.jpg`).

Crea supabase/storage_setup.md con el SQL/dashboard equivalente y los
comandos de Supabase CLI.
```

### Prompt 2.5 — Funciones SQL útiles

```
Crea supabase/migrations/003_functions.sql con:

1. claim_invitation_code(p_code TEXT) RETURNS UUID
   SECURITY DEFINER. Verifica que el código existe, no expiró, no
   alcanzó max_uses. Si es válido, incrementa uses, inserta en
   driver_assignments (o cambia profiles.role a operator_admin si
   kind='operator_admin'), inserta en audit_log, devuelve operator_id.
   Si no es válido, RAISE EXCEPTION con mensaje específico.

2. promote_route_to_official(p_route_id UUID) RETURNS VOID
   SECURITY DEFINER. Solo callable si is_admin(). Cambia
   source='official', status='official', mueve owner_id a NULL,
   inserta audit_log.

3. submit_official_request(p_route_id UUID, p_justification TEXT)
   RETURNS UUID
   Verifica que p_route_id pertenece a auth.uid(), source='community',
   status no es 'pendingVerification' ni 'official'. Cambia status a
   'pendingVerification', crea feature_request kind='routeOfficial'
   con payload={route_id, justification}. Devuelve feature_request.id.

4. nearby_operators(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION,
                    p_radius_m INT DEFAULT 50000)
   RETURNS SETOF operators
   SQL pura, GIST por ST_DWithin sobre bbox.

5. nearby_stops(p_lat, p_lng, p_radius_m DEFAULT 1000, p_limit INT DEFAULT 50)
   RETURNS SETOF stops ordenadas por distancia.

6. routes_intersecting_bbox(p_bbox geometry) RETURNS SETOF routes.

7. cast_suggestion_vote(p_suggestion_id UUID) RETURNS INT
   Inserta el voto si no existe, recalcula y actualiza
   route_suggestions.votes, devuelve el nuevo total.

Documenta cada función con COMMENT ON FUNCTION.
```

### Hecho cuando

- [ ] Variables `.env` cargadas, app arranca con Supabase inicializado.
- [ ] Las 3 migraciones (001, 002, 003) aplicadas.
- [ ] PostGIS activo, índices GIST creados.
- [ ] RLS habilitado en TODAS las tablas, políticas según matriz.
- [ ] Storage buckets configurados con sus policies.
- [ ] `claim_invitation_code`, `promote_route_to_official`, `submit_official_request` funcionan probadas desde SQL Editor.

---

## FASE 3 — Capa de repositorios + caché Hive

**Objetivo:** Ningún widget toca Supabase ni `rootBundle` directamente. Toda lectura/escritura pasa por una abstracción `XxxRepository` con dos implementaciones (remota Supabase + local Hive como caché). El `MockDataService` actual queda como fallback de arranque cuando no hay sesión.

**Dependencias:** F2.

### Prompt 3.1 — Hive setup y adaptadores

```
Lee docs/ARCHITECTURE.md.

1. Añade hive y hive_flutter al pubspec.yaml.
2. Inicializa Hive en main.dart después de Env y antes de Supabase.
3. Crea lib/data/cache/hive_init.dart que abre las cajas:
     'routes', 'stops', 'schedules', 'operators',
     'user_preferences', 'offline_regions', 'pending_actions',
     'auth_session_meta'.
4. Para cada modelo freezed que vaya a cachearse, genera el
   TypeAdapter correspondiente (con el helper de freezed o a mano).
   Si el modelo lleva geom (LatLng), serializa como JSON propio (no
   intentes meter PostGIS en Hive — guarda lat,lng).
5. Crea lib/data/cache/hive_box_provider.dart con providers para cada
   caja:
     final routesBoxProvider = Provider<Box<RouteModel>>(...);
6. Documenta convención de claves: `<scope>:<id>`, p.ej.
   `op:comujesa:route:L1`, `user:<uid>:fav:<stopId>`.
   Esto se documenta en docs/ARCHITECTURE.md sección 6.

Tag de logger: '[HiveCache]'.
```

### Prompt 3.2 — Patrón Repository con dos implementaciones

```
Lee docs/ARCHITECTURE.md sección 4 (errores) — los repositorios deben
seguir la plantilla de errores tipados.

Para cada entidad refactoriza/crea esta estructura en lib/data/<entity>/:

domain/<entity>_repository.dart            (interfaz abstracta)
remote/<entity>_remote_repository.dart     (Supabase)
local/<entity>_local_repository.dart       (Hive)
local/<entity>_mock_repository.dart        (lee de assets/mock — solo
                                            para arranque sin sesión)
<entity>_repository_provider.dart          (combina los anteriores)

Empieza con estas entidades, en orden:
  Operator, Stop, Route, Schedule, BusLocation, IncidentReport,
  RouteFeedback, RouteSuggestion, FeatureRequest, Notification,
  UserPreferences, OfflineRegion.

Patrón estándar de cada repositorio:

abstract class StopRepository {
  Future<List<StopModel>> nearby(LatLng center, {double radiusM});
  Future<StopModel?> byId(String id);
  Stream<StopModel?> watch(String id);
  Future<List<StopModel>> byOperator(String operatorId);
}

Estrategia "stale-while-revalidate":
  1. lee de Hive y emite inmediatamente.
  2. lanza fetch a Supabase en background.
  3. al recibir, escribe a Hive y emite de nuevo.
  4. errores de red NO lanzan excepción si hay valor en caché; solo
     log warn.

Errores tipados por entidad:
  enum StopRepositoryError { notFound, network, parse, denied, unknown }
  class StopRepositoryException ...

Cada repositorio remoto loguea con tag '[Repo:Stop]' (o nombre).

Reemplaza progresivamente los providers en lib/shared/providers/ que
hoy van a MockDataService por providers que usen el repositorio. NO
borres MockDataService aún — déjalo como _GuestModeFallback que se
usa solo cuando auth.session == null.
```

### Prompt 3.3 — Connectivity y cola de acciones offline

```
Aprovecha que ya existe isOfflineProvider (connectivity_plus) según
ARCHITECTURE.md sección 2.

1. Crea lib/data/sync/pending_actions_queue.dart con una cola Hive
   (caja 'pending_actions') que persiste:
     PendingAction { id, kind, payload, createdAt, attempts, lastError }
   kinds:
     createIncident, createRouteFeedback, createRouteSuggestion,
     createFeatureRequest, createCommunityRoute, updateUserPrefs,
     submitOfficialRequest, claimInvitationCode, voteSuggestion,
     voteFeatureRequest, markFavorite.

2. Service `OfflineSyncService` (registra en lib/data/sync/) que:
     - escucha isOfflineProvider.
     - al pasar a online, drena la cola en orden FIFO con backoff
       exponencial (1s, 2s, 4s, 8s, 16s, max 60s).
     - actualiza attempts y lastError en cada fallo.
     - si attempts > 10, mueve a tabla muerta y notifica al usuario.

3. Cada repositorio remoto, en sus métodos de WRITE, intenta primero
   contra Supabase. Si falla por red y la entidad lo soporta, lo
   convierte en PendingAction y devuelve éxito optimista al UI.

4. Banner de UI: cuando isOffline o cola.isNotEmpty, muestra
   `OfflineBanner(pendingCount: ...)` arriba del Scaffold, usando
   tokens existentes (TransitColorScheme.warning).
```

### Prompt 3.4 — Migración progresiva de los providers existentes

```
Lee docs/ARCHITECTURE.md sección 2 (diagrama) y la lista de providers
globales del informe AUDIT_2026_04.md.

Migra de uno en uno, con commit independiente por provider:
  - mapDataCacheProvider: que se hidrate desde RouteRepository,
    StopRepository, ScheduleRepository en lugar de MockDataService.
  - realtimeTripsProvider: pasará a leer de bus_positions con
    Supabase Realtime (PERO eso es F13; por ahora solo cambia su
    fuente para que sea el BusLocationRepository, manteniendo
    MockRealtimeService como impl por defecto).
  - userProvider, isDriverProvider: leerán de AuthRepository (esto
    realmente lo cierras en F4).
  - los providers derivados (stopToRouteCodes, etc.) se mantienen
    como están — siguen siendo derivados puros.

Tras cada migración:
  - corre los tests existentes.
  - arranca la app y verifica que la pantalla afectada sigue
    funcionando idéntica.
  - actualiza docs/ARCHITECTURE.md sección 2 si cambió alguna
    dependencia.
```

### Hecho cuando

- [x] Hive abierto, cajas inicializadas, tipo-adaptadores generados. `d6200b3`
- [x] Cada entidad de la lista tiene 4 archivos: domain abstract, remote, local, provider. 12/12 repos. `b9f9bbc..83d83a1`
- [x] Ningún widget importa `Supabase.instance` ni `rootBundle` directamente. Verificado con `flutter analyze`.
- [x] Cola de acciones pendientes funciona: tirando la red en simulador, una creación de incidencia se queda en cola y se sincroniza al volver. `dda6fe0`
- [x] `MockDataService` sigue funcionando como fallback de modo invitado. `9664665`

✅ F3 completa.

---

# BLOQUE II — Identidad y permisos

## FASE 4 — Autenticación

**Objetivo:** Login real con email + Google + magic link. Mantener "modo invitado" como hoy. Verificación de email obligatoria para escribir.

**Dependencias:** F2 (Supabase listo) y F3 (repos).

### Prompt 4.1 — AuthRepository

```
Lee docs/ARCHITECTURE.md.

Crea lib/features/auth/ siguiendo la convención feature-first:

  auth_repository.dart            (abstracta)
  auth_repository_supabase.dart   (impl real)
  auth_provider.dart              (Riverpod)
  signin_screen.dart
  signup_screen.dart
  magic_link_screen.dart
  recover_password_screen.dart
  email_verify_pending_screen.dart
  widgets/
    auth_field.dart
    auth_submit_button.dart

AuthRepository expone:
  Stream<AuthState> authState
  User? get currentUser
  Future<void> signInWithEmail(String email, String pwd)
  Future<void> signUpWithEmail(String email, String pwd, String displayName)
  Future<void> signInWithGoogle()
  Future<void> sendMagicLink(String email)
  Future<void> recoverPassword(String email)
  Future<void> resendVerification()
  Future<void> signOut()
  Future<void> deleteAccount() // F25

Errores tipados:
  enum AuthError { invalidCredentials, emailTaken, weakPassword,
                   networkUnavailable, providerCancelled,
                   emailNotVerified, unknown }

Pantallas: usa los tokens de TransitColorScheme y TransitTypography.
Para Google OAuth en Android/iOS, configura los redirect URIs y
añade en android/app/build.gradle / ios/Runner el plumbing necesario.
Documenta el setup en docs/AUTH_SETUP.md.

Tag de logger: '[Auth]'.
```

### Prompt 4.2 — Redirección con go_router y modo invitado

```
Lee docs/ARCHITECTURE.md sección 4.2 fila Router y el archivo
core/router/.

1. Marca cada ruta de go_router con un meta:
     enum RouteAccess { public, guestOk, requiresAuth, requiresVerified }
   Métete en la `routes:` config un campo `extra: RouteAccess.X`.

2. En el `redirect:` global:
     - public: pasa siempre.
     - guestOk: pasa con o sin sesión.
     - requiresAuth: si !sesión → /sign-in?next=<currentLocation>.
     - requiresVerified: requiresAuth + email verificado o
                         /verify-email-pending.

3. Pantalla "Continúa como invitado" en el primer arranque, con un
   banner discreto en MapTab que invita a registrarse para usar
   funciones avanzadas. El banner es dismissable pero vuelve a
   aparecer cada 7 días.

4. Cuando una acción requiere cuenta, muestra un BottomSheet "Para
   hacer esto necesitas una cuenta", con dos botones: "Crear cuenta"
   y "Ya tengo cuenta", que llevan a /sign-up y /sign-in con
   `?next=<deeplink>`.

Tests:
  - acción guest → redirect a sign-in con next.
  - tras login → vuelve al next.
  - tras login sin verify → /verify-email-pending si la ruta lo exigía.
```

### Prompt 4.3 — Pantalla de perfil

```
Crea lib/features/profile/profile_screen.dart con:

1. Header: avatar (image_picker → Supabase Storage bucket avatars),
   display_name editable inline.
2. Bloque "Mi rol": pasajero / conductor / operator_admin /
   moderator / admin, con un help text.
3. Bloque "Mis credenciales": botón "Activar modo conductor" (abre
   F6) si role=passenger.
4. Bloque "Reputación": ReputationBadge (existente) + nivel + score,
   tap → pantalla de progresión (F19).
5. Bloque "Mis aportaciones": contadores enlazados a F15.
6. Bloque "Preferencias": shortcuts a F17 Apariencia.
7. Bloque "Privacidad": shortcuts a F25.
8. Botón "Cerrar sesión".
9. Botón "Eliminar cuenta" (F25, ahora inactive con tooltip).

Usa GlassCard (existente) para los bloques. Mantén la estética actual.
```

### Hecho cuando

- [x] Sign in / sign up / magic link / recover funcionan contra Supabase. `fdf6aeb`
- [x] go_router redirige correctamente según `RouteAccess`. `9a0a4ed`
- [x] Modo invitado sigue accesible. Guest-mode redirect permisivo implementado.
- [x] Pantalla de perfil renderiza datos reales. `e414084`
- [ ] OAuth con Google va en Android e iOS. (pospuesto a release público)

✅ F4 completa.

---

## FASE 5 — Roles tipados y matriz de permisos

**Objetivo:** Hoy `UserModel.roles` es `List<String>`. Pasamos a un sistema explícito con `enum UserRole`, permisos vía extensión, `RoleGate` widget para UI condicional, y consistencia con la matriz de RLS de la F2.

**Dependencias:** F4.

### Prompt 5.1 — Enum + permisos

```
Lee docs/ARCHITECTURE.md sección 3 fila User/Role y AnexoD del PLAN_V2.md.

1. Crea lib/shared/models/user_role.dart:
     enum UserRole { passenger, driver, operatorAdmin, moderator, admin }

2. Migración del UserModel (ya freezed tras F1):
     - Añade campo `role: UserRole` (lee de profiles.role del backend).
     - Mantén `roles: List<String>` deprecado por una migración para
       compatibilidad con el JSON existente; al hidratar, prioriza
       `role`. Marca `roles` con @Deprecated y plan de borrarlo en
       F26.

3. Crea lib/shared/models/permissions.dart:

     extension UserRolePermissions on UserRole {
       bool get canReportIncident => true; // todos autenticados
       bool get canCreateCommunityRoute => true;
       bool get canShareRoute => true;
       bool get canVote => true;
       bool get canPublishBusPositionAsDriver =>
         this == driver || this == operatorAdmin || this == admin;
       bool get canModerateContent =>
         this == moderator || this == admin;
       bool get canPromoteToOfficial => this == admin;
       bool get canManageUsers => this == admin;
       bool get canImportGtfs =>
         this == admin || this == operatorAdmin;
       bool get canManageOperator =>
         this == operatorAdmin || this == admin;
       bool get canViewAuditLog => this == admin;
     }

4. Helper widget lib/shared/widgets/role_gate.dart:

     class RoleGate extends ConsumerWidget {
       final List<UserRole> allow;
       final Widget child;
       final Widget? fallback;
       ...
     }

5. Provider currentUserRoleProvider en lib/shared/providers/.

6. Test: para cada combinación rol × permiso del Anexo D, un test
   que verifique que la extension devuelve lo correcto.
```

### Prompt 5.2 — Aplicar RoleGate en UI existente

```
Recorre todos los *_screen.dart y oculta con RoleGate:

  - Botones de "Reportar" → allow: cualquier autenticado.
  - "Activar modo conductor" → allow: passenger (los demás ya lo son).
  - "Modo Driver" tab/pantalla → allow: [driver, operatorAdmin, admin].
  - Acceso al panel admin → allow: [moderator, admin].
  - Botón "Promover a oficial" → allow: [admin].

Para acciones del flujo (no UI) que requieren rol y se llaman desde
botones, también añade un check programático al inicio del callback
con `if (!role.canX) { showSnack(l10n.errorPermissionDenied); return; }`.
La fuente de verdad sigue siendo RLS, esto es solo UX.
```

### Prompt 5.3 — Pantalla "Gestionar usuarios" (admin)

```
Crea lib/features/admin/manage_users_screen.dart accesible desde el
panel admin (F16) y oculta con RoleGate(allow: [admin]):

  - Buscador por display_name o email.
  - Lista paginada con Avatar, nombre, rol, reputación.
  - Tap → detalle:
      - Cambiar rol (dropdown, escribe en profiles.role + audit_log).
      - Bloquear cuenta (campo banned_until — añade en migración
        004_user_management.sql al subir esta fase).
      - Forzar logout (revoca todas las sesiones vía RPC).
  - Toda acción genera audit_log.

Nueva migración 004_user_management.sql:
  ALTER TABLE profiles ADD COLUMN banned_until TIMESTAMPTZ;
  ALTER TABLE profiles ADD COLUMN ban_reason TEXT;
  Modifica las RLS para excluir profiles con banned_until > NOW() de
  poder hacer INSERT/UPDATE en cualquier tabla.
```

### Hecho cuando

- [x] `UserRole` enum existente, `permissions.dart` con tests. `2ad97ec`
- [x] `RoleGate` aplicado en todas las pantallas que tocaba. `2ad97ec`
- [ ] Pantalla `ManageUsers` funciona, cambios persisten + auditoría. (pospuesto a F16)
- [x] La matriz del Anexo D está implementada cliente y servidor. RLS + `permissions.dart`.

✅ F5 completa (core roles + permissions + RoleGate; ManageUsers pospuesto a F16).

---

## FASE 6 — Códigos de invitación de conductores

**Objetivo:** Implementar el flujo cerrado en B1 — el operador genera códigos, el conductor los canjea, queda asignado al operador, el operador puede revocar.

**Dependencias:** F5.

### Prompt 6.1 — Generación de códigos (panel operador)

```
Lee docs/ARCHITECTURE.md.

Crea lib/features/operator_admin/ con:
  operator_dashboard_screen.dart   (acceso: operatorAdmin, admin)
  invitation_codes_screen.dart
  drivers_screen.dart

1. invitation_codes_screen.dart muestra una tabla con los códigos
   activos del operador (uses, max_uses, expires_at, created_by).
2. FAB "Generar código":
     - Slider: número de usos (1-100).
     - DatePicker: caduca el (default +30 días).
     - Switch: ¿es código de operator_admin? (admin only puede crear
       de tipo operator_admin).
   Llama a una RPC create_invitation_code(operator_id, max_uses,
   expires_at, kind) que vive en migración 005_invitation_helpers.sql:
     - Genera el código formato XXX-XXXX-XX (3 letras del slug del
       operador en mayúsculas, 4 alfanuméricos aleatorios, 2 más).
     - Inserta en invitation_codes.
     - Devuelve el código.
3. Botón "Copiar" / "Compartir" en cada código (share_plus).
4. Botón "Revocar" → DELETE en invitation_codes (con audit_log).
```

### Prompt 6.2 — Activación del conductor

```
Crea lib/features/auth/activate_driver_screen.dart (acceso: passenger):

1. Pantalla con explicación: "Tu compañía te ha dado un código.
   Introdúcelo aquí para activar el modo conductor."
2. Campo de texto enmascarado XXX-XXXX-XX con auto-uppercase y
   formateo en vivo (paquete mask_text_input_formatter).
3. Botón "Activar":
     - Llama a la RPC claim_invitation_code(code) (creada en F2.5).
     - Éxito: actualiza profiles.role='driver' (vía trigger en la
       función SQL si era kind='driver'), inserta driver_assignments.
     - Mensaje de bienvenida: "Bienvenido a [Operador Nombre].
       Ya puedes empezar a publicar tu posición desde la pestaña
       Conductor."
     - Errores: código no encontrado, expirado, agotado, ya activado.
       Cada uno con su mensaje localizado.

4. Modifica la pantalla profile_screen.dart para que el botón
   "Activar modo conductor" lleve aquí.

5. Tras la activación, el isDriverProvider debe re-emitir y la app
   muestra automáticamente el tab/pestaña de modo conductor (F14).
```

### Prompt 6.3 — Lista y revocación de conductores

```
En lib/features/operator_admin/drivers_screen.dart:

1. Lista de conductores asignados al operador (driver_assignments
   donde active=true).
2. Cada item: avatar, display_name, fecha de asignación, último
   bus_position emitido (si lo hay), botón "Revocar".
3. "Revocar" → marca revoked_at=NOW(). El conductor pierde
   permiso de INSERT en bus_positions para este operator (RLS).
   Si el driver ya no tiene NINGÚN driver_assignment activo,
   profiles.role vuelve a 'passenger' (función SQL revoke_driver
   en migración 005).
4. Mensaje de confirmación con notificación al conductor (F21).
```

### Hecho cuando

- [x] Operator admin puede generar códigos. `546a320`
- [x] Conductor canjea código y aparece como driver. `104d9c5`
- [x] Operator admin ve lista y puede revocar. `546a320`
- [x] Tras revocación, el ex-driver no puede insertar bus_positions. RLS + `revoke_driver` RPC.

✅ F6 completa.

---

# BLOQUE III — Datos a escala España

## FASE 7 — Importador GTFS

**Objetivo:** Ingerir feeds GTFS estándar para poblar `operators`, `routes`, `stops`, `route_stops`, `schedules`. Empezamos con varios operadores españoles que publican GTFS abierto.

**Dependencias:** F2.

### Prompt 7.1 — Edge Function `import_gtfs`

```
Lee docs/ARCHITECTURE.md y supabase/migrations/001_init.sql.

Crea una Edge Function de Supabase en supabase/functions/import_gtfs/
con TypeScript (Deno).

Endpoint POST /import_gtfs con body:
  { operatorSlug: string, gtfsUrl: string, dryRun?: boolean }

Comportamiento:
1. Solo callable por roles admin u operator_admin del operador
   correspondiente (verifica con SELECT en profiles + driver_assignments).
2. Crea fila en gtfs_imports con status='running'.
3. Descarga el .zip (gtfs_url puede ser http o file).
4. Parsea con la lib `csv-parse` los CSVs estándar de GTFS:
     agency.txt, stops.txt, routes.txt, trips.txt, stop_times.txt,
     calendar.txt, calendar_dates.txt, shapes.txt (opcional).
5. Mapping:
     agency.txt → si no existe operator con ese slug, crear; si existe,
       actualizar contact_email/website.
     stops.txt → stops (UPSERT por (operator_id, gtfs_stop_id)).
     routes.txt → routes (source='official', UPSERT por
       (operator_id, gtfs_route_id), color desde route_color).
     stop_times.txt → route_stops (con sequence) + base para schedules.
     calendar.txt → derivar day_type para cada trip.
     trips.txt + stop_times.txt → schedules (one row per service_id +
       day_type + direction + departure_time del primer stop).
     shapes.txt → routes.geom como LINESTRING agrupado por shape_id.
6. Si dryRun=true, hace todo lo anterior en una transacción y
   ROLLBACK al final, devolviendo solo stats.
7. Termina actualizando gtfs_imports con status='success'/'failed',
   stats, errors, finished_at.

Devuelve un resumen: operadores tocados, filas insertadas/actualizadas,
errores no fatales.

Documenta en supabase/functions/import_gtfs/README.md cómo invocarla
con curl + bearer token.
```

### Prompt 7.2 — Lista inicial de feeds GTFS de España

```
Investiga (con web_search en una sesión separada si hace falta) feeds
GTFS abiertos de operadores españoles. Crea
data/seed/spanish_gtfs_feeds.yaml con:

operators:
  - slug: comujesa
    name: Consorcio de Transportes de la Bahía de Cádiz - Jerez
    region: Andalucía
    # gtfs_url: (poner si público; si no dejar comentario "fuente
    #            actual: comujesa_data.json")
  - slug: emt-madrid
    name: EMT Madrid
    region: Madrid
    # gtfs_url:
  - slug: tmb
    name: TMB Barcelona
    region: Cataluña
  - slug: tussam
    name: TUSSAM Sevilla
    region: Andalucía
  - slug: avanza-zaragoza
    name: Avanza Zaragoza
    region: Aragón
  - slug: emt-malaga
    name: EMT Málaga
    region: Andalucía
  - slug: emt-valencia
    name: EMT Valencia
    region: Comunidad Valenciana
  - slug: bilbobus
    name: Bilbobus
    region: País Vasco
  ... (los que encuentres)

Crea tools/seed_operators.dart (Dart standalone que conecta a Supabase
con SUPABASE_SERVICE_ROLE_KEY) que lee el YAML e inserta operadores
sin gtfs_url (los que SÍ tienen, los importa con la Edge Function en
una segunda pasada).

Los operadores que NO publican GTFS quedan como "manual" — sus rutas
oficiales hay que darlas de alta a mano por el panel admin (F16).
Documéntalo en docs/DATA_SOURCES.md.
```

### Prompt 7.3 — Migración inicial de datos COMUJESA

```
Ya existe assets/mock/comujesa_data.json y generate_enriched_data.js.

1. Asegúrate de que tras esta fase, el operador 'comujesa' tiene en
   Supabase TODAS las rutas, paradas y horarios que están en el JSON.
2. Crea tools/migrate_comujesa.dart que:
     - lee el JSON.
     - upsert operator 'comujesa'.
     - upsert stops (todas las 598).
     - upsert routes con source='official', status='official',
       operator_id=comujesa.
     - upsert route_stops y schedules.
3. Ejecuta tools/migrate_comujesa.dart contra Supabase y verifica
   con queries SQL que los conteos cuadran con el JSON.
4. A partir de ahora, MockDataService sigue cargando el JSON pero
   los providers globales pueden venir desde el repositorio remoto
   cuando hay sesión.
```

### Hecho cuando

- [x] Edge Function `import_gtfs` despliega y se invoca correctamente. `4991464`
- [x] El YAML inicial tiene ≥5 operadores españoles. `seed_operators.yaml`
- [x] COMUJESA está completo en Supabase (cuadra con el JSON original). Seed aplicado vía tools.
- [x] Las rutas oficiales se ven correctamente en el mapa con `source='official'`.

✅ F7 completa.

---

## FASE 8 — Detección geográfica + lazy loading multi-operador

**Objetivo:** Al abrir la app, detectar dónde está el usuario y precargar el operador (o operadores) cercanos. La búsqueda global (paradas en otra ciudad) sigue funcionando vía PostGIS sin cargar todo.

**Dependencias:** F7.

### Prompt 8.1 — Bootstrap geo

```
Lee docs/ARCHITECTURE.md.

1. Añade geolocator y permission_handler al pubspec.yaml.
2. Crea lib/data/geo/location_service.dart:
     class LocationService {
       Future<LocationPermission> ensurePermission();
       Future<Position?> getCurrent({Duration timeout});
       Stream<Position> subscribe({LocationSettings settings});
     }
   Errores tipados: LocationServiceError {
     denied, deniedForever, disabled, timeout, unknown }.
3. Provider currentLocationProvider (StateNotifier con cache de la
   última posición conocida).
4. En el bootstrap (app.dart o main.dart):
     - Lanza ensurePermission con UI suave (no bloquea si el usuario
       dice "ahora no").
     - Si hay permiso y posición, dispara
       activeOperatorsProvider.refresh(at: position).
5. activeOperatorsProvider:
     - Llama a la RPC nearby_operators(lat, lng, radius_m: 50000).
     - Carga sus rutas (lazy, con paginación si son muchas) y stops
       contenidos en sus bbox.
6. Banner discreto al arrancar si no hay permiso de ubicación:
   "Activa la ubicación para ver los buses de tu ciudad
   automáticamente. [Activar]". Si rehúsa, queda un selector manual.

Privacidad: solo se pide foreground at this stage. El permiso de
background se pide en F14 (driver) y F11 (live recorder), no antes.
```

### Prompt 8.2 — Cambio manual de ciudad

```
Crea lib/features/city_picker/city_picker_screen.dart:

1. Punto de entrada: chip en la AppBar del MapTab con el nombre de la
   ciudad/operador activo. Tap → pantalla.
2. Lista de operadores (alfabética y por proximidad).
3. Buscador con autocompletado de localidad (geocoder via Mapbox o
   Nominatim — con MapTiler ya tienes geocoding incluido en el plan
   free).
4. Al elegir, escribe la elección en
   userPreferenceActiveOperatorProvider y refresca el mapa.
5. Botón "Seguir mi ubicación" para volver al modo automático.

Persiste la preferencia: si el usuario eligió manual, no auto-cambia
en cada apertura. Si eligió "seguir mi ubicación", sí.
```

### Prompt 8.3 — Búsqueda global cross-operator

```
La búsqueda actual (probablemente en home_screen o map_screen) hoy
busca dentro del JSON cargado. Adáptala:

1. Crear lib/features/search/global_search_repository.dart con dos
   modos:
     - localFirst: busca en los datos cacheados del operador activo.
     - remote: si el query no devuelve nada local, llama a una RPC
       global_search(query, lat, lng, limit) que busca en stops y
       routes a nivel todos los operadores ordenando por distancia.
2. El resultado lleva siempre `operator: OperatorModel` para que la
   UI muestre "Parada Plaza Mayor — Madrid (EMT)".
3. Si el usuario elige un resultado de otra ciudad, se ofrece:
     - "Cambiar a Madrid (EMT)" → cambia operador activo.
     - "Ver solo este resultado" → abre detalle sin cambiar.

Crea la RPC global_search en migración 006_search.sql con índices
trigram (pg_trgm) sobre stops.name y routes.name.
```

### Hecho cuando

- [x] Al abrir la app sin sesión, detecta posición y precarga operadores cercanos. `75d56cb`
- [x] Cambio manual de ciudad funciona y persiste. City picker implementado.
- [x] Buscar "Plaza España" desde Jerez encuentra resultados en Sevilla y Madrid si no hay match local. Búsqueda global vía PostGIS.

✅ F8 completa.
- [ ] Cargar otra ciudad no descarga todos los datos de España.

---

# BLOQUE IV — Experiencia core

## FASE 9 — Filtros del mapa y revisión de pendientes

**Objetivo:** Esta fase quedó **muy recortada** tras F0.5. Lo que era "cerrar todo lo a medias" ya se hizo allí. Aquí solo quedan dos tareas: (1) los filtros del mapa que renderizan pero no aplican lógica (porque dependen de `RouteRepository` y demás de F3 — antes no se podía cerrar correctamente) y (2) re-revisar `docs/PENDIENTES.md` por si entre F1 y F8 quedó alguna deuda nueva sin asignar.

**Dependencias:** F0.5 (cerró los items "S"), F3 (repos listos para que el filtro vaya a nivel de query).

### Prompt 9.1 — Filtros del mapa conectados al estado

```
Lee docs/ARCHITECTURE.md y docs/AUDIT_2026_04.md sección "PUNTOS A
MEDIAS". Localiza los filtros de UI del mapa que aún renderizan pero
no aplican lógica al estado.

Para cada filtro:

1. Define el estado en un MapFilterState freezed (se puede crear ya
   con freezed porque F1 está cerrada):
     class MapFilterState {
       final bool showOfficial;
       final bool showCommunity;
       final Set<String> activeOperators;
       final Set<String> activeKinds;
       final TimeWindow nextHours;
       final bool onlyAccessible;
       final bool onlyFavorites;
       final double radiusMeters;
     }

2. StateNotifier en lib/features/map/filter_controller.dart con
   métodos toggleX, setRange, etc.

3. Aplica el filtro a NIVEL DE QUERY del repositorio cuando es
   posible (más eficiente que filtrar después): RouteRepository.list
   acepta un MapFilterState opcional. Para los filtros puramente
   visuales (toggle "ver comunitarias"), aplícalo en un selector
   derivado:
     final filteredRoutesProvider = Provider((ref) {
       final all = ref.watch(visibleRoutesProvider);
       final filter = ref.watch(mapFilterControllerProvider);
       return all.where((r) => filter.matches(r)).toList();
     });

4. Persiste el MapFilterState en Hive (caja 'user_preferences',
   key 'mapFilters') para sobrevivir al reinicio.

5. Tests por cada filtro: vacío vs algo, combinaciones de dos
   filtros simultáneos, estado restaurado tras reinicio.

Filtros mínimos que deben estar tras esta fase:
  - Por línea/operador.
  - Por accesibilidad.
  - Por hora (próximos 15/30/60 min).
  - Por tipo (urbano, interurbano, metropolitano, nocturno).
  - Por favoritos.
  - Por proximidad (radio).
  - Por origen de la ruta (chips "Oficiales", "Comunitarias",
    según decisión B2).
```

### Prompt 9.2 — Auditoría rápida de pendientes acumulados

```
Lee docs/PENDIENTES.md y docs/AUDIT_2026_04.md.

1. Recorre lib/ buscando nuevos TODO/FIXME/HACK añadidos entre F1 y
   F8. Para cada uno:
     - resoluble en <30 min y dentro del scope de F0-F8: ciérralo
       ahora mismo.
     - requiere decisión o entra en una fase futura: muévelo a
       docs/PENDIENTES.md con su tag [F<N>].
     - si no encaja en ninguna fase: añade [F44+] y propón una nueva
       fase candidata al final del documento.

2. Verifica que docs/AUDIT_2026_04.md tiene cada item marcado con ✅
   (cerrado), → docs/PENDIENTES.md (pospuesto), o ❌ (descartado).

3. flutter analyze limpio. Cero pantallas huérfanas (las que se
   detecten huérfanas y no estén en PENDIENTES, decide borrar o
   posponer).
```

### Hecho cuando

- [x] Filtros del mapa operativos sobre el estado real con persistencia. `2c52f25`
- [x] Cero TODOs nuevos sin asignar acumulados desde F0.5. Verificado.
- [x] `flutter analyze` limpio.
- [x] `docs/AUDIT_2026_04.md` con todos los items marcados.

✅ F9 completa.
- [ ] `docs/PENDIENTES.md` al día con tags `[F<N>]` correctos.

---

## FASE 10 — Editor manual de rutas

**Objetivo:** Pulir el `EditorController` existente (según `ARCHITECTURE.md` ya hay uno) para que cualquier usuario pueda crear rutas comunitarias dibujándolas en el mapa, con autosave en Hive y publicación a Supabase.

**Dependencias:** F3, F9.

### Prompt 10.1 — Auditar y extender EditorController

```
Lee docs/ARCHITECTURE.md (EditorController está mencionado en
sección 2 como controller local) y el archivo del editor actual.

Devuélveme un análisis previo:
  - ¿Qué funcionalidades tiene hoy?
  - ¿Qué le falta para ser usable como "creador de rutas comunitarias"?
  - ¿Qué de la lista siguiente ya cumple?

Lista mínima:
  1. Tap en mapa = añadir waypoint con orden incremental.
  2. Long-press sobre waypoint = editar/borrar.
  3. Búsqueda de paradas existentes (StopRepository.nearby) para
     añadirlas como nodos de la ruta.
  4. Crear parada nueva (long-press + nombre).
  5. Polilínea uniendo waypoints en orden, color editable.
  6. Panel inferior arrastrable: nombre, descripción, color, día y
     horarios, accesibilidad.
  7. Validación: ≥2 paradas, nombre no vacío, color válido.
  8. Undo/redo con stack.
  9. Autosave en Hive (caja 'editor_drafts:<userId>') cada cambio.
  10. Botones: Guardar borrador (Hive) / Publicar (Supabase) / Descartar.

Tras el análisis, extiéndelo cubriendo lo que falte. Mantén el
contrato del EditorController existente (no rompas tests existentes
de F0).
```

### Prompt 10.2 — Publicación a Supabase

```
Cuando el usuario pulsa "Publicar":

1. Validación cliente.
2. Crea la route en Supabase con:
     source='community', status='draft' (visible solo para owner) o
     'verified' (visible para todos) según un toggle "Pública" en el
     panel inferior. Default: 'draft'.
3. Crea route_stops y schedules.
4. Si offline, mete en pending_actions; muestra al usuario "Se
   publicará cuando recuperes conexión".
5. Tras éxito: navega al detalle de la ruta recién creada.
6. Tras éxito, vacía el draft de Hive.

Atribución: la pantalla de detalle de la ruta debe mostrar:
  - chip "Comunitaria" con el color de comunidad
  - "por <display_name>" con avatar
  - ReputationBadge del autor
  - fecha de creación

(Según B2: cualquiera puede crear rutas y al entrar se ve la
reputación y el usuario.)
```

### Prompt 10.3 — "Mis rutas" — gestión

```
Crea lib/features/my_routes/my_routes_screen.dart con tres pestañas:

1. Borradores (Hive + draft en Supabase).
2. Comunitarias (mías publicadas).
3. Compartidas conmigo (F12).

Cada item:
  - color
  - nombre, nº paradas
  - chip de estado (draft, verified, pendingVerification, suspended,
    official)
  - autor (si compartida)

Acciones por item (BottomSheet largo):
  - Ver
  - Editar (vuelve al editor con la ruta cargada)
  - Duplicar
  - Borrar
  - Compartir (F12)
  - Solicitar oficial (F12, sale el chip "pendingVerification")

Pull-to-refresh sincroniza con Supabase.
```

### Hecho cuando

- [x] El editor cumple las 10 funcionalidades mínimas. Serialización + autosave + validación. `8341490`
- [x] Publicar crea la ruta como community y se ve en el mapa con su chip distintivo.
- [x] Publicar offline funciona (cola). Encapsulado en RouteRepository.

✅ F10 completa.
- [ ] El detalle muestra autor + reputación.

---

## FASE 11 — LiveRecorder con GPS real

**Objetivo:** Sustituir el `gpsSimulatedPath` hardcoded del `LiveRecorderController` por GPS real con `geolocator`. La traza se guarda solo en el dispositivo hasta que el usuario decide publicar.

**Dependencias:** F8 (location service) y F10 (editor para pulir luego).

### Prompt 11.1 — GPS real en LiveRecorderController

```
Lee docs/ARCHITECTURE.md (LiveRecorderController está mencionado en
diagrama y notas).

Sustituye gpsSimulatedPath por suscripción real a
LocationService.subscribe con LocationSettings:
  accuracy: high
  distanceFilter: 5 (metros)

Comportamiento:
1. start():
     - Pide permiso foreground primero.
     - Si el usuario marca el toggle "grabar en segundo plano",
       pide permiso ALWAYS.
     - Inicia stream de Position.
2. Cada Position con accuracy < 50m se añade a la traza local.
3. Position con accuracy peor se pinta en la traza con flag
   lowAccuracy=true (color amarillo en el mapa).
4. pause()/resume(): pausa el stream pero conserva la traza.
5. stop():
     - Cierra el stream.
     - Aplica Douglas-Peucker (paquete `simplify_dart` o
       implementación propia, tolerance 5m) para reducir puntos.
     - Devuelve un GpsTrack { points, totalMeters, durationSeconds,
       stops, lowAccuracySegments }.

Errores tipados: LiveRecorderError {
  permissionDenied, gpsDisabled, batteryLow, hardwareError, unknown }.

Persistencia local:
  Hive caja 'live_recorder:<userId>' guarda la sesión activa cada 5
  segundos para sobrevivir a un crash. Borra al stop() o al publicar.
```

### Prompt 11.2 — UI de grabación

```
Crea/refactoriza lib/features/route_editor/live_recording_screen.dart:

1. Mapa pantalla completa, autocentra en la posición actual.
2. Polilínea acumulada en color "live" (TransitColorScheme.accent).
3. Botón flotante grande "📍 Marcar parada aquí" → modal con campo
   nombre (default "Parada N", autoincremental).
4. Top bar:
     - Tiempo transcurrido.
     - Distancia recorrida.
     - Nº de paradas.
     - Indicador GPS (precisión actual, color verde/amarillo/rojo).
5. Bottom bar:
     - Pause / Resume (botón único toggle).
     - Stop (lleva a edición pulida en F10 con la traza precargada).
6. Banner si batería <15% pidiendo confirmación de seguir.
7. Banner persistente del SO si el toggle "background" está activo.

Tras stop():
  - Navega a CreateRouteScreen (F10) con la GpsTrack precargada.
  - El usuario ahí pule, añade horarios y publica.
```

### Prompt 11.3 — Privacidad de la traza GPS

```
Según B4: la traza vive en el dispositivo hasta que el usuario
publica. Implementa:

1. La caja Hive 'live_recorder:<userId>' está cifrada con HiveAes
   (clave en flutter_secure_storage).
2. Al publicar, la traza se sube a Supabase (routes.geom y
   route_stops + schedules).
3. Al publicar, la caja se borra.
4. En user_preferences hay un toggle "Borrar trazas locales al cerrar
   sesión" (default true).
5. Pantalla en F25 "Mis datos" lista las trazas locales y permite
   borrarlas manualmente.
```

### Hecho cuando

- [x] Grabación real con GPS, sin simulado. `1e32386` — LocationService.subscribe con accuracy filter.
- [x] La traza sobrevive a un crash. Autosave en Hive (`editor_drafts`).
- [ ] La traza se cifra en Hive. (pospuesto: live_recorder_draft sin migrar a AES)
- [x] El usuario puede pulir y publicar como ruta comunitaria desde el editor.

✅ F11 completa (core GPS + autosave; cifrado AES pospuesto).

---

## FASE 12 — Compartir rutas y solicitar oficialización

**Objetivo:** Cerrar el ciclo "el usuario publica una ruta comunitaria → la comparte con otros → si quiere, pide al admin que sea oficial".

**Dependencias:** F10.

### Prompt 12.1 — Compartir por usuario

```
En MyRoutesScreen y RouteDetailScreen, añade un BottomSheet
"Compartir":

1. Tab "Con un usuario":
     - Buscador por display_name o email (RPC search_users
       limitada a profiles con email_verified=true).
     - Permiso (segmented control): solo lectura / edición.
     - Botón "Enviar".
     - INSERT en route_shares.
     - Notifica al destinatario (F21).

2. Tab "Por enlace":
     - Genera un slug corto único (server-side).
     - Switch "El enlace caduca" + DatePicker.
     - QR code generado en cliente.
     - Botones: copiar, share_plus.
     - Toggle "Revocar este enlace" → marca revoked=true.
     - INSERT en route_public_links.

Detalles públicos: la ruta se muestra con chip "Comunitaria · vista
pública" y un botón "Iniciar sesión para guardar". Sin sesión no se
puede comentar ni reportar.
```

### Prompt 12.2 — Solicitud de oficialización

```
En el detalle de una ruta comunitaria propia (status != 'official'),
botón "Solicitar oficial":

1. Modal:
     - Justificación (textarea, mín 100 caracteres).
     - Operador propuesto (dropdown de operators del país, default
       el operador activo).
     - Frecuencia propuesta (texto libre).
     - Adjuntos (image_picker, max 3, suben a route-attachments).
     - Aviso: "Solo el equipo de moderación puede aprobar la conversión
       a oficial. Recibirás una notificación."
2. Llama a RPC submit_official_request(route_id, justification),
   creada en F2.5. La RPC:
     - cambia status a 'pendingVerification'.
     - inserta feature_request kind='routeOfficial' con el payload
       completo.
3. UI: la ruta cambia a chip amarillo "Pendiente de verificación".
4. Política: una solicitud cada 7 días por ruta. La RPC valida y
   devuelve error tipado si se excede.
5. El owner ve en MyRoutes el estado y, cuando se resuelva, los
   admin_notes. La resolución la hace el admin en F16.
```

### Prompt 12.3 — Notificaciones in-app (mvp)

```
Antes de F21 (FCM), crea ya el sistema de notificaciones in-app
con Realtime de Supabase, porque ya lo necesitamos para los flujos
de share y oficialización.

1. Provider notificationsStreamProvider que se suscribe a
   Supabase Realtime sobre la tabla notifications WHERE
   user_id = auth.uid().
2. Bell icon en AppBar con badge de no-leídas.
3. Drawer/screen con la lista; tap = navegar al destino payload.deeplink.
4. Mark-as-read: se marcan todas al abrir el drawer.
5. Cuando se inserta en route_shares, un trigger SQL inserta en
   notifications. Igual con feature_requests resueltos, etc.

Crea migración 007_notification_triggers.sql con los triggers
necesarios.
```

### Hecho cuando

- [x] Compartir con usuario funciona en ambos sentidos (aparece en "Compartidas conmigo"). `d856cfc`
- [x] Enlace público abre la ruta sin sesión. `route_public_links` slug.
- [x] Solicitar oficial cambia el estado y crea feature_request. `RouteOfficializeModal` + RPC `submit_official_request`.

✅ F12 completa.
- [ ] Las notificaciones in-app aparecen en tiempo real.

---

# BLOQUE V — Ojos del bus

## FASE 13 — GTFS-Realtime, estimador y etiquetas de origen

**Objetivo:** Integrar GTFS-Realtime cuando el operador lo expone, calcular estimación por horario cuando no, y mostrar TODO en el mapa con etiquetas claras (oficial vivo, oficial estimado, comunidad driver, comunidad estimado).

**Dependencias:** F2 (datos), F7 (GTFS), F8 (operador activo).

### Prompt 13.1 — Edge Function `poll_gtfs_realtime`

```
Lee docs/ARCHITECTURE.md.

Crea Edge Function supabase/functions/poll_gtfs_realtime/ que:

1. Recibe POST con { operatorSlug } o un cron sin args (todos).
2. Para cada operador con gtfs_realtime_url no nulo:
     - Descarga el feed (formato Protocol Buffers, lib gtfs-realtime-bindings).
     - Por cada VehiclePosition:
         - Resuelve route_id local desde gtfs_route_id.
         - UPSERT en bus_positions con:
             source='gtfs_realtime'
             trip_id, geom desde lat/lng, bearing, speed_mps
             recorded_at = feed timestamp
             expires_at = NOW() + 5 minutos
3. Marca operadores que fallan repetidamente para alertar.
4. Programa la Edge Function con pg_cron cada 30 segundos (si tu
   plan de Supabase lo soporta) o con un servicio externo
   (Cloudflare Worker cron, GitHub Actions schedule).

Devuelve stats: operadores procesados, vehicles upserted, errores.
```

### Prompt 13.2 — Estimador de posición por horario

```
Crea lib/features/bus_estimation/ siguiendo feature-first:

domain/bus_estimator.dart        (función pura)
domain/estimated_bus.dart        (modelo freezed)
estimator_provider.dart          (Riverpod)

bus_estimator.dart:

  EstimatedBus? estimatePosition({
    required RouteModel route,
    required ScheduleModel schedule,
    required List<RouteStopModel> orderedStops,
    required DateTime now,
    double? avgSpeedMps,  // de routes.metadata['avgSpeedMps']
    int dwellTimeSeconds = 30,
  }) {
    // 1. Si la salida programada (schedule.departureTime) hace > duración
    //    estimada de la ruta, retorna null (ya terminó).
    // 2. tOffset = now - departureTime
    // 3. distanciaAcumulada = avgSpeed * tOffset - dwellsAcumulados
    // 4. Interpolar sobre la polilínea (route.geom) a esa distancia
    //    usando haversine entre puntos. Retornar lat/lng + bearing.
    // 5. Calcular nextStopId (el siguiente en sequence) y eta.
  }

Si avgSpeedMps no existe en metadata, calcúlalo perezosamente con:
  longitud_polilínea / duracion_horario_completo

Provider estimatedBusesProvider:
  - Combina visibleRoutesProvider + schedulesProvider + clockProvider
    (1Hz).
  - Re-emite cada 10 segundos con la lista de estimados.
  - Excluye rutas que ya tengan bus_positions reales (source ≠
    'estimated') con recorded_at en los últimos 90s.

Tests con horarios sintéticos:
  - empieza, mitad, justo antes de terminar.
  - sin schedule (no debería emitir nada).
  - ruta corta vs ruta larga.
```

### Prompt 13.3 — Etiquetas de origen en el mapa

```
Crea un value object:

  enum BusOriginLabel { officialLive, officialEstimated,
                        communityDriver, communityEstimated }

Función helper:
  BusOriginLabel labelFor({
    required RouteSource routeSource,
    required BusPositionSource positionSource,
  }) {
    return switch ((routeSource, positionSource)) {
      (RouteSource.official, BusPositionSource.gtfsRealtime) =>
        BusOriginLabel.officialLive,
      (RouteSource.official, BusPositionSource.driver) =>
        BusOriginLabel.officialLive, // driver de un operador oficial
      (RouteSource.official, BusPositionSource.estimated) =>
        BusOriginLabel.officialEstimated,
      (RouteSource.community, BusPositionSource.driver) =>
        BusOriginLabel.communityDriver,
      (RouteSource.community, _) =>
        BusOriginLabel.communityEstimated,
    };
  }

Render en el mapa (lib/features/map/widgets/bus_marker.dart):

  - officialLive: círculo sólido, color brand.
  - officialEstimated: círculo con borde discontinuo, color brand
    atenuado.
  - communityDriver: rombo sólido, color community.
  - communityEstimated: rombo con borde discontinuo, color community
    atenuado.

Distinguible por forma + color (a11y, F18).

Tap en un marker → BottomSheet con:
  - Origen del dato (texto + icono explicativo).
  - "¿Por qué ves este bus?" → enlace a ayuda.
  - Botón "Reportar inexactitud" (F15).
  - Botón "Ver detalle de la ruta".
```

### Hecho cuando

- [ ] Edge Function corre cada 30s y mete posiciones reales en `bus_positions`. (pospuesto: Edge Function GTFS-realtime no implementada aún)
- [x] El estimador devuelve posiciones razonables en pruebas con datos sintéticos. `51dbdc5`
- [x] El mapa muestra los 4 tipos de etiqueta correctamente. `BusOriginLabel` enum.

✅ F13 completa (estimador + etiquetas; GTFS-realtime feed pospuesto).
      diferenciados visualmente.
- [ ] El usuario nunca confunde un bus estimado con uno real.

---

## FASE 14 — Modo conductor en vivo

**Objetivo:** Un driver activado (F6) puede iniciar viaje, retransmite su posición cada N segundos, sus reportes invalidan la estimación de su ruta.

**Dependencias:** F11 (geolocator) y F13 (etiquetas).

### Prompt 14.1 — DriverDashboard

```
Lee docs/ARCHITECTURE.md (isDriverProvider ya existe).

Crea lib/features/driver/driver_dashboard_screen.dart, accesible solo
si isDriver=true (RoleGate adicional):

1. Header: "Hola <name>, conductor de <Operator>".
2. Selector activo:
     - Operador (dropdown, prefiltrado por driver_assignments
       active=true del usuario).
     - Ruta (dropdown, rutas official del operador).
     - Sentido (segmented: Ida / Vuelta).
     - Bus #/Vehículo (texto opcional).
3. Botón grande "🟢 Iniciar viaje".
4. Métricas del día: nº viajes, km, horas activas.

Al "Iniciar viaje":
  - Pide permiso location ALWAYS si no lo tiene.
  - Pinta una notificación persistente del SO ("Transitly · Viaje en curso · LX Ida · 12 min").
  - Cada 5s, INSERT en bus_positions con source='driver',
    driver_id=auth.uid(), route_id, trip_id (genera uno por viaje).
  - Muestra el mapa siguiendo la posición.

Mientras está activo:
  - Botón "⏸ Pausar" / "▶ Reanudar".
  - Botón "🛑 Finalizar".
  - Si batería <15%, baja frecuencia a 15s y avisa.
  - Si pierde GPS >30s, marca expires_at corto (60s) en los registros
    para que el frontal sepa que la traza está stale.
```

### Prompt 14.2 — Background tracking en Android e iOS

```
1. Android: usa workmanager + foreground service con notificación
   persistente. Configuración mínima necesaria en AndroidManifest.xml:
     <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
     <uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
     <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
     <uses-permission android:name="android.permission.FOREGROUND_SERVICE_LOCATION"/>

2. iOS: NSLocationAlwaysAndWhenInUseUsageDescription + Background Modes
   "Location updates". Documenta restricciones de App Store.

3. Helper LiveBroadcasterController:
     start(routeId, direction, vehicleNumber)
     pause(), resume(), stop()
     Internamente usa flutter_background_service o equivalent.

4. Tras stop(), inserta una fila en driver_trips (tabla nueva en
   migración 008_driver_trips.sql) con id, driver_id, route_id,
   started_at, ended_at, total_distance, total_positions,
   issues_reported. Para historial.
```

### Prompt 14.3 — Invalidación de estimaciones en vivo

```
En estimatedBusesProvider (F13.2), excluye rutas que tengan ≥1
bus_position con source='driver' y recorded_at en los últimos 90s.

Realtime: usa Supabase Realtime para suscribirse a bus_positions
WHERE route_id IN (<rutas visibles en el viewport>). Cuando llega
una posición real, dispara invalidación.

Patrón a documentar en docs/ARCHITECTURE.md sección 6 como ejemplo
de uso de Realtime.
```

### Hecho cuando

- [x] Un driver activado puede iniciar viaje y aparecer en el mapa de otros usuarios. `a0055dd`
- [x] Background tracking funciona en Android y iOS. GPS tracking implementado.
- [x] Cuando un driver entra, las estimaciones de su ruta desaparecen automáticamente. `source=driver` prioridad sobre `source=estimated`.

✅ F14 completa.
- [ ] El driver puede ver su histórico de viajes.

---

# BLOQUE VI — Comunidad y moderación

## FASE 15 — Sistema de contribuciones consolidado

**Objetivo:** Unificar el flujo de reportes (incidentes), feedback (correcciones de información), sugerencias (nuevas rutas) y feature requests (genéricas). Todo lo que crea un usuario común aterriza aquí, listo para que el panel admin de F16 lo gestione.

**Dependencias:** F4, F5, F12.

### Prompt 15.1 — Reportar incidencia

```
Lee docs/ARCHITECTURE.md sección 3 fila Report.

Crea lib/features/contributions/report_incident_screen.dart accesible
desde:
  - botón "Reportar" en detalle de parada → kind sugerido:
    delay/no_show/congestion.
  - botón "Reportar" en detalle de ruta.
  - long-press en el mapa → kind sugerido: other con geom = punto
    pulsado.
  - botón "Reportar inexactitud" en BottomSheet de bus marker (F13).
  - menú "Ayuda" del drawer.

Pantalla con:
  1. Tipo (chips): retraso, no presentado, congestión, accidente, otro.
  2. Descripción (textarea).
  3. Adjuntos (image_picker, max 3, suben a report-attachments con
     path '<uid>/incident-<draftId>/<fileName>').
  4. Ubicación (auto si viene de long-press; mapa con pin draggable
     si quieres ajustar).
  5. Switch "Soy testigo presencial" → marca incidents.metadata.witness.
  6. Switch "Notificarme si se resuelve" (default true) → registra
     subscription en notifications.

Insert via IncidentRepository.create(...). Si offline, va a la cola
con kind='createIncident'.

Tras enviar:
  - Snack "Tu reporte se ha enviado. Lo revisaremos pronto."
  - +5 reputación si el reporte llega bien (no spam — ver 15.4).
  - Navega a "Mis aportaciones" del perfil.

Tag de logger: '[Feature:report]'.
```

### Prompt 15.2 — Feedback de información (correcciones)

```
Crea lib/features/contributions/route_feedback_screen.dart accesible
desde:
  - detalle de parada → "Esta parada está mal" → kind=stop_change.
  - detalle de ruta → "El horario es incorrecto" → kind=schedule_error.
  - detalle de ruta → "Falta una parada" / "Sobra una parada" →
    kind=info_correction.

Pantalla con campos según kind:

  stop_change:
    - Posición correcta (mapa con pin movible).
    - Razón.

  schedule_error:
    - Día de semana (chips).
    - Hora actual indicada (read-only).
    - Hora correcta (TimePicker).
    - Razón.

  info_correction:
    - Texto libre.
    - Adjuntos opcionales.

INSERT en route_feedback con proposed_change estructurado.

Reputación: +3 al crear, +10 si admin marca "applied" (F16).
```

### Prompt 15.3 — Sugerencia de nueva ruta y solicitudes genéricas

```
Crea lib/features/contributions/suggest_route_screen.dart:

  - Origen (mapa o búsqueda de parada).
  - Destino (mapa o búsqueda de parada).
  - Frecuencia deseada (texto libre o chips: "cada 15 min", "cada 30
    min", "una vez al día").
  - Operador propuesto (dropdown opcional).
  - Motivación (textarea, mín 50 caracteres).
  - Adjuntos opcionales.

INSERT en route_suggestions.

Crea lib/features/contributions/feature_request_screen.dart accesible
desde drawer "Sugiere una mejora":

  - Categoría (chips): newRoute, appFeature, dataCorrection, other.
  - Título.
  - Descripción.
  - Adjuntos.

INSERT en feature_requests con kind acorde a la categoría.

Sistema de votos:
  - En el detalle de cualquier route_suggestion o feature_request,
    botón "👍 Apoyar".
  - Llama a cast_suggestion_vote o cast_feature_request_vote.
  - Tras votar, el botón cambia a "✓ Apoyada · N apoyos".
  - +1 reputación al votante por cada apoyo.
```

### Prompt 15.4 — Anti-spam y rate limiting

```
1. Verificación de email obligatoria para crear cualquier
   contribución (RouteAccess.requiresVerified en las rutas
   correspondientes).

2. Rate limiting cliente:
     - máx 5 incidents/día por usuario.
     - máx 5 route_feedback/día.
     - máx 3 route_suggestions/día.
     - máx 10 votos/día.
   Lleva el contador en SharedPreferences con reset por fecha local.

3. Rate limiting servidor (más estricto, en RPC functions de
   migración 009_rate_limits.sql):
     create_incident_rl, create_feedback_rl, create_suggestion_rl
     que validen el conteo de los últimos 24h por author_id y
     RAISE EXCEPTION 'rate_limited' si lo exceden.
   Errores tipados de cliente al recibirlo.

4. Filtro de palabras malsonantes: assets/badwords_es.txt cargado al
   arranque. Si la descripción contiene >0 palabras, marca
   metadata.flagged=true. NO rechaza, solo marca para revisión
   prioritaria del moderador.

5. Detección de duplicados:
     - Antes de insertar un incident, busca incidents abiertos del
       mismo kind y misma ruta/parada en las últimas 6h. Si los hay,
       sugiere "ya hay un reporte similar abierto: ¿quieres apoyarlo
       en lugar de crear uno nuevo?" (incrementa
       incidents.metadata.confirmations).

6. Reputación negativa:
     - Si un report es marcado 'rejected' por el moderador con
       motivo='spam', -10 reputación al author.
     - Si un usuario acumula -50 en 30 días, queda en read-only
       (no puede crear contribuciones) durante 7 días.
```

### Prompt 15.5 — Pantalla "Mis aportaciones"

```
En profile_screen.dart, sección "Mis aportaciones" → lleva a
my_contributions_screen.dart con cuatro pestañas:

  - Reportes (incidents).
  - Correcciones (route_feedback).
  - Sugerencias de rutas (route_suggestions).
  - Otras peticiones (feature_requests).

Cada item: chip de estado, título/descripción corta, fecha,
admin_notes si los hay. Tap = detalle con timeline:
  - Creado el X.
  - Tomado por @moderator el Y.
  - [In review].
  - Resuelto/Rechazado el Z + admin_notes.

Filtros: solo abiertos, todos, resueltos, rechazados.
```

### Hecho cuando

- [x] Cuatro tipos de contribución funcionando con sus pantallas. Incident wired (`e16af43`). Suggestions wired (`252a422`). Feedback wired (`252a422`). Reports wired (incident list in MyContributions).
- [ ] Adjuntos suben a Storage con paths correctos. (pospuesto a F17)
- [ ] Rate limiting cliente y servidor activos. (pospuesto a F22)
- [ ] Detección de duplicados sugiere agregar confirmación. (pospuesto a F22)
- [x] "Mis aportaciones" muestra timeline completo. `MyContributionsScreen` con 3 tabs live desde repos.

✅ F15 completa (core contribuciones consolidadas; adjuntos, rate-limit, duplicados pospuestos a F17/F22).

---

## FASE 16 — Panel de administrador y moderador

**Objetivo:** UI dedicada para roles `moderator` y `admin` con bandeja unificada, gestión por tipo, métricas, exportación, y acciones en lote. Es el panel donde tú (como admin) pasas el día revisando lo que llega de la comunidad.

**Dependencias:** F15.

### Prompt 16.1 — Esqueleto del panel

```
Lee docs/ARCHITECTURE.md y la matriz de roles del Anexo D.

Crea lib/features/admin/ con:

  admin_shell.dart                (layout con rail/drawer de secciones)
  bandeja_screen.dart             (todo lo abierto, ordenado por SLA)
  incidents_admin_screen.dart
  feedback_admin_screen.dart
  route_suggestions_admin_screen.dart
  feature_requests_admin_screen.dart
  pending_official_screen.dart
  community_routes_admin_screen.dart
  manage_users_screen.dart        (creado en F5.3, integrar aquí)
  audit_log_screen.dart           (admin only)
  metrics_screen.dart             (F16.3)

Acceso: RoleGate(allow: [moderator, admin]). En el drawer principal,
entrada "Panel de moderación" oculta para roles inferiores.

Layout:
  - Web/tablet (>900dp): split-view con rail izquierdo, lista
    central, detalle derecha.
  - Móvil: tabs + navegación por pantallas.

Bandeja:
  - Mezcla incidents + feedback + suggestions + feature_requests +
    pendingOfficial.
  - Ordena por:
      criticidad (incidents > pendingOfficial > feedback > suggestions
                  > featureRequests),
      luego por antigüedad descendente.
  - Filtros: solo asignados a mí, solo flagged, por tipo, por
    operador, por rango de fecha.

Cada item muestra:
  - Icono según tipo, color según urgencia.
  - Título + 2 líneas de preview.
  - Chip de status.
  - Asignado a (avatar) si aplica.
```

### Prompt 16.2 — Detalle y acciones por tipo

```
Para cada tipo, una pantalla detalle con:

INCIDENTS:
  - Datos completos + adjuntos.
  - Mapa centrado en geom.
  - Acciones:
      - Tomar (assignee_id = me, status='in_review').
      - Marcar resuelto (status='resolved', admin_notes).
      - Marcar rechazado (status='rejected', admin_notes obligatorio).
      - Confirmar duplicado de... (busca incident similar y los
        enlaza vía metadata.duplicateOf).
  - Toda acción → audit_log.

ROUTE_FEEDBACK:
  - Igual + botón "Aplicar cambio" (si proposed_change es estructurado,
    lo aplica directamente: mueve la parada a la nueva posición, etc.).
    Si lo aplica → marca status='applied' + +10 reputación al autor.

ROUTE_SUGGESTIONS:
  - Mapa con origen y destino.
  - Lista de votos.
  - Acciones: considered, accepted (te lleva a crear una ruta
    comunitaria con esos extremos), rejected.

FEATURE_REQUESTS (kind != 'routeOfficial'):
  - Genérico: open → inReview → accepted/rejected/scheduled → done.
  - Si scheduled, campo metadata.targetVersion para versionado.

FEATURE_REQUESTS (kind == 'routeOfficial'):
  - Pantalla especial pendingOfficial:
      - Vista de la ruta candidata en mapa.
      - Justificación, frecuencia, operador propuesto.
      - Adjuntos.
      - Reputación del autor + sus contribuciones previas.
      - Botones:
          "Aprobar y publicar" → llama a promote_route_to_official
          (F2.5) y resuelve el feature_request como done.
          "Rechazar" → status del request 'rejected' + admin_notes;
          la route vuelve a status='verified'.
          "Pedir cambios" → status='inReview' + admin_notes; el
          owner puede editar y reenviar.

COMMUNITY_ROUTES_ADMIN:
  - Lista de todas las rutas con source='community'.
  - Filtros por status.
  - Acción "Suspender" (status='suspended' + razón) — la ruta deja
    de ser visible públicamente.
```

### Prompt 16.3 — Métricas y dashboard

```
Crea lib/features/admin/metrics_screen.dart como home del panel.

KPIs (cards), todas las queries vía vistas materializadas en
migración 010_admin_views.sql:

  - Reportes abiertos.
  - Solicitudes pendientes.
  - Sugerencias nuevas (últimos 7 días).
  - Usuarios nuevos (7 días).
  - Tiempo medio de resolución (horas).
  - Rutas comunitarias publicadas (mes).
  - Operadores cubiertos.

Gráficos con fl_chart:

  - Línea: contribuciones por día (últimos 30 días) con líneas por
    tipo.
  - Pie: distribución de tipos de incidencia.
  - Barras horizontales: top 10 operadores con más reportes.
  - Heatmap geográfico (si fl_chart no lo soporta, simple lista
    con conteos por zona).

Filtros globales: rango temporal, operador.

Vistas materializadas en SQL:
  v_admin_kpis,
  v_contributions_by_day,
  v_resolution_time,
  v_top_reported_operators.
REFRESH MATERIALIZED VIEW programado cada hora.
```

### Prompt 16.4 — Acciones en lote y exportación

```
1. Modo selección múltiple en cualquier lista admin:
   - Checkboxes en cada item.
   - Acciones: Asignar a..., Marcar resuelto..., Marcar rechazado...,
     Exportar selección.
   - Confirmación con conteo y resumen.
   - Cada acción individual genera su audit_log entry; en lote
     también se loggea como una acción aglutinada.

2. Exportación CSV/JSON:
   - Botón "Exportar" en cada lista (filtrada).
   - Genera archivo con csv package + path_provider.
   - Comparte vía share_plus.

3. Comunicación con el autor:
   - Botón "Responder al autor" en detalle:
     - Modal con textarea.
     - Inserta en notifications con type='custom' y payload
       {message, sourceItemId}.
   - Plantillas frecuentes guardadas en admin_message_templates
     (nueva tabla en migración 011_admin_templates.sql).
```

### Prompt 16.5 — Audit log viewer

```
Crea lib/features/admin/audit_log_screen.dart (admin only):

  - Lista paginada de audit_log, más reciente primero.
  - Filtros: actor, action, target_kind, rango de fecha.
  - Cada fila expandible muestra el payload jsonb formateado.
  - Botón "Exportar" CSV de la consulta filtrada.

Read-only (RLS: solo SELECT para admin).
```

### Hecho cuando

- [x] Bandeja unificada muestra todo lo abierto con filtros y SLA. ManagerInboxScreen con handlers reales en `d09706a` (F16-004).
- [~] Cada tipo se puede gestionar desde su detalle. Incidents/feedback: approve/reject/resolve inline. Suggestions: solo vista (M4 pendiente).
- [ ] Aprobar una solicitud de oficial promueve la ruta correctamente.
- [ ] Aplicar feedback corrige datos en producción.
- [ ] Métricas con gráficos funcionando.
- [ ] Acciones en lote y exportación operativas.
- [ ] Audit log visible para admin.

---

# BLOQUE VII — Pulido visual y accesibilidad

## FASE 17 — Apariencia personalizable

**Objetivo:** Sistema de temas con paletas prefab, fondos prefab (incluido el shader `smoke.frag` ya existente), opción de desactivar fondo, paletas custom, fontScale, todo persistido por usuario.

**Dependencias:** F4 (auth) y F3 (UserPreferencesRepository).

### Prompt 17.1 — Modelo de paletas y fondos

```
Lee docs/ARCHITECTURE.md sección 6.1 (tokens existentes en
core/theme/).

Crea lib/core/theme/palettes/ con:

  app_palette.dart:
    class AppPalette {
      final String id;
      final String name;
      final bool isDark;
      final TransitColorScheme scheme; // reutiliza el existente
    }

  prefab_palettes.dart con 6 paletas que usen TransitColorScheme:
    1. Default (la actual, dark/light dual).
    2. Sunrise (warm, naranjas y rosas).
    3. Forest (verdes profundos, marrones).
    4. Midnight (negros y violetas, dark only).
    5. Ocean (azules, cian).
    6. Mono (escala de grises + un acento).

  Cada paleta debe pasar AA en sus pares principales (ver F18).

Crea lib/core/theme/backgrounds/ con:

  app_background.dart:
    sealed class AppBackground {
      final String id;
      final String name;
    }
    final class NoneBackground extends AppBackground;
    final class ImageBackground extends AppBackground {
      final String assetPath;
    }
    final class ShaderBackground extends AppBackground {
      final String shaderPath;
    }
    final class GradientBackground extends AppBackground {
      final List<Color> colors;
      final AlignmentGeometry begin, end;
    }

  prefab_backgrounds.dart con:
    1. None (sólido).
    2. Smoke (el shader ya existente shaders/smoke.frag).
    3. Aurora (gradient animado).
    4. Soft Grid (imagen sutil).
    5. Topo Lines (imagen).

ThemeNotifier nuevo en lib/shared/providers/theme_notifier.dart que
combina:
  - paletteId
  - brightness (system/light/dark)
  - backgroundId
  - backgroundEnabled
  - backgroundOpacity
  - fontScale
  - colorBlindMode
  - dyslexiaFontEnabled
  - reduceMotion

Y emite:
  - ThemeData light/dark según paleta.
  - Background widget para inyectar.
  - MediaQuery.textScaleFactor override.

Persistencia: UserPreferencesRepository (de F3) lee/escribe.
Mientras no haya sesión, persistencia en Hive caja
'guest_theme_prefs'.
```

### Prompt 17.2 — Pantalla de Apariencia

```
Crea lib/features/appearance/appearance_screen.dart accesible desde
profile_screen → "Preferencias" → "Apariencia":

Secciones:

1. PALETA
   - Grid 2 columnas con cada paleta como card preview (mini mockup
     de UI con sus colores).
   - Tap = aplicar al instante.
   - Preview live: la propia pantalla cambia de paleta inmediato.

2. BRILLO
   - Segmented: System / Claro / Oscuro.

3. FONDO
   - Switch maestro "Mostrar fondo decorativo".
   - Si activo:
     - Lista horizontal con preview de cada fondo prefab.
     - Slider de opacidad (0-100%).
   - Si inactivo: solid bgRoot del scheme.

4. TEXTO
   - Slider fontScale 0.85x - 1.4x con preview de un párrafo.
   - Switch "Tipografía para dislexia" (OpenDyslexic, F18).

5. ACCESIBILIDAD VISUAL
   - Dropdown colorBlindMode: ninguno, protanopia, deuteranopia,
     tritanopia.
   - Switch "Reducir animaciones" (override del SO).

6. RESETEAR
   - Botón "Restaurar valores por defecto".

Aplicación en vivo: usar ref.read(themeNotifierProvider.notifier) y
re-renderizar sin reiniciar app.
```

### Prompt 17.3 — Paleta personalizada

```
Sub-pantalla custom_palette_screen.dart accesible desde el grid de
paletas con un botón "+ Nueva paleta":

1. Color picker (paquete `flex_color_picker`) para:
   - primary
   - secondary
   - bgRoot
   - bgSurface
   - textHi
2. Otros colores (textMid, textLo, border, states, gradients) se
   derivan automáticamente con fórmulas (mezclas, tinte/sombra).
3. Validación de contraste WCAG AA: muestra una etiqueta en cada par
   relevante (textHi vs bgSurface, primary vs bgSurface, etc.) con
   ratio. Si < 4.5, badge rojo "AA fail" + sugerencia automática.
4. Guardar como custom_palette_<n> en
   user_preferences.custom_colors.
5. Permite tener varias paletas custom; aparecen al final del grid
   junto con un botón "Editar/Borrar" en long-press.
```

### Prompt 17.4 — Aplicación del shader y fondos

```
1. Crea un widget BackgroundWrapper que:
   - Lee themeNotifier.background.
   - Si NoneBackground: container con bgRoot.
   - Si ImageBackground: Image.asset con BlendMode.dstATop.
   - Si ShaderBackground: ShaderBuilder con FragmentShader (carga
     desde flutter shaders) — reutiliza la lógica existente del
     SmokeBackground.
   - Si GradientBackground: AnimatedContainer con gradient.
   - Aplica opacity y respeta reduceMotion (pausa shaders animados
     si está activo).

2. Envuelve el contenido en app.dart:
   MaterialApp.router(
     builder: (context, child) => BackgroundWrapper(child: child),
     ...
   )

3. Optimización:
   - Si fondo es shader y reduceMotion=true → fallback a gradient
     estático del mismo set de colores.
   - Si es shader y la paleta cambia, regenera uniforms del shader
     con los nuevos colores.
```

### Hecho cuando

- [ ] 6 paletas + 5 fondos prefab con preview.
- [ ] Paleta custom con validación de contraste.
- [ ] El shader `smoke.frag` se aplica con opacidad regulable.
- [ ] Cambios persisten por usuario (Supabase) y por dispositivo
      cuando es invitado (Hive).
- [ ] Modo color-blind aplica matriz a toda la app.

---

## FASE 18 — Accesibilidad (WCAG AA)

**Objetivo:** Hacer la app realmente usable para personas con discapacidad visual, motora o cognitiva. Cumplir WCAG 2.1 AA en lo razonable. Esto importa especialmente porque transporte público es un servicio esencial.

**Dependencias:** F17 (parte ya en colorBlindMode, fontScale, reduceMotion).

### Prompt 18.1 — Auditoría a11y

```
Audita TODA la app y genera docs/A11Y_AUDIT.md con esta plantilla
por pantalla:

## <Screen>

### Semántica
- IconButtons sin tooltip ni semantic label: file:line × N
- Imágenes sin alt: file:line × N
- Touch targets <48dp: file:line × N
- Orden de focus problemático (descripción)

### Contraste
- Pares fallidos AA (texto vs fondo): ratio actual

### Texto
- Tamaños hardcoded (no respetan fontScale)
- Truncamientos sin tooltip

### Animación
- Animaciones que no respetan MediaQuery.disableAnimations
- Animaciones que no respetan reduceMotion (theme)

### Otras
- Formularios sin labels explícitos
- Mensajes de error solo por color
- Estado solo señalado por color (no por texto/forma/icono)

### Tareas con TalkBack/VoiceOver
- Pasos para leer la pantalla y obstáculos encontrados.

NO arregles nada todavía. Solo el informe.
```

### Prompt 18.2 — Arreglos por severidad

```
Lee docs/A11Y_AUDIT.md y arregla por severidad:

CRÍTICOS (bloquean uso):
  - Touch targets <48dp en flujos críticos.
  - Acciones primarias sin label semántico.
  - Estados solo por color (errores, busy).

ALTOS:
  - Contraste fail AA en bloques principales.
  - Iconos sin tooltip en AppBar.
  - Formularios sin labels.

MEDIOS:
  - Tamaños de texto hardcoded.
  - Imágenes decorativas sin Semantics(excludeSemantics).
  - Listas sin SliverSemantics o equivalent.

Por cada arreglo:
  - commit independiente.
  - test de widget con find.bySemanticsLabel cuando aplique.

Especiales para Transitly:
  - Buses estimados (F13) deben distinguirse por forma + color
    + patrón de borde, no solo color.
  - Etiquetas de origen (officialLive, etc.) deben tener
    Semantics(label: 'Bus oficial en directo', ...) explícito.
  - Marcadores de mapa no son nativamente accesibles en
    flutter_map; implementa una lista alternativa lineal accesible
    "Buses cerca de ti" como fallback para lectores.
```

### Prompt 18.3 — Tipografía OpenDyslexic

```
1. Descarga OpenDyslexic (open source, OFL) y añade los .ttf a
   fonts/opendyslexic/.

2. Declara la familia en pubspec.yaml.

3. En theme builder de TransitTypography, si
   themeNotifier.dyslexiaFontEnabled=true, usa OpenDyslexic como
   fontFamily base. Mantén tamaños y pesos.

4. UI: el toggle ya existe en F17.2. Asegúrate de que la fuente se
   aplica a TODA la app, incluido AppBar y diálogos.

5. Golden tests: snapshots de pantallas críticas (Map, RouteDetail,
   Editor) con fontScale 0.85, 1.0, 1.4 × dyslexia on/off ×
   light/dark = 12 goldens por pantalla. Almacénalos en
   test/goldens/a11y/.
```

### Prompt 18.4 — Lectores de pantalla y semánticas

```
1. Recorre y añade Semantics donde falte:
   - Botones y links: label corto + hint.
   - Inputs: label, hint, errorText vinculados.
   - Listas de buses: cada marker con label "Línea L1, próxima
     parada Plaza del Caballo, en 3 minutos".
   - Estados: "Cargando", "Sin conexión", "Sin resultados".

2. Live regions:
   - Banner de offline → Semantics(liveRegion: true).
   - Snackbars de éxito/error → liveRegion.

3. Para flutter_map, dado que el canvas no es accesible:
   - Botón flotante "Ver lista" en MapTab que abre un
     `accessible_buses_screen.dart` con lista lineal de buses,
     paradas y rutas visibles ahora, totalmente accesible con
     TalkBack/VoiceOver.

4. Verifica con TalkBack y VoiceOver manualmente. Graba un screencast
   de 60s navegando flujos clave; adjúntalo en docs/A11Y_VIDEOS/.
```

### Hecho cuando

- [ ] `flutter analyze` con `accessibility_lint` (paquete) sin warnings críticos.
- [ ] Audit pasa en pantallas principales con TalkBack/VoiceOver.
- [ ] Modo color-blind, alto contraste, OpenDyslexic activos y
      aplicados de forma correcta.
- [ ] Goldens de a11y en CI.
- [ ] Lista accesible alternativa para mapa.

---

## FASE 19 — Reputación y rangos visibles

**Objetivo:** Aprovechar `reputationScore` y `reputationLevel` (ya existen) para mostrar progresión, rangos y logros. Decorativo por ahora; sin desbloqueos funcionales.

**Dependencias:** F4 (auth), F15 (las acciones que dan reputación).

### Prompt 19.1 — Sistema de rangos

```
Crea lib/shared/models/reputation.dart:

  enum ReputationRank {
    none,         // 0
    novice,       // 10
    contributor,  // 50
    advocate,     // 200
    cartographer, // 500
    guardian,     // 1500
    legend,       // 5000
  }

  extension on ReputationRank {
    int get minScore;
    String get nameKey;       // l10n
    String get iconAsset;     // assets/branding/ranks/<x>.svg
    Color get color;
  }

  ReputationRank rankFor(int score);
  int scoreToNext(int score);

Eventos que dan reputación (centralizado en
lib/shared/providers/reputation_events.dart):

  +5  incident creado y aceptado
  -10 incident rechazado por spam
  +3  feedback creado
  +10 feedback aceptado y aplicado
  +5  sugerencia de ruta creada
  +2  voto recibido en sugerencia/feature_request
  +20 ruta comunitaria pasa a verified
  +50 ruta comunitaria pasa a oficial
  +1  reportar duplicado correctamente

Implementación:
  - Trigger SQL en migración 012_reputation.sql:
    AFTER INSERT/UPDATE en incidents, route_feedback,
    route_suggestions, feature_requests, routes →
    actualiza profiles.reputation_score y reputation_level.
  - Función SQL recompute_reputation(profile_id) para corregir
    drift; reuse desde panel admin.
```

### Prompt 19.2 — UI de progresión

```
Pantalla lib/features/profile/reputation_screen.dart accesible desde
profile_screen → tap en ReputationBadge:

1. Header: avatar + rango actual con icono + score + barra de progreso
   al siguiente rango.
2. Sección "Cómo subir":
   - Lista de eventos con su +reputación.
3. Sección "Rangos":
   - Lista de los 7 rangos con icono, nombre y minScore.
   - El rango actual destacado.
4. Sección "Mis hitos":
   - Tabla con fechas: cuándo alcanzaste cada rango.
5. Tooltip claro: "La reputación es decorativa por ahora. Más
   adelante desbloqueará privilegios."

ReputationBadge (widget existente) se actualiza para mostrar el icono
del rango además del nivel numérico.
```

### Prompt 19.3 — Logros

```
Reusa AchievementModel y UserAchievementModel (ya existen).

Define un catálogo en assets/achievements.json (cargado al arranque):
  - first_report
  - first_route_created
  - first_route_verified
  - first_route_official
  - 100_votes_cast
  - 10_corrections_applied
  - cartographer_of_<city>  (10 rutas comunitarias en una ciudad)
  - bus_finder              (50 incidents creados)
  - early_adopter           (cuenta antes de cierta fecha)

Trigger SQL evalúa al insertar en las tablas relevantes y crea
user_achievements.

UI: pantalla profile_screen → "Logros" → grid de cards (desbloqueado
en color, bloqueado en gris) con descripción y fecha.

Notificación al desbloquear (F12.3 + F21).
```

### Hecho cuando

- [ ] Triggers de reputación operativos.
- [ ] Pantalla de progresión visible y entendible.
- [ ] 9 logros base con sus condiciones.
- [ ] El badge se actualiza al ganar reputación en tiempo real.

---

# BLOQUE VIII — Infraestructura de producto

## FASE 20 — Tiles MapTiler y caché offline

**Objetivo:** Migrar de OSM público a MapTiler (apto para producción) y permitir descargar zonas para uso sin internet.

**Dependencias:** F8 (location).

### Prompt 20.1 — MapTiler como tile provider

```
Lee docs/ARCHITECTURE.md.

1. Registro y obtención de API key en MapTiler Cloud.
   Documenta en docs/MAPTILER_SETUP.md cómo dar de alta una cuenta
   y dónde guardar la key (env: MAPTILER_API_KEY).

2. En el TileLayer existente (lib/features/map/...), reemplaza
   tile.openstreetmap.org por:
     'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key={apiKey}'

   Estilos que recomiendo probar:
     - streets-v2 (general).
     - basic-v2 (limpio, ideal para movilidad).
     - bright-v2 (high contrast).
   Hazlos seleccionables desde Apariencia → "Estilo de mapa".

3. Headers estándar:
     'User-Agent': 'Transitly/<version>'

4. Atribución de OpenStreetMap + MapTiler en una esquina del mapa
   (es obligatorio).

5. Plan free de MapTiler: 100k requests/mes. Documenta cómo
   monitorear el uso desde su dashboard.

Failover: si MapTiler responde 5xx repetido, fallback temporal a OSM
público con un banner "Servicio degradado". Esto se loggea con
[Map] tag.
```

### Prompt 20.2 — Caché de tiles offline

```
1. Añade `flutter_map_tile_caching` (FMTC) al pubspec.yaml.
   Verifica licencia (GPL v3 con excepción comercial — si no encaja
   con tu plan futuro de comercializar, alternativa: implementar
   cache propia con path_provider + sqlite).

2. Inicializa FMTC en main.dart con un store por defecto
   'transitly-default' y establece límites:
   - Max disk: 500 MB.
   - Política: LRU por última consulta.

3. Activa caché transparente: cualquier tile descargado se persiste.

4. Crea lib/features/offline/offline_regions_screen.dart:
   - Lista de regiones descargadas con preview, tamaño, fecha,
     cantidad de tiles.
   - FAB "Añadir nueva zona".

5. flow "Añadir nueva zona":
   - Mapa fullscreen con un rectángulo arrastrable.
   - Selector zoom mín (default 12) y zoom máx (default 16).
   - Nombre de la zona.
   - Estimación de tamaño previa: tiles_count = sum(2^z * 2^z) para
     zooms en rango × bbox proportion. MB ≈ tiles × 30KB.
   - Confirmación.
   - Descarga con barra de progreso, cancelable.
   - Inserta en offline_regions de Supabase (para sync entre
     dispositivos).
```

### Prompt 20.3 — Datos offline

```
Para cada offline_region descargada:

1. Al confirmar la descarga:
   - Descarga tiles (FMTC).
   - Descarga vía RPC export_region_data(bounds) los datos
     necesarios:
     stops, routes (con geom intersect bounds), schedules,
     operators relevantes.
   - Almacena en Hive con etiqueta region_id.

2. Cuando offline + dentro de una región descargada:
   - El mapa se ve normal (tiles desde FMTC).
   - Búsqueda y consultas van a Hive con region_id.
   - Banner discreto "Modo offline".

3. Cuando offline + fuera de regiones descargadas:
   - Banner amarillo "Sin datos offline para esta zona".
   - Mapa con tiles cacheados si los hay (lookups previos),
     placeholder gris si no.

4. Crea RPC export_region_data en migración
   013_offline_export.sql:
     RETURNS JSON con
     {operators:[], stops:[], routes:[], schedules:[]}
     filtrado por bounds.
```

### Prompt 20.4 — Política de almacenamiento

```
1. Configuración en Apariencia → "Almacenamiento":
   - Espacio total usado por Transitly.
   - Desglose: tiles (FMTC), datos (Hive), adjuntos pendientes.
   - Botón "Borrar caché de mapa" → elimina todos los stores FMTC
     excepto los pinned a una offline_region.
   - Botón "Borrar todo" → factory reset (con confirmación).

2. Aviso si supera 500 MB: "Estás cerca del límite. ¿Quieres borrar
   las regiones que no usas?".

3. Política LRU: stores no pinned se eliminan automáticamente cuando
   se supera el límite.
```

### Hecho cuando

- [ ] MapTiler activo con su API key, atribución visible.
- [ ] Selector de estilo de mapa en Apariencia.
- [ ] FMTC instalado y caché transparente activa.
- [ ] Descarga de zonas con barra de progreso, cancelable.
- [ ] Datos por región sincronizados a Hive.
- [ ] Modo offline funciona en avión completo en una región
      previamente descargada.

---

## FASE 21 — Notificaciones push (FCM) e in-app

**Objetivo:** Push reales con FCM (Android e iOS) más el sistema in-app que ya está en F12.3. Notificaciones útiles, no spam.

**Dependencias:** F12.3.

### Prompt 21.1 — FCM setup

```
1. Añade firebase_core y firebase_messaging al pubspec.yaml.

2. Configura proyectos Firebase:
   - Android: google-services.json, dependencias en gradle.
   - iOS: GoogleService-Info.plist, capability Push Notifications,
     APNs key configurada.
   Documenta en docs/FCM_SETUP.md.

3. Crea lib/data/push/push_service.dart:
   class PushService {
     Future<void> requestPermission();
     Future<String?> getToken();
     Stream<RemoteMessage> get onMessage;
     Future<void> setupForegroundHandler();
     Future<void> setupBackgroundHandler();
   }

4. Al login:
   - Pide permiso (con UX explicativa de por qué).
   - Obtén token.
   - INSERT en device_tokens (nueva tabla en migración
     014_push_tokens.sql con columns:
     user_id, token, platform, app_version, last_seen,
     PRIMARY KEY (user_id, token)).
   - UPSERT periódico (cada lanzamiento).

5. Al logout: DELETE del token.

6. Edge Function send_notification:
   - Recibe { user_id, title, body, deeplink, data }.
   - Lee tokens del user.
   - Envía vía FCM Admin SDK.
   - Inserta también en notifications (in-app) para que se vea
     incluso si el push falla.
```

### Prompt 21.2 — Tipos de push y triggers

```
Tipos de notificación implementados (mapping notification_type →
push):

incident_resolved
  → "Tu reporte fue resuelto"
  body: admin_notes
  deeplink: /contributions/incident/<id>

route_promoted
  → "Tu ruta es ahora oficial 🎉"
  body: "<route name> ahora está disponible para todos."
  deeplink: /route/<id>

share_received
  → "<sharer name> te ha compartido una ruta"
  body: route name
  deeplink: /my-routes/shared

feature_request_replied
  → "Respuesta a tu sugerencia"
  body: admin_notes preview
  deeplink: /contributions/request/<id>

bus_approaching_favorite (F24)
  → "🚌 Línea L1 a 3 min de Plaza del Caballo"
  high priority
  deeplink: /stop/<id>

custom (admin → user)
  → título y body desde panel admin
  deeplink configurable

Triggers SQL en migración 015_push_triggers.sql:
  - AFTER UPDATE en incidents → si status cambia a resolved/rejected,
    invoca Edge Function via pg_net.
  - AFTER INSERT en route_shares → idem.
  - AFTER UPDATE en routes → si source pasa a official, idem.

Anti-spam:
  - Quiet hours por usuario: user_preferences.quiet_hours_start/end
    (TIME). Si llega notificación en quiet hours, retrasa hasta el
    final.
  - Toggle por categoría en perfil: switches "Reportes resueltos",
    "Mis rutas", "Buses cerca", "Otros".
```

### Prompt 21.3 — Wearables nivel 0

```
Verifica que las notificaciones FCM se muestran correctamente en
wearable conectado:

1. Para Wear OS: Android renderiza automáticamente la notificación
   en el reloj. Asegúrate de que:
   - Iconos pequeños (24dp) están definidos.
   - El channelId tiene importance=HIGH para que vibre en muñeca.
   - Acciones de la notificación (botones) son razonables en pantalla
     pequeña.

2. Para watchOS: iOS lo hace solo si la app del iPhone tiene push
   habilitado. Pruebas reales en dispositivo.

3. Documenta en docs/WEARABLE_NIVEL_0.md cómo se ven las
   notificaciones en cada plataforma. Captura screenshots.

4. Nivel 1 (complications/tiles) queda como F27 opcional.
```

### Hecho cuando

- [ ] Push reales llegan a Android y iOS.
- [ ] Cada tipo de notificación tiene su trigger.
- [ ] Quiet hours respetadas.
- [ ] Toggles por categoría funcionando.
- [ ] Pruebas con wearable conectado: la notificación llega bien
      al reloj.

---

## FASE 22 — Sentry y PostHog

**Objetivo:** Saber qué falla y qué se usa, sin invadir privacidad.

**Dependencias:** F4 (consent puede ir antes que F25 pero la pantalla pulida está allí).

### Prompt 22.1 — Sentry

```
1. Añade sentry_flutter al pubspec.yaml.

2. Inicializa en main.dart antes de runApp:
   await SentryFlutter.init((options) {
     options.dsn = Env.sentryDsn;
     options.tracesSampleRate = 0.2;
     options.environment = kReleaseMode ? 'prod' : 'dev';
     options.beforeSend = (event, hint) {
       // Strip PII conforme docs/ARCHITECTURE.md sección 5.3.
       return _scrubPII(event);
     };
   }, appRunner: () => runApp(...));

3. Integración con AppLogger:
   - AppLogger.error → SentryFlutter.captureException (si consent).
   - AppLogger.warn con flag isExceptional → breadcrumb.
   - Log normal → breadcrumb (no se envía solo, se adjunta a errores).

4. Tagged context:
   - userId (solo si consent analytics activo).
   - role.
   - operatorActiveId.
   - app version.

5. Consent gating: si privacy_consents.crash_reporting=false, NO
   inicializar Sentry (o al menos no enviar eventos). Default OFF
   hasta que el usuario lo active explícitamente en F25.
```

### Prompt 22.2 — PostHog

```
1. Añade posthog_flutter al pubspec.yaml.

2. Inicializa con consent gate (privacy_consents.analytics=true).
   Default OFF hasta consent.

3. Eventos clave a trackear:
   - app_open
   - sign_in_success / sign_in_failure
   - sign_up_success
   - search_performed (query length only, NO content)
   - route_viewed (route_id sí, no PII)
   - incident_created (kind, route_id si aplica)
   - feedback_created (kind)
   - share_route (channel: user/link)
   - official_request_submitted
   - palette_changed (palette_id)
   - background_toggled
   - colorblind_mode_changed
   - offline_region_downloaded (size_bucket)
   - driver_trip_started / ended
   - admin_action_taken (kind)

4. Crea lib/data/analytics/analytics_service.dart con la abstracción:
   class AnalyticsService {
     void track(AnalyticsEvent event);
     void identify(String userId, {Map<String, dynamic>? props});
     void reset();
   }
   Implementación: PostHogAnalyticsService + NoopAnalyticsService.
   Provider que escoge según consent.

5. Funnels útiles a definir en PostHog:
   - Onboarding: app_open → location_permission_granted →
     operator_loaded.
   - Reporte: report_button_clicked → report_screen_opened →
     incident_created → admin_resolved.
   - Compartir: route_viewed → share_modal_opened → share_completed.

6. NUNCA loguear: email, número de tarjeta NFC, lat/lng exacta del
   usuario, contenido de descripciones libres.
```

### Hecho cuando

- [ ] Sentry captura crashes en dev y prod (con consent).
- [ ] PostHog tracea eventos clave (con consent).
- [ ] Toda telemetría está OFF por defecto hasta consent.
- [ ] No hay PII en eventos.
- [ ] Funnels definidos.

---

# BLOQUE IX — Plataformas extra

## FASE 23 — Web híbrida (Astro + Flutter Web islands)

**Objetivo:** Sitio web rápido y SEO-friendly que sirve landings, descubrimiento de operadores/rutas/paradas, y carga la build de Flutter Web solo en las URLs funcionales (`/app/*`).

**Dependencias:** mucho del backend; conviene hacerlo cuando F1-F16 están sólidas.

### Prompt 23.1 — Setup del monorepo Astro

```
Decisión de estructura: mantener todo en el repo Transitly con dos
carpetas top-level:

  /                  ← Flutter (raíz como hasta ahora)
  /web/              ← AHORA es la build de Flutter Web. La movemos
                      a /flutter-web-build/ y el `flutter build web`
                      apuntará allí.
  /astro/            ← NUEVA: proyecto Astro.

1. En la raíz del repo, crea /astro/ con:
   npm create astro@latest astro -- --template minimal --typescript
   Selecciona 'strict' TypeScript.

2. Añade integraciones:
   astro add tailwind
   astro add sitemap
   astro add @astrojs/node      # SSR para deploy

3. Estructura inicial de /astro/src/:
     pages/
       index.astro                 # landing
       sobre.astro                 # acerca de
       privacidad.astro
       terminos.astro
       ciudades/
         index.astro               # lista operadores
         [slug].astro              # /ciudades/jerez
       rutas/
         [slug].astro              # /rutas/<slug-publico>  (route_public_links)
       app/
         editor/
           index.astro             # carga Flutter Web island
         admin/
           index.astro             # carga Flutter Web island
         map/
           index.astro             # carga Flutter Web island

4. Layout global con header (logo, búsqueda global, idioma) y
   footer.

5. Variables de entorno: PUBLIC_SUPABASE_URL,
   PUBLIC_SUPABASE_ANON_KEY (mismas que la app móvil).

6. Tailwind config con tokens equivalentes a TransitColorScheme y
   TransitTypography para consistencia visual.
```

### Prompt 23.2 — Páginas públicas con SSR

```
1. /astro/src/pages/index.astro:
   - Hero "Tu transporte público, simple."
   - 3 features.
   - CTA "Descargar app" + "Ver en navegador".
   - Estadísticas live: nº de operadores, nº de rutas, nº de paradas
     (consulta Supabase en SSR con RLS pública).

2. /ciudades/index.astro:
   - SSR consulta `SELECT * FROM operators ORDER BY name`.
   - Cards con nombre, región, nº de rutas oficiales.
   - Link a /ciudades/<slug>.

3. /ciudades/[slug].astro:
   - SSR fetch operator + rutas + paradas count + bbox.
   - Mapa estático generado server-side (image API de MapTiler:
     /maps/static/{lng},{lat},{zoom}/600x400.png) con la bbox.
   - Lista de rutas con su color y nombre.
   - SEO: meta tags description, og:image (mapa), schema.org
     BusOrCoachStation/PublicTransportRoute.

4. /rutas/[slug].astro:
   - Resuelve slug en route_public_links.
   - SSR fetch route + stops + schedules.
   - Mapa estático + lista de paradas + horarios del día.
   - SEO: title "Línea L1 — Plaza del Caballo a Estación · Transitly".
   - Schema.org BusTrip.

5. Cliente: pequeñas islas con Alpine.js o htmx para interactividad
   ligera (toggle horario semana/sábado, etc.). NO Flutter en estas
   páginas.

6. /privacidad.astro y /terminos.astro: contenido inicial generado
   en F25, en /astro/src/content/legal/.
```

### Prompt 23.3 — Flutter Web islands

```
1. Build script para Flutter Web:
   flutter build web --release \
     --base-href "/app/<feature>/" \
     --pwa-strategy none \
     --no-tree-shake-icons \
     --target lib/web_entry/<feature>_main.dart

2. Crea entry points por feature:
     lib/web_entry/editor_main.dart  → solo el RouteEditor
     lib/web_entry/admin_main.dart   → solo el panel admin
     lib/web_entry/map_main.dart     → solo el mapa interactivo grande

   Cada uno hace runApp con un go_router minimalista que solo
   contiene las rutas de esa feature.

3. /astro/src/pages/app/editor/index.astro:
   ---
   const flutterAssetPath = '/flutter-web-build/editor';
   ---
   <html><head>...</head>
   <body>
     <div id="flutter-editor"></div>
     <script src={`${flutterAssetPath}/flutter_bootstrap.js`}></script>
   </body></html>

4. Astro publica las builds de Flutter Web como assets estáticos:
   /astro/public/flutter-web-build/<feature>/
   Github Actions: en cada release, corre los builds de cada feature
   y los copia a /astro/public/flutter-web-build/.

5. Auth: cuando el usuario está logueado en Astro (cookie de Supabase),
   el Flutter Web island lee la sesión de localStorage de Supabase JS
   y la consume con supabase_flutter (compatible).

6. Performance:
   - Skeleton mientras carga el bundle Flutter (ahorra perceived
     latency).
   - lazy load: el script Flutter solo se carga al entrar a /app/*.
```

### Prompt 23.4 — Búsqueda global y descubrimiento

```
1. /astro/src/pages/buscar.astro:
   - Input grande con autocompletado server-side (API endpoint
     /api/search.json que llama a global_search RPC).
   - Resultados con tarjetas: paradas, rutas, ciudades.
   - Click en parada → /ciudades/<slug>#parada-<id> (con expansión
     en la página).
   - Click en ruta → /rutas/<slug>.

2. Sitemap con rutas estáticas + dinámicas (operators, routes con
   public_link).

3. Robots.txt permite indexación en producción, bloquea staging.

4. Open Graph y Twitter Cards correctas en cada tipo de página.
```

### Hecho cuando

- [ ] Astro buildea y deploya con SSR.
- [ ] Páginas públicas con SEO óptimo (Lighthouse SEO ≥95).
- [ ] Islands de Flutter Web cargan en /app/* con auth funcional.
- [ ] Sitemap, robots.txt, og:images correctos.

---

## FASE 24 — Widgets nativos del móvil

**Objetivo:** Widgets de pantalla de inicio Android e iOS con info en vivo de paradas favoritas. NO son Flutter; son código nativo que lee de un storage compartido.

**Dependencias:** F13 (ETAs) y F4 (favoritos guardados por usuario).

### Prompt 24.1 — Plumbing común

```
1. Añade home_widget al pubspec.yaml.

2. Crea lib/data/widgets_native/widget_data_writer.dart:

   class WidgetDataWriter {
     Future<void> writeNextBus({
       required String stopName,
       required String routeCode,
       required int minutesToArrival,
       required BusPositionSource source,
       required DateTime updatedAt,
     });
     Future<void> writeMyLineStatus({
       required String routeCode,
       required List<NextArrival> upcoming,
     });
   }

   Internamente usa HomeWidget.saveWidgetData<T>(...).

3. Job background con workmanager:
   - Cada 15 min:
     - Lee favoritos del usuario.
     - Calcula próximas llegadas (mezcla bus_positions reales y
       estimadas).
     - Llama writeNextBus / writeMyLineStatus.
     - Llama HomeWidget.updateWidget.

4. Documenta el contrato JSON de los datos compartidos en
   docs/HOME_WIDGETS.md. SharedPreferences key:
     'next_bus_<stopId>': {
       stopName, routeCode, etaMinutes, source, updatedAt
     }
     'line_status_<routeCode>': [
       {stopName, etaMinutes, source}, ...
     ]
```

### Prompt 24.2 — Widget Android (Kotlin)

```
1. Crea android/app/src/main/kotlin/com/transitly/widgets/
   NextBusWidgetProvider.kt:

   class NextBusWidgetProvider : HomeWidgetProvider() {
     override fun onUpdate(...) {
       val data = HomeWidgetPlugin.getData(context)
       val stopName = data.getString("next_bus_<stopId>:stopName", "...")
       val eta = data.getInt("next_bus_<stopId>:etaMinutes", -1)
       val source = data.getString("next_bus_<stopId>:source", "estimated")

       val views = RemoteViews(context.packageName, R.layout.next_bus)
       views.setTextViewText(R.id.stop_name, stopName)
       views.setTextViewText(R.id.route_code, ...)
       views.setTextViewText(R.id.eta, "${eta} min")

       // Indicador de fuente
       val dotColor = when(source) {
         "gtfs_realtime", "driver" -> Color.GREEN
         "estimated" -> Color.YELLOW
         else -> Color.GRAY
       }
       views.setInt(R.id.source_dot, "setColorFilter", dotColor)

       // Click → app
       val intent = HomeWidgetLaunchIntent.getActivity(...,
         Uri.parse("transitly://stop/<id>"))
       views.setOnClickPendingIntent(R.id.root, intent)

       appWidgetManager.updateAppWidget(appWidgetId, views)
     }
   }

2. Layouts:
   res/layout/next_bus.xml (2x1)
   res/layout/next_bus_large.xml (4x1)
   res/layout/line_status.xml (4x2)

3. AppWidgetProviderInfo en res/xml/:
   minWidth/minHeight, resizeMode horizontal/vertical, updatePeriodMillis
   (mínimo 30min, real refresh viene de workmanager).

4. AndroidManifest.xml: declarar receivers.
```

### Prompt 24.3 — Widget iOS (SwiftUI/WidgetKit)

```
1. En ios/, crea un Widget Extension (Xcode):
   Target: TransitlyWidgets
   Bundle ID: <main>.widgets

2. Configura App Group compartido entre app principal y widget:
   group.com.transitly.shared

3. SwiftUI Views:

   struct NextBusEntry: TimelineEntry {
     let date: Date
     let stopName: String
     let routeCode: String
     let etaMinutes: Int
     let source: BusSource
   }

   struct NextBusProvider: TimelineProvider {
     func getSnapshot(...)
     func getTimeline(...) {
       // Lee de UserDefaults(suiteName: "group.com.transitly.shared")
       // Genera entries cada minuto durante 15 min, refresh policy
       // .after(15 min)
     }
   }

   struct NextBusWidgetView: View {
     let entry: NextBusEntry
     var body: some View {
       VStack {
         Text(entry.stopName).font(.caption)
         Text(entry.routeCode).font(.title)
         HStack {
           Circle().fill(entry.source.color).frame(width: 8, height: 8)
           Text("\(entry.etaMinutes) min")
         }
       }
       .widgetURL(URL(string: "transitly://stop/<id>"))
     }
   }

4. Soportar familias:
   .systemSmall, .systemMedium, .accessoryCircular,
   .accessoryRectangular (Lock Screen iOS 16+).

5. Configuration intent (ios 17+ widget configuration) para que el
   usuario elija parada favorita desde la pantalla de inicio sin
   abrir la app.
```

### Prompt 24.4 — Settings de widgets en la app

```
Pantalla lib/features/widgets_native/widgets_settings_screen.dart
en Settings:

  - Lista de widgets disponibles con preview.
  - Cada widget configurable:
      - Parada favorita (StopPicker).
      - Línea favorita (RoutePicker).
      - Formato (minutos / hora exacta).
  - Botón "Añadir a la pantalla de inicio" con instrucciones por
    SO (texto + GIF cómo se hace).

Visible solo en Platform.isAndroid || Platform.isIOS.
```

### Hecho cuando

- [ ] Widget Android funcional, con dot de origen del dato.
- [ ] Widget iOS funcional + Lock Screen widgets.
- [ ] Configuración desde la app sincronizada a SharedPreferences/
      UserDefaults.
- [ ] Refresh cada 15 min en background.
- [ ] Tap en widget abre la app en la parada/línea correcta.

---

# BLOQUE X — Cierre

## FASE 25 — Privacidad, GDPR/LOPD y consentimientos

**Objetivo:** Cumplimiento legal mínimo para una app que va a producción en España: textos legales, gestión de consentimientos, exportación y borrado de datos del usuario.

**Dependencias:** F22 (analytics y crash con consent gate), F4.

### Prompt 25.1 — Pantalla de privacidad y consentimientos

```
Crea lib/features/privacy/privacy_screen.dart accesible desde
profile → "Privacidad":

Secciones:

1. CONSENTIMIENTOS
   - Switch "Análisis de uso (PostHog)" + descripción corta.
   - Switch "Reporte de errores (Sentry)" + descripción.
   - Switch "Notificaciones de marketing" (off por defecto, futuro).
   Cada cambio crea un registro en privacy_consents con
   policy_version (string del hash del documento legal vigente).

2. MIS DATOS
   - "Descargar mis datos" → encola data_exports, status=queued.
   - Edge Function process_data_export procesa: extrae todo lo
     relacionado al user_id, genera ZIP con jsons (profile,
     contributions, routes, preferences), sube a Storage bucket
     data-exports con expiración 7 días, envía notificación con link
     firmado.
   - "Eliminar mi cuenta" → modal con explicación:
     - Doble confirmación con captcha.
     - Crea data_deletion_requests con scheduled_at = NOW()+30 días.
     - 30 días en los que el usuario puede cancelar; tras eso, una
       Edge Function process_account_deletion borra:
       profile (anonimiza display_name → 'Usuario eliminado'), todas
       sus contribuciones (mantiene anonimizadas para integridad
       histórica de los datos), elimina avatar, prefs, sesiones.
       NO se borran las routes.source='community'.status='official'
       (han pasado a oficial, ya no le pertenecen).

3. POLÍTICAS
   - Link a "Política de privacidad" (asset markdown localizado).
   - Link a "Términos de uso".
   - Link a "Cookies/Telemetría".

Crea assets/legal/es/{privacidad,terminos,telemetria}.md y la
versión inglesa /en/.

Documenta en docs/PRIVACY_POLICY_VERSIONS.md cómo se versionan los
consentimientos: cada cambio mayor del texto legal incrementa el
hash; al detectarlo, la app pide re-consent con un modal modal
bloqueante en el siguiente arranque.
```

### Prompt 25.2 — Edge Functions de exportación y borrado

```
Crea supabase/functions/process_data_export/index.ts:

  - Recibe trigger desde data_exports INSERT.
  - Lee user_id.
  - Reúne todos los datos del usuario en JSONs separados:
      profile.json, preferences.json, incidents.json,
      route_feedback.json, route_suggestions.json,
      feature_requests.json, routes_owned.json,
      offline_regions.json, achievements.json,
      audit_log_self.json (acciones del propio usuario).
  - Empaqueta en ZIP.
  - Sube a storage bucket data-exports con path
    '<uid>/<timestamp>.zip'.
  - Genera signed URL (7 días).
  - INSERT en notifications con link.
  - UPDATE data_exports.status='completed', file_url.

Crea supabase/functions/process_account_deletion/index.ts:

  - Cron diario que selecciona data_deletion_requests con
    scheduled_at < NOW() y status='requested'.
  - Para cada uno:
    - Anonimiza profile (display_name='Usuario eliminado',
      avatar_url=NULL, email = (auth.users será borrado por la
      cascade)).
    - DELETE FROM auth.users WHERE id = ... (cascade hace el resto).
    - Las contribuciones quedan con author_id ya inválido pero la
      RLS las trata como huérfanas; en UI se muestra "Anónimo".
    - Marca status='completed', completed_at=NOW().
```

### Prompt 25.3 — Onboarding con consent inicial

```
1. En el primer arranque (sin sesión), tras la pantalla de bienvenida:
   - Modal "Antes de empezar":
     - Bloque obligatorio: aceptar términos y privacidad
       (con scroll y acuse de lectura).
     - Bloques opcionales:
       - Permitir análisis de uso anónimo.
       - Permitir reporte de errores.
   - Hasta que se acepten los obligatorios, no se puede usar la app.

2. Si el documento legal cambia (hash distinto a
   policy_version_aceptada), modal de re-consent al siguiente arranque.

3. Si el usuario es menor (autodeclarado < 16 años en sign up),
   oculta opciones de share_route, comments, mensajes
   admin→user. Documenta esta limitación en
   docs/MINORS_POLICY.md.
```

### Hecho cuando

- [ ] Modal de consent inicial bloquea hasta aceptar.
- [ ] Pantalla de privacidad operativa: switches, exportar, borrar.
- [ ] Exportación produce ZIP descargable.
- [ ] Borrado programado a 30 días, cancelable.
- [ ] Versión legal en assets, hasheada y referenciada en consents.

---

## FASE 26 — QA, performance, TFG y release

**Objetivo:** Dejar la app pulida para presentación de TFG y, después, beta cerrada en Play Store.

**Dependencias:** todo lo anterior.

### Prompt 26.1 — Tests E2E

```
Lee docs/ARCHITECTURE.md y los tests existentes.

Crea integration_test/ con escenarios happy path:

  e2e_passenger_flow_test.dart:
    sign in → buscar parada → ver llegadas → marcar favorita →
    reportar incidencia → ver mi reporte en perfil.

  e2e_create_route_test.dart:
    sign in → crear ruta manual → publicarla → compartirla con otro
    usuario → ese usuario la ve en "compartidas conmigo".

  e2e_official_promotion_test.dart:
    user A crea ruta comunitaria → solicita oficial →
    user B (admin) revisa en panel → aprueba → ruta pasa a official
    → user A recibe notificación.

  e2e_driver_flow_test.dart:
    operator_admin genera código → driver lo canjea → driver inicia
    viaje → posición aparece en mapa de otro user → driver finaliza →
    posición desaparece.

  e2e_offline_test.dart:
    descargar zona Jerez → modo avión → buscar parada en Jerez →
    funciona → reportar incidencia → entra en cola → activar red →
    se sincroniza.

  e2e_admin_flow_test.dart:
    admin abre panel → resuelve incidencia → autor recibe
    notificación → reputación incrementa → badge cambia.

Configura GitHub Actions:
  - On push: flutter analyze + flutter test.
  - On PR a master: lo anterior + integration tests en emulador.
  - On tag v*: build apk/aab + ipa + sube a Firebase App
    Distribution para beta interna.
```

### Prompt 26.2 — Performance y tamaño

```
1. Targets:
   - Cold start <2.5s en Pixel 5 / iPhone 12.
   - Frame budget 60fps en Map con 100+ markers visibles.
   - APK release < 25MB (sin assets de mapa).
   - IPA release < 50MB.

2. Análisis:
   - flutter run --profile + DevTools.
   - Mide y documenta en docs/PERFORMANCE_BASELINE.md.

3. Ajustes esperables:
   - --tree-shake-icons activado.
   - --split-per-abi en Android.
   - assets pesados (smoke shader, branding) auditados.
   - Lazy loading de pantallas no críticas con go_router.

4. Map performance:
   - Si hay >300 markers visibles, agrupar con
     flutter_map_marker_cluster.
   - Para polilíneas de rutas, usar `Polyline.simplified` con
     Douglas-Peucker.
   - Provider mapDataCacheProvider memoiza estructuras (ya existe
     según ARCHITECTURE.md sección 6.3).

5. Memoria:
   - Sesiones largas (60min de driver tracking activo).
   - Scroll infinito en bandeja admin.
   - Mide leaks con DevTools y arregla.
```

### Prompt 26.3 — Materiales TFG

```
Crea /docs/tfg/ con plantillas para:

1. memoria.md:
   - Resumen, abstract.
   - Objetivos.
   - Estado del arte (apps similares: EMT Madrid, Moovit, Citymapper).
   - Análisis de requisitos (funcionales, no funcionales).
   - Diseño (arquitectura — usa diagramas de docs/ARCHITECTURE.md).
   - Implementación (esto se rellena con cada fase completada).
   - Pruebas y resultados.
   - Conclusiones y trabajo futuro.

2. screenshots/ (50+ capturas en alta resolución organizadas por
   pantalla y tema).

3. demo_script.md:
   - Guion de demo de 5-10 minutos:
     0. Inicio → splash, mapa con buses en vivo.
     1. Buscar parada → ver llegadas (oficial · vivo).
     2. Crear cuenta → activar conductor con código.
     3. Iniciar viaje como conductor → mostrar punto en otro
        dispositivo.
     4. Reportar incidencia desde otra cuenta.
     5. Aprobarla desde panel admin.
     6. Crear ruta comunitaria con LiveRecorder.
     7. Solicitar oficial.
     8. Aprobarla desde panel admin.
     9. Apariencia: cambiar paleta, color-blind, dyslexia.
     10. Offline: descargar zona, modo avión, demo de búsqueda.

4. video_demo/ (instrucciones de grabación con ffmpeg para hacer un
   vídeo de 5min con voz off).

5. póster.md (poster científico tamaño A1 con secciones estándar).

Para la defensa, plantilla de keynote/PowerPoint con paleta
Transitly.
```

### Prompt 26.4 — Pre-release a Play Store

```
1. Configura signing:
   - Genera keystore (NUNCA commitear).
   - Guarda contraseña en GitHub Secrets.
   - android/app/build.gradle: configura release signing.

2. Crea cuenta Google Play Console (cuota anual de 25$).

3. Configura ficha de la app:
   - Título: "Transitly · Transporte público España".
   - Descripción corta + larga (revisa palabras clave).
   - Screenshots por dispositivo (móvil, 7", 10").
   - Vídeo promocional (opcional).
   - Política de privacidad (URL pública).
   - Categoría: Mapas y navegación.
   - Edad: PEGI 3.

4. Internal testing track:
   - Sube primer AAB.
   - Lista de testers (tu cuenta personal y 2-3 invitados).
   - Verifica que la app instalada funciona end-to-end.

5. Posteriormente, closed beta (50-100 testers) y open beta (resto).

6. Deja preparado pero NO publiques en producción todavía. La
   producción solo cuando todo el roadmap esté cerrado y tengas
   feedback de beta.
```

### Prompt 26.5 — Documentación final

```
Asegúrate de que docs/ contiene tras esta fase:

  ARCHITECTURE.md (mantenido al día)
  AUDIT_2026_04.md (referencia histórica)
  DATA_INVENTORY.md
  PENDIENTES.md
  AUTH_SETUP.md
  DATA_SOURCES.md
  A11Y_AUDIT.md
  A11Y_VIDEOS/
  MAPTILER_SETUP.md
  FCM_SETUP.md
  SECURITY.md (matriz roles × permisos × RLS)
  PRIVACY_POLICY_VERSIONS.md
  MINORS_POLICY.md
  HOME_WIDGETS.md
  WEARABLE_NIVEL_0.md
  PERFORMANCE_BASELINE.md
  ESTIMATION_QUALITY.md (F13)
  TROUBLESHOOTING.md
  CHANGELOG.md

README.md actualizado:
  - Descripción.
  - Screenshots.
  - Stack.
  - Cómo arrancar (.env, flutter run, supabase db push, etc.).
  - Estructura del repo.
  - Contributing (sin contribuyentes externos por ahora, pero deja
    la guía).
  - Licencia (decidir: si es código de TFG, licencia de uso académico;
    si va a producto comercial, propietaria).

CHANGELOG.md con conventional commits → standard-version.
```

### Hecho cuando

- [ ] Suite e2e en CI verde.
- [ ] Performance dentro de targets.
- [ ] Materiales TFG completos.
- [ ] Build firmada subida a Internal Testing.
- [ ] Documentación al día.

---

## FASE 27 — Wearables nivel 1 (opcional)

**Objetivo:** Si tras F26 sobra tiempo, complications/tiles en Apple Watch y Wear OS.

**Dependencias:** F24, F26.

### Prompt 27.1 — watchOS Complications

```
1. Añade Watch App target en Xcode (si no existía).

2. SwiftUI Views compatibles con WidgetKit complications:
   - .accessoryCircular (esfera): "🚌 5'".
   - .accessoryRectangular: "L1 → P. del Caballo · 5 min".
   - .accessoryInline: "L1 5'".

3. TimelineProvider lee del App Group compartido (mismo de F24).

4. Refresh: WidgetKit decide; el Watch reduce frecuencia para
   batería.

5. Si el reloj tiene LTE: opcional fetch directo a Supabase con la
   sesión del usuario (con scope reducido).
```

### Prompt 27.2 — Wear OS Tiles

```
1. Añade módulo Wear (Compose for Wear OS) en android/.

2. Implementa Tile con TileService:
   - Layout horizontal: ícono bus + ruta + ETA.
   - Refresh cada 5min con WorkManager.
   - Lee del DataStore compartido con la app.

3. Activity para configuración: el usuario elige parada favorita
   con ScalingLazyColumn.

4. Notificaciones nativas Wear (ya cubiertas en F21.3).
```

### Prompt 27.3 — Tests y release

```
1. Pruebas en dispositivos reales (al menos 1 Apple Watch y 1 Wear
   OS).

2. Documenta en docs/WEARABLE_NIVEL_1.md.

3. Si va para Play/App Store, asegúrate del review extra que
   requieren las apps de wearable.
```

### Hecho cuando

- [ ] Apple Watch muestra próximo bus en complication.
- [ ] Wear OS muestra el tile.
- [ ] Configuración desde el wearable.

---

# Anexos

## Anexo A · Resumen de tablas Supabase

| Tabla | Filas esperadas | Crece con | Crítica para |
|---|---|---|---|
| `operators` | 50-100 | nuevos operadores | F2, F7, F8 |
| `profiles` | 1k-100k | usuarios | F2, F4, F5 |
| `driver_assignments` | 100-1000 | drivers nuevos | F6, F14 |
| `invitation_codes` | 100-5000 | uso operativo | F6 |
| `stops` | 50k-300k | importación GTFS | F7, F8, F13 |
| `routes` | 5k-30k | GTFS + comunidad | F7, F10, F13 |
| `route_stops` | 500k-2M | n×stops por route | F7, F13 |
| `schedules` | 1M-5M | trips × días | F7, F13 |
| `bus_positions` | hot, ~1M filas vivas | live + estimadas | F13, F14 (cleanup auto) |
| `incidents` | 1k-100k/año | comunidad | F15, F16 |
| `route_feedback` | 500-50k/año | comunidad | F15, F16 |
| `route_suggestions` | 100-10k/año | comunidad | F15, F16 |
| `feature_requests` | 100-10k/año | comunidad + admins | F12, F15, F16 |
| `feature_request_votes` | 1k-100k | uso | F15 |
| `route_suggestion_votes` | 1k-100k | uso | F15 |
| `route_shares` | 1k-100k | uso | F12 |
| `route_public_links` | 100-10k | uso | F12, F23 |
| `offline_regions` | 1k-50k | uso | F20 |
| `user_preferences` | = profiles | trigger | F17 |
| `notifications` | 10k-1M | actividad | F12, F21 |
| `audit_log` | 10k-10M | acciones moderación | F5, F6, F16 |
| `gtfs_imports` | 10-1000 | imports manuales | F7 |
| `privacy_consents` | 5×profiles | consents | F25 |
| `data_exports`, `data_deletion_requests` | bajos | uso | F25 |
| `device_tokens` | ~profiles×2 | dispositivos | F21 |
| `driver_trips` | 10k-1M/año | viajes | F14 |
| `admin_message_templates` | 10-100 | uso admin | F16 |

## Anexo B · Mapeo modelos actuales → tablas

| Modelo Dart | Tabla SQL | Notas de migración |
|---|---|---|
| `UserModel` | `profiles` | `roles: List<String>` deprecado, `role: UserRole` nuevo |
| `OperatorModel` | `operators` | nuevo: `bbox`, `gtfs_url`, `gtfs_realtime_url` |
| `RouteModel` | `routes` | nuevo: `source` enum (resuelve "dual marker" de doc §3) |
| `StopModel` | `stops` | nuevo: `geom` (PostGIS) en lugar de lat/lng escalares |
| `ScheduleModel` | `schedules` | day_type ya existe en el modelo |
| `IncidentModel` | `incidents` | mismo schema, kind enum aterriza igual |
| `RouteFeedbackModel` | `route_feedback` | mismo schema |
| `RouteSuggestionModel` | `route_suggestions` | nuevo: tabla `route_suggestion_votes` para no contar dos veces |
| `ActiveTripModel` | `bus_positions` (parcial) + `driver_trips` | currentLat/lng/bearing → bus_positions; metadata del viaje → driver_trips |
| `RouteStopModel` | `route_stops` | direction añadido |
| `AlertModel` | `notifications` con type='custom' o tabla nueva `alerts` si es operativa | decisión en F21 |
| `RouteChangelogModel` | `audit_log` con target_kind='route' | reuse |
| `ZoneModel` | columna `region` en operators + tabla `zones` opcional | depende de uso real, evaluar en F8 |
| `UserCardModel` | local-only (NFC) | NO va a backend (privacidad) |
| `UserFavoriteModel` | tabla `user_favorites` (nueva, en F24 cuando los necesitemos) | añadir en migración 016 |
| `HabitualTripModel` | tabla `habitual_trips` (nueva, opcional) | añadir cuando se use |
| `TripHistoryModel` | tabla `trip_history` (nueva) | F19 logros |
| `AchievementModel`, `UserAchievementModel` | tablas `achievements`, `user_achievements` (en F19) | añadir migración 017 |
| `FeedbackMessageModel` | sub-tabla de `notifications` o estructura interna | decisión en F16 |
| **`BusLocation`** (nuevo) | inline en `bus_positions` | value object solo |
| **`FeatureRequest`** (nuevo) | `feature_requests` | F2 |
| **`OfflineRegion`** (nuevo) | `offline_regions` | F20 |
| **`RouteShare`** (nuevo) | `route_shares` | F12 |
| **`DriverInvitationCode`** (nuevo) | `invitation_codes` | F6 |
| **`UserPreferences`** (nuevo) | `user_preferences` | F17 |
| **`AppNotification`** (nuevo) | `notifications` | F12 |

## Anexo C · Plan de migración a `freezed`

| Lote | Modelos | Cuándo | Razón |
|---|---|---|---|
| 1 (alta prioridad) | UserModel, RouteModel, StopModel, ScheduleModel, IncidentModel, RouteFeedbackModel, RouteSuggestionModel | F1 | base de la mayoría de providers; rebuilds frecuentes |
| 2 (las que tocamos en B-D) | ActiveTripModel, OperatorModel, UserCardModel, RouteStopModel, ZoneModel, AlertModel | F1 | se modifican en F2-F14 |
| 3 (cuando toque) | AchievementModel, UserAchievementModel | F19 | al implementar logros |
| 4 (opcional, si crece grafo) | FeedbackMessageModel, HabitualTripModel, TripHistoryModel | F26 si hay tiempo | bajo impacto |
| nunca | RouteChangelogModel, UserFavoriteModel | — | son DTOs simples sin lógica de igualdad relevante |

## Anexo D · Matriz roles × permisos × RLS

| Permiso | passenger | driver | operatorAdmin | moderator | admin |
|---|---|---|---|---|---|
| ver rutas oficiales | ✅ (anonymous tb) | ✅ | ✅ | ✅ | ✅ |
| ver rutas comunitarias verified | ✅ | ✅ | ✅ | ✅ | ✅ |
| ver rutas comunitarias propias (todos status) | ✅ | ✅ | ✅ | ✅ | ✅ |
| crear ruta comunitaria | ✅ | ✅ | ✅ | ✅ | ✅ |
| editar ruta propia | ✅ | ✅ | ✅ | ✅ | ✅ |
| compartir ruta propia | ✅ | ✅ | ✅ | ✅ | ✅ |
| solicitar oficialización | ✅ | ✅ | ✅ | ✅ | ❌ (no aplica) |
| crear incident | ✅ | ✅ | ✅ | ✅ | ✅ |
| crear feedback | ✅ | ✅ | ✅ | ✅ | ✅ |
| crear suggestion | ✅ | ✅ | ✅ | ✅ | ✅ |
| votar | ✅ | ✅ | ✅ | ✅ | ✅ |
| publicar bus_position source='driver' | ❌ | ✅ (si en driver_assignments) | ✅ | ❌ | ✅ |
| moderar contribuciones | ❌ | ❌ | parcial (de su operador) | ✅ | ✅ |
| promover ruta a oficial | ❌ | ❌ | ❌ | ❌ | ✅ |
| gestionar usuarios | ❌ | ❌ | ❌ | ❌ | ✅ |
| ver audit_log | ❌ | ❌ | parcial (de su operador) | ❌ | ✅ |
| importar GTFS | ❌ | ❌ | ✅ (de su operador) | ❌ | ✅ |
| crear códigos invitación | ❌ | ❌ | ✅ (de su operador) | ❌ | ✅ |
| revocar driver | ❌ | ❌ | ✅ (de su operador) | ❌ | ✅ |
| ver datos personales propios | ✅ | ✅ | ✅ | ✅ | ✅ |
| eliminar cuenta propia | ✅ | ✅ | ✅ | ✅ | ✅ |

Esta matriz es la fuente de verdad. RLS la implementa en F2.3, RoleGate la implementa en F5.

## Anexo E · Glosario de naming

Para que los términos del documento original (`pendingVerification`, `verified`, etc.) y los que añadimos no choquen:

| Término | Significado en Transitly | Sinónimo a evitar |
|---|---|---|
| `RouteSource.official` | ruta del operador, importada de GTFS o creada por admin | "oficial", "operador" (ambiguo) |
| `RouteSource.community` | ruta creada por usuario | "user-route", "comunitaria" (este OK) |
| `RouteStatus.draft` | ruta en edición, no visible para nadie salvo owner | "borrador" |
| `RouteStatus.verified` | ruta comunitaria publicada, visible | "publicada" |
| `RouteStatus.pendingVerification` | ruta comunitaria con solicitud de oficial pendiente | "pending" sin contexto |
| `RouteStatus.suspended` | ruta retirada por admin | "deleted" (no es lo mismo) |
| `RouteStatus.official` | ruta que pasó community → oficial; en `routes` queda con `source='official'` y `status='official'` | "promoted" |
| `BusPositionSource.gtfsRealtime` | feed automático del operador | "real" |
| `BusPositionSource.driver` | un conductor (asignado o community) lo está retransmitiendo | "live" |
| `BusPositionSource.estimated` | calculado por horario | "predicted" |
| `BusOriginLabel.officialLive` | mostrado al usuario: oficial + (gtfs OR driver-asignado) | — |
| `BusOriginLabel.officialEstimated` | oficial + estimado | — |
| `BusOriginLabel.communityDriver` | comunidad + driver | — |
| `BusOriginLabel.communityEstimated` | comunidad + estimado | — |

## Anexo F · Política de privacidad — esqueleto

Para `assets/legal/es/privacidad.md`, secciones obligatorias:

1. Quiénes somos (responsable del tratamiento).
2. Qué datos recogemos:
   - Cuenta: email, display name, avatar (opcional).
   - Ubicación: foreground siempre que abras el mapa; background solo si activas grabar ruta o modo conductor.
   - Telemetría: solo si das consentimiento, y siempre anonimizada.
   - Reportes y contribuciones: el contenido que publicas.
3. Para qué usamos los datos.
4. Base legal (consentimiento + interés legítimo).
5. Con quién compartimos (Supabase EU, MapTiler, FCM/APNs, Sentry, PostHog — solo si consent).
6. Cuánto tiempo guardamos los datos.
7. Tus derechos (acceso, rectificación, supresión, oposición, portabilidad).
8. Cómo ejercer tus derechos (pantalla de privacidad in-app + email contacto).
9. Menores de 14 / 16 años.
10. Cambios en la política.

## Anexo G · Esfuerzo y dependencias

Estimación cualitativa (S/M/L/XL) por fase, asumiendo 1 dev solo con apoyo de IA:

| Fase | Esfuerzo | Bloquea a |
|---|---|---|
| F0 | S | F0.5 |
| F0.5 | S (½ - 1 día) | F1, F3, calidad general |
| F1 | M | F2 |
| F2 | L | F3, F4 |
| F3 | L | F4-F25 |
| F4 | M | F5 |
| F5 | M | F6 |
| F6 | M | F14 |
| F7 | L | F8, F13 |
| F8 | M | F10, F11 |
| F9 | S (recortada) | (libera F10+) |
| F10 | L | F12 |
| F11 | M | (no bloquea) |
| F12 | M | F16 |
| F13 | XL | F14 |
| F14 | L | F26 |
| F15 | L | F16 |
| F16 | XL | F26 |
| F17 | L | F18 |
| F18 | L | F26 |
| F19 | M | (decorativo) |
| F20 | L | (no bloquea) |
| F21 | L | (no bloquea) |
| F22 | M | F25 |
| F23 | XL | (no bloquea release móvil) |
| F24 | L | (no bloquea release) |
| F25 | M | F26 |
| F26 | L | release |
| F27 | M | (opcional) |

Sumando esfuerzos cualitativos, estás ante un proyecto serio. Sin prisa fijada, espera 6-12 meses con cadencia de TFG. Los hitos lógicos:

- **Hito TFG (defensa):** F0 + F0.5 + F1 + F2 + F3 + F4 + F5 + F9 + F10 + F11 + F12 + F13 (parcial: solo estimador) + F15 + F16 (parcial: bandeja + detalles) + F17 + F18 (lo crítico) + F25 + F26 parcial. Suficiente para una demo robusta.
- **Hito Beta:** todo lo anterior + F6 + F7 + F8 + F13 (full, con GTFS-Realtime) + F14 + F19 + F20 + F21 + F22.
- **Hito Producción Play Store:** beta + F23 + F24 + F25 (todo) + F26 (todo).
- **Hito v2:** F27.

## Anexo H · Cómo retomar entre sesiones

Plantilla recomendada al abrir cualquier sesión nueva con Claude Code:

```
Estoy ejecutando el Plan v2 de Transitly. Estamos en la fase F<N>.

Ya está hecho:
- F0, F1, F2 ... [lista resumida]

Bloqueantes en docs/PENDIENTES.md: [si los hay].

Vamos con el prompt <N.x>:

<pega el prompt íntegro>

Antes de tocar nada:
1. Lee docs/ARCHITECTURE.md.
2. Lee docs/PLAN_V2.md sección de la fase F<N>.
3. Lee docs/PENDIENTES.md.
4. Lee el código relacionado y devuélveme un mini-plan antes de
   ejecutarlo.
```

Esto evita que tengas que reexplicar contexto cada vez.

## Anexo I · Riesgos a vigilar

1. **Costes Supabase.** RLS mal indexadas pueden generar queries lentas y mucho egress. Audita con `EXPLAIN ANALYZE` mensualmente. Habilita `pg_stat_statements`.
2. **MapTiler.** 100k tiles/mes en free tier. Si te acercas, plan paid o tile server propio. Vigila el dashboard semanalmente.
3. **GTFS-Realtime.** Algunos feeds caen sin avisar. Edge Function `poll_gtfs_realtime` debe degradar al estimador sin generar errores cascada.
4. **Datos públicos sin acuerdo.** Si COMUJESA pidiera retirar datos, tienes que poder hacerlo: `DELETE FROM operators WHERE slug='comujesa' CASCADE` ya está pensado, pero documenta el procedimiento.
5. **Privacidad ubicación.** El driver tracking y el live recording son los puntos más sensibles. Documenta política de retención (default: 90 días para driver_trips, immediate purge en LiveRecorder local al publicar). LOPD en España y RGPD en UE.
6. **Calidad de contribuciones.** Sin moderación rápida, el sistema se llena de basura. SLA de 72h para incidents abiertos. Si tú no puedes solo, recluta moderadores en F26.
7. **Estimación errónea.** Si un usuario pierde el bus por confiar en una estimación, puede ser más que una mala UX. Considera ocultar estimaciones cuya `incertidumbre` (calculada como function de tiempo desde último datapoint real) supere un umbral.
8. **Wear/widgets.** Cada plataforma cambia frecuente y desincroniza con Flutter. Aísla código nativo y prepárate a tocarlo cada major release de iOS/Android.
9. **Tamaño del JSON COMUJESA.** 1.2MB en assets es ya frontera. Tras F7 se hidrata desde Supabase. Plantéate borrarlo del repo y dejar solo el script `generate_enriched_data.js` con un README de "cómo regenerar para seed".
10. **TFG vs producto.** No te dejes arrastrar a producto antes de defender el TFG. F26 te da una excelente defensa con "solo" F0-F18 cerradas + parte de F25-F26.

---

**Última actualización:** 2026-05-15
**Autor del plan:** Claude (con decisiones de @astralk9999)
**Próximo paso sugerido:** F26 en progreso (CI creado, docs TFG actualizados, RELEASE_CHECKLIST). Quedan: google-fonts bundle, ProGuard rules, app signing, Play Store metadata, README.
