# Inventario de datos — Transitly

> **Propósito.** Catálogo único de los datos no-código del proyecto: el JSON mock de COMUJESA, el branding, los shaders y el pipeline que produce todo eso. Si tocas un asset o un script, este documento se actualiza primero.
>
> **Estado:** vivo. Última auditoría: 2026-05-02 (post P43, sobre `assets/mock/comujesa_data.json` de 1180 KB).
>
> **Lectura previa recomendada:** [`docs/ARCHITECTURE.md`](ARCHITECTURE.md) — capas, entidades de dominio y servicios que consumen estos datos.

---

## 1. `assets/mock/comujesa_data.json` — fuente de verdad de la app

### 1.1 Resumen

| Campo | Valor |
|-------|-------|
| Ruta | `assets/mock/comujesa_data.json` |
| Tamaño | **1 180 KB** (~1.15 MB), JSON pretty-printed con `null, 2` |
| Declarado en | `pubspec.yaml` → `flutter.assets: - assets/mock/` |
| Cargado por | `MockDataService._loadFromAsset()` (`lib/data/mock/mock_data_service.dart:55-60`) vía `rootBundle.loadString` |
| Encoding | UTF-8 |
| Origen | comujesa.es (paradas y horarios) + Nominatim/coords curadas + datos demo sintéticos (ver §4) |

### 1.2 Schema (estilo `jq`) — todos los caminos

> Notación: `array[N]` indica longitud, `<type>` indica tipo escalar. Conteos reales calculados sobre el archivo del 2026-05-02.

