# Diseño: Líneas COMUJESA en Supabase, horarios exactos por parada, offline sincronizable, wizard admin y mejoras de gestión

- **Fecha:** 2026-06-07
- **Proyecto:** nexto-stop-v2 (Transitly) — app Flutter de transporte de Jerez (COMUJESA)
- **Estado:** Aprobado para implementación (pendiente de revisión final del spec por el usuario)

## 1. Contexto y problema

La app tiene **dos fuentes de datos en paralelo**, conmutadas por sesión de auth en
`lib/data/route/route_repository_provider.dart:114`:

- **Sin sesión (anónimo)** → `RouteMockRepository(mockData)` lee el asset empaquetado
  `assets/mock/comujesa_data.json` (20 líneas reales de COMUJESA).
- **Con sesión (admin/operator/usuario)** → `RouteRepositorySwr` lee Supabase (con cache Hive).

**Verificado contra la base de datos en vivo (MCP Supabase):**

- `operators`: 1 fila (COMUJESA, `id=00000000-0000-0000-0000-000000000001`, `slug=comujesa`).
- `routes`: **0 filas**. `stops`: 0. `schedules`: 0. `route_stops`: 0.
- `user_routes`: 2, `user_stops`: 5, `user_route_stops`: 5 (rutas de comunidad existentes).
- `scheduled_departures`: 889 (probablemente huérfanas; a revisar en implementación).

**Consecuencia:** las 20 líneas de COMUJESA solo existen en el JSON. Al iniciar sesión como
admin, la app pasa a modo Supabase (0 rutas) y las líneas "desaparecen" (Gestión muestra
"Sin líneas"). Existe `tools/migrate_comujesa.dart` pensado para migrar JSON→Supabase pero
está **roto**: lee `schedules` como lista (el JSON los tiene como objeto por tipo de día) y
**no migra el trazado** (`polyline` → columna `geom`).

### Problemas adicionales reportados por el usuario

1. **Gestión de líneas** (`lib/features/management/routes_management_screen.dart`) es básica.
2. **Creador de línea admin** (`lib/features/management/route_editor_screen.dart`) es un
   formulario simple (código, nombre, color, estado). El de **comunidad**
   (`lib/features/create_route/create_route_wizard.dart`) es un wizard de 6 pasos con mapa
   (Info → Paradas → Trazado → Horarios → Visibilidad → Resumen). Se quiere esa riqueza en admin.
3. **Datos offline** (`lib/features/profile/offline_data_screen.dart`) solo recarga el asset
   empaquetado; no descarga ni actualiza desde Supabase.
4. **Horarios incompletos**: al entrar en una línea solo se ven **salidas de cabecera**, no el
   **horario completo de cada parada**. En una parada por la que pasan varias líneas solo se ve
   (parcialmente) la línea seleccionada y **no se puede seleccionar fin de semana**.
   - Datos verificados del JSON: las 20 líneas tienen los 3 tipos de día
     (`weekday`/`saturday`/`sunday_holiday`), pero **0/598 paradas** llevan horas propias.
   - Hoy la app **estima** la hora por parada con un offset fijo de `+2 min/parada`
     (`lib/data/mock/mock_data_service.dart:387`).

## 2. Objetivos / No-objetivos

### Objetivos

- Que las líneas de COMUJESA estén en Supabase (fuente de verdad) y se vean en mapa y Gestión
  estando logueado, siendo editables como líneas oficiales.
- **Horarios exactos por parada** (hora real de paso por cada parada y expedición), tomados de
  los **horarios oficiales en PDF de COMUJESA (horario de VERANO)**, con selector de tipo de día.
- **Offline sincronizable**: snapshot JSON local que se regenera desde Supabase al tener internet,
  exportable/descargable como JSON funcional; el asset empaquetado se regenera con los datos finales.
- **Wizard de creación admin** equivalente al de comunidad + asignación de operador.
- **Mejoras de Gestión de líneas**: contadores y detalle, agrupar por operador, ordenar/filtrar.

### No-objetivos (por ahora)

- Tiempo real de buses (GTFS-RT/telemetría) — fuera de alcance.
- Generación del snapshot en servidor (Edge Function) — evolución futura; de momento cliente.
- Acciones rápidas inline en Gestión (cambiar estado/operador desde la lista) — el usuario las
  descartó en esta iteración.
- Horario de invierno — se usa **verano**; el de invierno queda como evolución/segunda carga.

## 3. Arquitectura de datos (núcleo del diseño)

```
PDFs oficiales COMUJESA (verano)  ──OCR──▶  datos exactos por parada
                                               │ (one-time / re-ejecutable)
assets/mock/comujesa_data.json  ──seed──▶  Supabase (FUENTE DE VERDAD)
   (fallback 1er arranque)                   routes / stops / route_stops / schedules
                                               │  export continuo al tener internet
                                               ▼
                                   Snapshot JSON local (app docs dir)
                                   = espejo offline, mismo esquema que comujesa_data.json
                                               │
                                               ▼
                                   Export/descarga JSON funcional (compartible)
```