```
.                                                     object
├─ ._metadata                                         object
│  ├─ .extractionDate                                 string  "2026-04-13"
│  ├─ .sources                                        array[2] of string  (URLs comujesa.es + jerezsinfronteras.es)
│  ├─ .scheduleType                                   string  "Horario Invierno 2025/2026 …"
│  ├─ .dataQuality                                    object
│  │  ├─ .stops                                       string
│  │  ├─ .schedules                                   string
│  │  └─ .linesWithIncompleteData                     array[1] of string
│  ├─ .pdfScheduleUrls                                object
│  │  ├─ .pattern                                     string
│  │  └─ .tipos                                       object  { LAB, SAB, FES }
│  ├─ .enrichedAt                                     string  "2026-04-13"
│  ├─ .geocoding                                      object
│  │  ├─ .totalStops                                  number  598
│  │  ├─ .geocodedFromNominatim                       number  598
│  │  ├─ .estimated                                   number  0
│  │  └─ .successRate                                 number  100
│  ├─ .polylines                                      string  (descripción)
│  └─ .demoData                                       array[10] of string
│
├─ .operator                                          object
│  ├─ .id                                             string  "comujesa"
│  ├─ .name                                           string
│  ├─ .shortName                                      string
│  ├─ .region                                         string  "Jerez de la Frontera"
│  ├─ .website                                        string
│  ├─ .phone                                          string
│  ├─ .secondaryPhone                                 string
│  ├─ .office                                         string
│  ├─ .officeHours                                    string
│  └─ .fare                                           object  { single: 1.10, currency: "EUR" }
│
├─ .lines                                             array[20]   ← 20 líneas (no 18: incluye "L15-EP" y "LEI")
│  └─ [].                                             object
│     ├─ .code                                        string  "L1", "L2", …, "L15-EP", "L16", "L17", "L18", "LEI"
│     ├─ .name                                        string  "Esteve - San Telmo"
│     ├─ .color                                       string  "#E53935"  (hex con #)
│     ├─ .serviceType                                 string  "urban" | …
│     ├─ .stops                                       array[6..88]   ← total 598
│     │  └─ [].                                       object
│     │     ├─ .name                                  string
│     │     ├─ .order                                 number  (1-indexed dentro de la línea)
│     │     ├─ .municipality                          string  "Jerez de la Frontera"
│     │     ├─ .lat                                   number  (7 decimales)
│     │     ├─ .lng                                   number
│     │     ├─ .geocodeSource                         string  "nominatim_or_known" | "partial_match" | "interpolated" | "estimated_from_prev" | "estimated_from_next" | "fallback_center"
│     │     ├─ .officialCode                          string  "JER-001" … "JER-598"
│     │     ├─ .hasShelter                            boolean
│     │     ├─ .isAccessible                          boolean
│     │     └─ .hasBench                              boolean
│     ├─ .schedules                                   object
│     │  ├─ .weekday                                  array of string "HH:MM"   (sumatorio: 401)
│     │  ├─ .saturday                                 array of string "HH:MM"   (sumatorio: 281)
│     │  └─ .sunday_holiday                           array of string "HH:MM"   (sumatorio: 207)
│     └─ .polyline                                    object
│        ├─ .type                                     string  "LineString"
│        └─ .coordinates                              object   ← Level-of-Detail, NO un array GeoJSON estándar
│           ├─ .lod0                                  array of [lng,lat]  (∑ 408   pts) — zoom < 12
│           ├─ .lod1                                  array of [lng,lat]  (∑ 1 111 pts) — zoom 12–13
│           ├─ .lod2                                  array of [lng,lat]  (∑ 2 005 pts) — zoom 13–14.5
│           ├─ .lod3                                  array of [lng,lat]  (∑ 3 690 pts) — zoom 14.5–16
│           └─ .lod4                                  array of [lng,lat]  (∑ 5 017 pts) — zoom > 16, geometría OSRM completa
│
├─ .activeTrips                                       array[4]
│  └─ [].                                             { id, lineCode, vehicleId, status, delay, delayLabel, currentStopIndex, currentStopName, nextStopName, capacity, capacityLabel, heading, speed, lastUpdated, currentPosition: {lat,lng}|null, driverName, cancellationReason? }
│
├─ .alerts                                            array[2]
│  └─ [].                                             { id, type ∈ {info, warning}, lineCode, title, description, startDate, endDate|null, isActive, affectedStops?, createdAt }
│
├─ .incidents                                         array[2]
│  └─ [].                                             { id, type ∈ {delay, noShow, …}, lineCode, stopName, description, status ∈ {pending, confirmed}, confirmations, reportedAt, reportedBy, expiresAt }
│
├─ .routeSuggestions                                  array[1]
│  └─ [].                                             { id, title, description, status, votes, contributions, proposedBy, proposedAt, proposedStops: array of string, estimatedDemand, tags: array of string }
│
├─ .feedbacks                                         array[2]
│  └─ [].                                             { id, type ∈ {scheduleError, stopMoved}, lineCode, stopName?, title, description, priority, status, reportedBy, reportedAt, affectedScheduleType? }
│
├─ .userProfiles                                      object
│  ├─ .passenger                                      { id, username, displayName, email, role, reputation, reputationLevel, reputationNextLevel, reputationNextThreshold, avatar|null, joinedAt, stats: {…}, preferences: {favoriteLines, notifications, language, theme, hapticFeedback} }
│  └─ .driver                                         { id, username, displayName, email, role, operator, assignedLine, vehicleId, reputation, reputationLevel, joinedAt, stats: {…}, shift: {start, end, days[]} }
│
├─ .transitCard                                       object
│                                                     { id, userId, type, cardNumber, displayName, balance, currency, lastRecharge: {amount, date, method}, farePerTrip, tripsRemaining, expiresAt, isActive }
│
├─ .favorites                                         array[2]
│  └─ [].                                             { id, userId, type, lineCode, stopName, stopCode, label, notifyBefore, createdAt }
│
├─ .tripHistory                                       array[10]
│  └─ [].                                             { id, userId, lineCode, date, boardingStop, alightingStop, boardingTime, alightingTime, fare, paymentMethod, onTime, delay? }
│
└─ .badges                                            array[12]
   └─ [].                                             { id, name, description, icon, category ∈ {trips, exploration, community, special}, requirement, userProgress, earned, earnedAt|null }
```

### 1.3 Conteos por colección (resumen)

| Camino | Conteo | Notas |
|--------|--------|-------|
| `.lines[]` | **20** | L1–L15, L15-EP (ramal El Portal), L16, L17, L18, LEI (Especial Institutos) |
| `.lines[].stops[]` | **598** total | Mín. 6 (LEI) · Máx. 88 (L9 circular) · Mediana ≈ 27 |
| `.lines[].schedules.weekday[]` | **889** total entries | LEI tiene 4; el resto entre 10 y 37 |
| `.lines[].schedules.saturday[]` | (incluido en 889) | LEI tiene 0 (no opera fin de semana) |
| `.lines[].schedules.sunday_holiday[]` | (incluido en 889) | LEI tiene 0 |
| `.lines[].polyline.coordinates.lod0..lod4` | 408 / 1 111 / 2 005 / 3 690 / 5 017 | Pesos crecientes ~8% / 22% / 40% / 74% / 100% |
| `.activeTrips[]` | 4 | 3 `inRoute` + 1 `cancelled` |
| `.alerts[]` | 2 | 1 `info` + 1 `warning` |
| `.incidents[]` | 2 | |
| `.routeSuggestions[]` | 1 | |
| `.feedbacks[]` | 2 | |
| `.favorites[]` | 2 | |
| `.tripHistory[]` | 10 | |
| `.badges[]` | 12 | |
| `.userProfiles.{passenger,driver}` | 2 | un único pasajero + un único conductor demo |
| `.transitCard` | 1 (objeto) | |