- **Online** (logueado): lectura en vivo de Supabase (como ahora).
- **Offline / anónimo**: lectura del **snapshot JSON local**; si no existe, el asset empaquetado.
- **Al recuperar internet**: el snapshot local se regenera desde Supabase (cumple "el JSON se
  actualiza al tener internet").
- `MockDataService` ya parsea exactamente ese esquema → el snapshot es funcional sin reescribir
  el parser; solo cambia el **origen** (archivo local con fallback al asset).

### Enfoque del snapshot (alternativas consideradas)

- (A) Solo cache Hive de tablas sueltas (lo que ya hace el SWR) — **descartado**: no produce un
  "JSON descargable".
- (B) **`SnapshotExporter` Supabase→JSON** (esquema MockData), archivo local + descargable —
  **elegido**.
- (C) Generación en servidor (Edge Function) — futura.

## 4. Modelo de datos (Supabase) — esquema verificado

Tablas y columnas relevantes (de `information_schema`):

- `routes(id uuid, operator_id uuid, source enum, status enum, code text, name text,
  description text, color text, owner_id uuid, gtfs_route_id text, geom geometry, metadata jsonb,
  created_at, updated_at)`
- `stops(id uuid, operator_id uuid, code text, name text, geom geometry NOT NULL,
  accessibility jsonb NOT NULL, gtfs_stop_id text, metadata jsonb NOT NULL, source enum, owner_id uuid)`
- `route_stops(route_id uuid, stop_id uuid, sequence int, direction smallint)` (clave compuesta)
- `schedules(id uuid, route_id uuid, day_type enum, direction smallint, departure_time time,
  arrival_offsets jsonb, notes text, created_at)`

### Decisiones de mapeo

- **Trazado**: `polyline` (LOD `{lod0..lod4}`, pares `[lng,lat]`) → `routes.geom` LINESTRING desde
  LOD4 (detalle máximo) **y** se preserva el LOD completo en `routes.metadata.polyline_lod` para no
  perder rendimiento de render en el mapa ni fidelidad al exportar.
- **Paradas**: `lat/lng` → `stops.geom` POINT (`SRID=4326`); `hasShelter/isAccessible/hasBench` →
  `stops.accessibility` jsonb (`{shelter,wheelchair,bench}`); `officialCode`/nombre → `stops.code`/`name`;
  `municipality` y demás → `stops.metadata`.
- **Horarios de cabecera**: objeto por día → filas `schedules` (una por expedición), `day_type`
  ∈ {weekday, saturday, sunday_holiday}, `departure_time`.
- **Horas exactas por parada** (Fase E): por cada expedición, `schedules.arrival_offsets` =
  mapa `{stop_id: "HH:MM"}` (hora absoluta de paso por parada en esa expedición). Esto soporta que
  el tiempo de recorrido varíe entre expediciones (no es un offset constante).

## 5. Fases

### Fase A — Seed COMUJESA → Supabase

- Generar e insertar de forma **idempotente** (upsert por `operator_id`+`code` en rutas, por
  `operator_id`+`code` en paradas): 20 rutas, paradas únicas, `route_stops` (orden), `schedules`
  (cabecera por día).
- Aplicación vía **migración Supabase (MCP `apply_migration`/`execute_sql`)** para que quede
  operativo de inmediato, **y** dejar `tools/migrate_comujesa.dart` corregido (arreglar horarios
  como objeto + añadir trazado a `geom`/metadata) como vía re-ejecutable.
- `source=official`, `status=official` (o `verified`), `metadata.active=true`.
- **Confirmación previa del usuario antes de ejecutar la escritura real en la BD en vivo.**
- **Resultado:** las 20 líneas aparecen en Gestión y mapa al estar logueado.
- **Reversible:** borrable por `operator_id`+`source=official`.

### Fase E — Horarios exactos por parada (horario de VERANO)

Fuente: PDFs oficiales en
`https://www.jerez.es/fileadmin/Documentos/Autobuses_Urbanos/horario_verano/LINEA_<N>_<TIPO>.pdf`.

- **Inventario de verano (verificado):** existen `LAB` (laborables) y `SAB` (sábados);
  **`FES`/`DOM` (domingos/festivos) dan 404** en todas las líneas probadas → en verano no se
  publican. **Decisión por defecto:** marcar domingos/festivos como "sin servicio / sin datos de
  verano" en la UI (honesto), con opción de reutilizar el horario de sábado si el usuario lo
  prefiere (a confirmar en implementación). ~20 líneas × 2 tipos ≈ 40 PDFs.
- Cada PDF es **imagen** (sin texto extraíble) con una **matriz parada × expedición**: columna
  `Nº PARADA` (códigos tipo 343/344/30…, distintos de los del JSON), `NOMBRE DE PARADA`, y la hora
  de paso por cada parada en cada expedición. (Validado leyendo L1 laborables a 300 dpi.)
- **Pipeline OCR (automatizado, pip — sin instalar nada de sistema):**
  1. Descargar los PDFs de verano.
  2. Renderizar páginas (PyMuPDF) y **OCR de la rejilla de horas** con whitelist de dígitos+`:`.
  3. **Alinear por orden de filas** al orden de paradas conocido del JSON/Supabase (el JSON ya
     tiene las paradas ordenadas), reduciendo errores; casar paradas PDF↔modelo por orden + nombre.
  4. Construir, por expedición, `{stop -> HH:MM}` y cargar a `schedules.arrival_offsets` + regenerar
     JSON/asset.
- **Rollout:** empezar con **2-3 líneas (L1 + una circular L8/L9), verificadas contra el PDF**;
  validar precisión del OCR; luego escalar a las 20.
- **Casos especiales:** líneas circulares (L8/L9) y líneas no estándar (`L15-EP`, `LEI`) pueden
  tener nombres de archivo o estructura distintos → resolver en implementación.

### Fase E (UI) — Horario por parada y por línea

- **Pantalla de parada** (`lib/features/stop_detail/stop_detail_screen.dart`):
  - Añadir **selector de tipo de día** (entre semana / sábado / domingo-festivo).
  - Mostrar, para **todas** las líneas que pasan, el **horario completo** de paso por esa parada
    en el día seleccionado (no solo "próximas 5"), con la próxima resaltada y "ver todas".
- **Pantalla de línea** (`route_detail`): además de salidas de cabecera, ofrecer ver las horas por
  parada (al tocar una parada del recorrido).
- Helper en `MockDataService`: `getStopTimetable(routeId, stopId, dayType)` y agregador
  multi-línea por parada, leyendo `arrival_offsets` cuando existan (fallback documentado si faltan).

### Fase B — Datos offline sincronizables

- `SnapshotExporter`: consulta Supabase y serializa al esquema `comujesa_data.json` (incl.
  `polyline_lod` desde `metadata`, horarios con `arrival_offsets`).
- `MockDataService`: cargar snapshot local si existe (app documents dir), si no, el asset.
- **Auto-refresh** del snapshot al detectar conexión (regenerar y persistir).
- Rediseño de **Datos offline**: "última sincronización", botón **Actualizar desde Supabase**,
  botón **Descargar/Exportar rutas en JSON** (compartible), tamaño y fecha.

### Fase C — Wizard de creación admin

- Nuevo `AdminRouteWizard` que **reutiliza los pasos de comunidad** (`StepBasicInfo`, `StepStops`
  con mapa, `StepRoutePath`, `StepSchedules`) — están desacoplados de los modelos de BD (usan
  `wizard_models.dart`; la escritura solo ocurre en `_publish`).
- Sustituir el paso **"Visibilidad"** por **"Operador + Estado"**: selector de operador (admin
  elige cualquiera; `operator_admin` fijo al suyo), estado (draft/verified/official…),
  `source=official`.
- `_publish` escribe en tablas oficiales vía RPCs admin existentes (`admin_route_upsert`,
  `admin_stop_upsert`, `admin_route_stop_add`, `admin_schedule_upsert`).
- Reemplaza el botón "Nueva línea" actual; el formulario simple se mantiene para edición rápida.

### Fase D — Mejoras de Gestión de líneas

- **Contadores y detalle**: nº de paradas y horarios por línea en cada tarjeta (vía counts/RPC).
- **Agrupar por operador**: secciones plegables (útil para admin con varios operadores).
- **Ordenar y filtrar mejor**: por código/estado/última actualización + filtros adicionales.

## 6. Orden de entrega

**A** (desbloquea ver datos reales) → **E** (datos exactos + UI de horarios, el grueso) →
**B** y **D** (en paralelo) → **C**.

## 7. Riesgos y puntos abiertos

- **Escritura en BD en vivo (Fase A):** idempotente y reversible; se confirma con el usuario antes.
- **Precisión OCR:** validación de muestra antes de carga masiva; alineación por orden de paradas;
  whitelist de dígitos. Posible verificación manual de líneas conflictivas.
- **Casado de paradas** PDF↔modelo (códigos distintos): por nombre normalizado + orden de recorrido.
- **Domingos/festivos en verano:** sin PDF publicado → por defecto "sin datos de verano"; alternativa
  reutilizar sábado (a confirmar).
- **`scheduled_departures` (889 filas):** posibles huérfanas; revisar relación con `schedules`/seed.
- **RLS `spatial_ref_sys`:** RLS desactivado (tabla de sistema PostGIS, riesgo bajo). Se deja como
  está salvo decisión del usuario de añadir política.
- **Validez temporal:** se carga horario de **verano**; documentar la fecha de validez del PDF.

## 8. Pruebas

- **Seed:** asserts de conteos (20 rutas, paradas, route_stops, schedules) tras la migración;
  re-ejecución idempotente no duplica.
- **OCR:** comparación de la matriz OCR de líneas piloto contra lectura manual del PDF (tolerancia 0
  en horas tras alineación); test de parser de rejilla.
- **Snapshot:** round-trip Supabase→JSON→`MockDataService.parse` sin pérdida (rutas/paradas/horarios/
  trazado); el snapshot exportado vuelve a parsear.
- **UI horarios:** widget tests de selector de día y de agregación multi-línea por parada.
- **Wizard admin:** crear línea oficial con operador asignado escribe en tablas correctas; visible
  en Gestión.
- Mantener verde el set de tests existente (`flutter test`).