**Distribución de `geocodeSource`** sobre 598 paradas: `nominatim_or_known: 597` · `partial_match: 1`. Cero estimadas o fallback (todas las paradas tienen coordenada real o de match parcial).

### 1.4 Mapeo a entidades de dominio

Correspondencia con `lib/shared/models/` (ver `docs/ARCHITECTURE.md` §3).

| Camino JSON | Modelo Dart | Servicio que lo carga |
|-------------|-------------|-----------------------|
| `.operator` | `OperatorModel` | `MockDataService.operator_` |
| `.lines[]` (sin `stops`/`schedules`) | `RouteModel` | `MockDataService.routes` |
| `.lines[].stops[]` (denormalizadas) | `StopModel` (deduplicadas por nombre) + `RouteStopModel` (relación N:M ruta↔parada con `order`) | `MockDataService.stops`, `routeStops` |
| `.lines[].schedules.{weekday,saturday,sunday_holiday}[]` | `ScheduleModel` con `dayType` derivado de la clave | `MockDataService.schedules` |
| `.lines[].polyline.coordinates.lod{0..4}` | `Map<int, List<List<double>>>` (LOD entero → lista de `[lng, lat]`) | `MockDataService.polylinesLod` (campo derivado: `polylines` = LOD4) |
| `.activeTrips[]` | `ActiveTripModel` | `MockDataService.activeTrips` |
| `.alerts[]` | `AlertModel` | `MockDataService.alerts` |
| `.incidents[]` | `IncidentModel` | `MockDataService.incidents` |
| `.routeSuggestions[]` | `RouteSuggestionModel` | `MockDataService.routeSuggestions` |
| `.feedbacks[]` | `RouteFeedbackModel` | `MockDataService.feedbacks` |
| `.userProfiles.{passenger,driver}` | `UserModel` (×2 con `roles` distintos) | `MockDataService.users` |
| `.transitCard` | `UserCardModel?` | `MockDataService.transitCard` |
| `.favorites[]` | `UserFavoriteModel` | `MockDataService.favorites` |
| `.tripHistory[]` | `TripHistoryModel` | `MockDataService.tripHistory` |
| `.badges[]` | `AchievementModel` + `UserAchievementModel` (estado `earned`/`userProgress` vive en el segundo) | `MockDataService.achievements`, `userAchievements` |

### 1.5 Limitaciones documentadas

- **Horarios aproximados.** `_metadata.dataQuality.schedules` lo deja claro: derivados de primera/última salida + número de frecuencias reales. Los exactos viven en PDFs imagen de COMUJESA, no extraíbles sin OCR.
- **LEI sin contenido.** `_metadata.dataQuality.linesWithIncompleteData` enumera "Especial Institutos — página sin contenido en comujesa.es". La línea existe en `.lines[]` con 6 paradas y 4 horarios `weekday`, pero está marcada como incompleta.
- **`polyline.coordinates` no es GeoJSON estándar.** GeoJSON `LineString` exige `coordinates: [[lng,lat], …]` (array). Aquí es un objeto LOD `{lod0..lod4}`. Cualquier consumidor externo (export, validador GeoJSON) debería normalizar a LOD4 antes.

---

## 2. `assets/branding/`

| Archivo | Tamaño | Formato | Usos en la app |
|---------|--------|---------|----------------|
| `transitly_logo.png` | imagen única | PNG | **Splash screen** — `lib/features/splash/splash_screen.dart:115-120` carga `Image.asset('assets/branding/transitly_logo.png')` en un `FadeTransition` + `ScaleTransition` (160×160 px, `FilterQuality.medium`, accesibilidad: `Semantics(label: 'Transitly', image: true)`). |

**Declarado en** `pubspec.yaml` → `flutter.assets: - assets/branding/`.

**Observaciones:**

1. Solo hay **un único asset** en la carpeta. Toda la marca tipográfica del splash se construye con texto + `GoogleFonts.ibmPlexMono` (`splash_screen.dart:130-137`), no con imagen.
2. **No hay variantes** para densidades (1x/2x/3x), ni para modo oscuro, ni icono de app aparte. La app aún no tiene icono adaptativo Android ni `Assets.xcassets` poblados — se usan los placeholders por defecto de `flutter create`.
3. La carpeta queda preparada para añadir, sin tocar `pubspec.yaml`: variantes del logo, splash de marca para iOS/Android, ilustraciones de onboarding, fondos de tarjetas.

---

## 3. `shaders/`

| Archivo | Lenguaje | Tamaño | Usado por |
|---------|----------|--------|-----------|
| `smoke.frag` | GLSL fragment shader (formato Flutter `.frag`, compilado por `flutter build` vía Impeller/Skia) | — | `SmokeBackground` (`lib/shared/widgets/smoke_background.dart:54`) — `ui.FragmentProgram.fromAsset('shaders/smoke.frag')` |

**Declarado en** `pubspec.yaml` → `flutter.shaders: - shaders/smoke.frag`. Nota: la carpeta vive en la **raíz**, no dentro de `assets/`, porque Flutter trata los shaders como sección distinta.

### 3.1 Cómo se usa

`SmokeBackground` es un `StatefulWidget` que:

1. Carga el shader con `FragmentProgram.fromAsset` en `initState`.
2. Si la carga falla (`_shaderFailed = true`), degrada silenciosamente — el widget pinta sin shader.
3. Se redibuja vía un `Ticker` que actualiza el uniform `time` cada `_frameInterval` (rate-limit, no por frame del compositor).
4. El widget recibe `color` (acento de la paleta) e `isDark` (afecta a la mezcla del shader).

### 3.2 Pantallas que lo consumen

23 callsites en 17 features. Es el **fondo ambiental por defecto** de toda pantalla "no-mapa":

```
features/home/home_shell.dart                              (×2 — light & dark wrapper)
features/route_detail/route_detail_screen.dart
features/stop_detail/stop_detail_screen.dart
features/profile/{offline_data,achievements,accessibility_settings}_screen.dart
features/contributions/my_contributions_screen.dart
features/suggestions/suggest_route_screen.dart
features/feedback/feedback_screen.dart
features/management/manager_inbox_screen.dart
features/error/not_found_screen.dart
features/driver/start_route_screen.dart
features/driver/active_route_screen.dart                   (×2)
features/driver/route_editor/manual_route_editor.dart
features/driver/route_editor/post_recording_editor.dart
features/driver/route_editor/widgets/{recorder_pre_form,recorder_live_view}.dart
```

Patrón común: `Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark))` como hijo más profundo de un `Stack`. **No usado** en la `MapTab`/`transit_map.dart` (compite visualmente con tiles del mapa).

---

## 4. Pipeline de generación de `comujesa_data.json`

> El JSON que sirve la app no se escribe a mano — sale de un pipeline de cuatro pasos. Esta sección documenta entradas, transformaciones y salidas, y propone una limpieza estructural.

### 4.1 Visión global

```
┌────────────────────────────┐
│  comujesa.es (web + PDFs)  │  ← upstream humano: scrap manual
└──────────────┬─────────────┘
               │  (extracción manual: paradas, horarios, colores)
               ▼
┌──────────────────────────────────────────┐
│  comujesa_data.json (raíz)               │  ← seed sin coords ni demo data
│  · operator + lines + stops (sin lat/lng)│     (este artefacto previo NO está en el repo;
│  · schedules                             │      lo que hay hoy en raíz es el OUTPUT del paso 1)
└──────────────┬───────────────────────────┘
               │
   PASO 1 ─────┤  generate_enriched_data.js  (raíz, Node.js)
               │
               ▼
┌──────────────────────────────────────────┐
│  comujesa_data.json (raíz)  ~334 KB      │  ← in-place: sobrescribe el mismo archivo
│  + lat/lng + officialCode + flags        │
│  + polyline simple (medio punto entre    │
│    paradas, sin seguir carretera)        │
│  + activeTrips, alerts, incidents,       │
│    routeSuggestions, feedbacks,          │
│    userProfiles, transitCard, favorites, │
│    tripHistory, badges                   │
└──────────────┬───────────────────────────┘
               │
   COPIA ──────┤  (manual: cp comujesa_data.json assets/mock/)
               │
               ▼
┌──────────────────────────────────────────┐
│  assets/mock/comujesa_data.json          │
└──────────────┬───────────────────────────┘
               │
   PASO 2 ─────┤  scripts/generate_polylines.js
               │  · llama a OSRM público (router.project-osrm.org)
               │  · sustituye polyline.coordinates por geometría real
               │    que sigue carreteras (varios miles de puntos)
               │  · rate-limit 1.1s / línea
               ▼
   PASO 3 ─────┤  scripts/simplify_polylines.js
               │  · Ramer-Douglas-Peucker, tolerance 0.00008 (~9 m)
               │  · reduce a array plano simplificado
               ▼
   PASO 4 ─────┤  scripts/generate_lod_polylines.js
               │  · genera 5 niveles de detalle (lod0..lod4)
               │  · cambia coordinates: array → object {lod0..lod4}
               ▼
┌──────────────────────────────────────────┐
│  assets/mock/comujesa_data.json  ~1.18 MB│  ← lo que carga MockDataService
└──────────────────────────────────────────┘
```

### 4.2 Detalle de cada script

#### `generate_enriched_data.js` (raíz)

| Aspecto | Valor |
|---------|-------|
| Path | `generate_enriched_data.js` (raíz del repo) |
| Tamaño | 32 KB, ~1 125 LoC |
| Lee | `comujesa_data.json` (raíz) |
| Escribe | `comujesa_data.json` (raíz, **in-place**) |
| Dependencias Node | solo `fs` (stdlib) |
| Determinismo | parcialmente — usa `Math.random` seedeado con LCG (`seed = 42`) para `hasShelter`/`isAccessible`/`hasBench`/jitter de interpolación |

**Transformaciones principales:**

1. **Geocodificación** (líneas 7-456). Diccionario `KNOWN_COORDS` con ~280 paradas de Jerez con lat/lng reales (Nominatim + curado manual). Por cada parada: match exacto → match parcial (`includes`) → interpolación entre vecinos conocidos → estimación con jitter desde uno de los vecinos → fallback al centro de Jerez con jitter. Anota `geocodeSource` con la decisión tomada.
2. **Enriquecimiento de paradas** (líneas 480-491). Asigna `officialCode` `JER-NNN` incremental. `hasShelter`/`isAccessible`/`hasBench` → `true` para terminales y paradas con keywords mayores ("Plaza", "Hospital", "Estaciones", "Rotonda"); el resto, probabilidad 55/45/35%.
3. **Polyline ingenua** (líneas 499-518). Construye un `LineString` flat poniendo cada parada y un punto medio jittereado entre paradas consecutivas. **Esta polyline será sobrescrita por el paso 2** — solo sirve como placeholder.
4. **Inyección de demo data** (líneas 528-1080). Hard-codea `activeTrips` (4), `alerts` (2), `incidents` (2), `routeSuggestions` (1), `feedbacks` (2), `userProfiles` (2), `transitCard` (1), `favorites` (2), `tripHistory` (10), `badges` (12).
5. **Metadata** (líneas 1085-1104). Añade `enrichedAt`, `geocoding{totalStops, …}`, descripción de `polylines`, lista `demoData`.

#### `scripts/generate_polylines.js`

| Aspecto | Valor |
|---------|-------|
| Path | `scripts/generate_polylines.js` |
| Lee/escribe | `assets/mock/comujesa_data.json` (in-place) |
| Red | `https://router.project-osrm.org/route/v1/driving/...?overview=full&geometries=geojson` |
| Dependencias Node | stdlib (`fs`, `path`, `https`) |
| User-Agent | `TransitlyApp/1.0` |
| Rate limit | 1 100 ms entre llamadas |

Sustituye `polyline.coordinates` por la geometría que devuelve OSRM (ya en formato `[lng, lat]`), redondeada a 7 decimales. Si la API falla, conserva la geometría existente.

#### `scripts/simplify_polylines.js`

| Aspecto | Valor |
|---------|-------|
| Path | `scripts/simplify_polylines.js` |
| Lee/escribe | `assets/mock/comujesa_data.json` (in-place) |
| Algoritmo | Ramer-Douglas-Peucker recursivo |
| Tolerancia | `0.00008` grados (~9 m) — alta densidad para preservar curvas urbanas |

Pensado para ejecutarse **inmediatamente después** de `generate_polylines.js`, antes del paso de LOD. Hoy queda redundante porque el paso siguiente regenera todos los LOD desde el array crudo.

#### `scripts/generate_lod_polylines.js`

| Aspecto | Valor |
|---------|-------|
| Path | `scripts/generate_lod_polylines.js` |
| Lee/escribe | `assets/mock/comujesa_data.json` (in-place) |
| Salida | `polyline.coordinates: { lod0, lod1, lod2, lod3, lod4 }` |

Tolerancias por nivel (en grados ≈ metros):

| LOD | Tolerancia | ≈ Distancia | Zoom objetivo |
|-----|-----------|-------------|---------------|
| `lod0` | 0.003 | 330 m | < 12 |
| `lod1` | 0.0012 | 130 m | 12–13 |
| `lod2` | 0.0005 | 55 m | 13–14.5 |
| `lod3` | 0.00015 | 17 m | 14.5–16 |
| `lod4` | — | — | > 16 (todos los puntos) |

Es **idempotente** sobre su propia salida: si `coordinates` ya es objeto LOD, lo aplana usando `lod4 ?? lod3 ?? …` antes de regenerar.

### 4.3 Decisión: ¿queda `generate_enriched_data.js` en raíz o se mueve?

**Recomendación: mover a `scripts/generate_enriched_data.js`** y unificar el destino del pipeline en `assets/mock/comujesa_data.json`.

**Por qué:**

| Síntoma actual | Coste |
|----------------|-------|
| El script vive en raíz; los otros tres en `scripts/`. Inconsistencia visual y de descubrimiento. | Bajo, pero real al onboardear nueva persona. |
| El script lee y escribe `comujesa_data.json` en CWD; los demás operan sobre `assets/mock/`. Hay un **paso manual de copia** entre el paso 1 y el paso 2 que nadie ha documentado. | Alto: si alguien edita el JSON de raíz creyendo que es el que carga la app, sus cambios no aparecen. Y al revés: editar `assets/mock/` directamente queda sobreescrito si se reejecuta el paso 1. |
| `comujesa_data.json` (raíz) es un artefacto intermedio congelado desde 2026-04-13 que ya no se regenera, pero ocupa ~334 KB en la raíz del repo y aparece en `git status` como ruido visual. | Bajo. |

**Plan propuesto** (no aplicado en este commit, requiere acuerdo):

1. **`mv generate_enriched_data.js scripts/generate_enriched_data.js`**.
2. Editar el script para que `DATA_FILE` use `path.join(__dirname, '..', 'assets', 'mock', 'comujesa_data.json')` — mismo patrón que los otros tres scripts.
3. **Eliminar `comujesa_data.json` de la raíz** una vez verificado que todo el pipeline corre desde `assets/mock/`. Si se necesita una "seed sin enrichment" (input del paso 1), guardarla como `scripts/seed/comujesa_seed.json` (artefacto editado a mano cuando hay que rescrapear).
4. Añadir un `scripts/README.md` documentando el orden: `enriched → polylines → simplify → lod`. (Hoy no hay documentación de ejecución; queda implícito.)

**Coste estimado:** ~30 minutos. Sin impacto en `lib/` ni en tests.

**Riesgo de no hacerlo:** medio. Es un foot-gun que recurrentemente confunde "qué archivo es el bueno". Cualquier refactor futuro del schema (p. ej. mover de `userProfiles.{passenger,driver}` a `users[]`) tiene que sincronizarse a mano entre dos archivos.

---

## 5. Resumen — qué queda fuera de este inventario

- **Coverage** (`coverage/`): salida de `flutter test --coverage`. No es un asset de la app.
- **`build/`**: artefactos generados, gitignored.
- **`l10n/` ARB**: cubierto por `lib/l10n/` y referenciado en `ARCHITECTURE.md` §1; no es "data" de dominio.
- **`test/` fixtures**: no hay fixtures aparte; los tests que cargan datos lo hacen vía el mismo `MockDataService` o construyen modelos en línea.
- **`android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/`**: scaffolding de plataforma generado por `flutter create`. Iconos placeholder; reemplazo pendiente cuando el branding crezca (ver §2 nota 2).

---

**Última actualización:** 2026-05-02.
