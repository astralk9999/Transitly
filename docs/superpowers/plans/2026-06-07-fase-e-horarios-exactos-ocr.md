# Fase E — Horarios exactos por parada (OCR PDFs de verano) + UI (Implementation Plan)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extraer de los horarios oficiales en PDF de COMUJESA (verano) la **hora exacta de paso por cada parada en cada expedición**, cargarla en Supabase (`schedules.arrival_offsets`) y el snapshot JSON, y mostrar en la app el **horario completo por parada** de **todas** las líneas que pasan, con selector entre semana / sábado (verano no publica domingos).

**Architecture:** Pipeline Python: descargar PDF → renderizar (PyMuPDF) → OCR (rapidocr-onnxruntime) → reconstruir la rejilla parada×expedición (clustering por X/Y) → casar paradas con Supabase por nombre/orden → emitir `schedules` (una fila por expedición, `arrival_offsets={stop_id: "HH:MM"}`). Aplicación vía `tools/apply_sql.mjs` (Management API). UI Flutter: nueva sección de horario por parada con selector de día y agregación multi-línea.

**Tech Stack:** Python 3 (PyMuPDF/fitz, rapidocr-onnxruntime, Pillow), Node (apply_sql.mjs), PostgreSQL/PostGIS (Supabase), Dart/Flutter (UI).

**Spec:** `docs/superpowers/specs/2026-06-07-lineas-comujesa-supabase-horarios-offline-design.md` (Fase E).

**Depende de:** Fase A (líneas/paradas ya sembradas — COMPLETADA).

---

## Estado de ejecución (2026-06-07) — PILOTO L1 + L8 CARGADO ✅

Implementado como **`tools/ocr/extract_line.py`** (monolito que cubre Tasks 1-5: descarga→render→OCR→rejilla→casado→SQL) + **`tools/ocr/fetch_route.mjs`** (vuelca route+paradas desde Supabase). Aplicado con `tools/apply_sql.mjs`. Commit `1314ede6`.

- **OCR**: rapidocr-onnxruntime (pip). **Tiling por franjas verticales** para líneas grandes (rapidocr perdía texto al redimensionar imágenes anchas; L8 pasó de 941 a 2408 horas detectadas). **Clustering por inicio de grupo** (no por último valor) para no encadenar filas densas en una sola.
- **Detección de bloques** por hueco vertical (sábados apilan 2 tablas mañana/tarde).
- **Casado de paradas por nombre** (difflib, normalizado), no por posición (el orden del seed no coincide con el PDF). Asociación nombre↔fila con `tol` estrecho (±11px) para no mezclar filas vecinas.
- **Modelo**: 1 fila `schedules` por expedición; `arrival_offsets` = array `[{"s":stop_id,"t":"HH:MM"}]` en orden (soporta paradas revisitadas por viaje).
- **Cargado y verificado:**
  - L1 LAB (23 exp.) + SAB (36 exp., 2 bloques), 0 saltos hacia atrás. "Bajada San Telmo" laborables = 35 pasos.
  - L8 LAB (42 exp., 37/39 paradas) + SAB (27 exp., 40/45), 0 saltos hacia atrás.
  - **Multi-línea por parada verificado**: Bajada San Telmo laborables → L1 (35 pasos) + L8 (40 pasos).
- **Limitaciones conocidas (pendiente):**
  - L8 (circular) tiene en el seed 83 paradas (del JSON) pero el PDF oficial lista ~39; faltan en el seed paradas reales (Ikea, Decathlon, Alcampo, Tablao…) → **reconciliar el listado de paradas de L8 desde el PDF** (las casadas tienen horas exactas; las no casadas quedan sin hora exacta).
  - Falta: escalar a las 20 líneas (Task 6), UI de parada (Task 7) y snapshot (Task 8).

---

## Hallazgos validados (prototipo sobre L1 LAB verano)

- PDFs de verano: `https://www.jerez.es/fileadmin/Documentos/Autobuses_Urbanos/horario_verano/LINEA_<N>_<TIPO>.pdf`.
  - **Solo `LAB` (laborables) y `SAB` (sábados)**; `FES`/`DOM` dan 404 → **verano no tiene domingos/festivos**.
  - Validez impresa: "VERANO 2025 · 30 JUNIO 2025 AL 07 SEPTIEMBRE 2025".
- Cada PDF es **imagen** (sin texto). Render a 300 dpi → OCR rapidocr detecta ~294 horas (conf media 0.77).
- Estructura: tabla **parada (fila) × expedición (columna)**. Columnas = viajes; cada viaje recorre las paradas en orden continuo (p.ej. Plaza Esteve 07:32 → … → última 08:05).
  - **Dos bloques por sentido** ("SENTIDO SAN TELMO" / "SENTIDO PLAZA ESTEVE") apilados verticalmente, pero forman un **recorrido continuo** (no comparten columnas distintas: una columna baja por todas las paradas).
  - **Expediciones parciales**: algunas columnas solo tienen horas en parte de las paradas (viaje que empieza/termina a mitad).
  - **Sufijos** en algunas horas (`a`,`b`,`c`) = retirada anticipada; el PDF trae leyenda (p.ej. "a = Retirada en Moreno Mendoza"). Se conservan como anotación; la hora sigue siendo válida para esa parada.
- Reconstrucción de rejilla validada: clustering por `cy` (filas) y `cx` (columnas) con tolerancias 18/22 px a 300 dpi → 0 colisiones, matriz coherente (+1 min por parada). Prototipo: `tools/ocr/grid_prototype.py`.

## Modelo de datos

- Una fila `schedules` por **expedición** (no por hora suelta como en el seed de cabecera de Fase A):
  - `route_id`, `day_type` (`weekday`|`saturday`), `direction=0`, `departure_time` = hora en la **primera parada que sirve** esa expedición.
  - `arrival_offsets` jsonb = `{ "<stop_id>": "HH:MM", ... }` para **todas** las paradas que sirve la expedición.
  - `notes` = anotación de sufijo si aplica (p.ej. "retirada en Moreno Mendoza").
- Reemplaza las filas de cabecera que sembró la Fase A para esas rutas/días (Fase A puso una fila por hora de cabecera sin `arrival_offsets`).
- **Casado de paradas**: por **nombre normalizado** (mayúsc/acentos/espacios) contra `stops` del operador, ayudado por el **orden** de recorrido (las filas del PDF van en el mismo orden que `route_stops.sequence`). Resolver desajustes de conteo (p.ej. PDF 20 filas vs 19 paradas sembradas) en la validación piloto.

---

## Task 1: Esqueleto del pipeline — descarga + render + OCR

**Files:**
- Create: `tools/ocr/ocr_timetable.py`
- Create: `tools/ocr/requirements.txt`

- [ ] **Step 1: Declarar dependencias**

Crear `tools/ocr/requirements.txt`:

```
pymupdf
rapidocr-onnxruntime
pillow
```

- [ ] **Step 2: Descargar + render + OCR de un PDF a JSON de cajas**

Crear `tools/ocr/ocr_timetable.py` con la función de OCR (cachea el PNG y el JSON de cajas):

```python
import json, os, sys, urllib.request
import fitz  # PyMuPDF
from rapidocr_onnxruntime import RapidOCR

BASE = "https://www.jerez.es/fileadmin/Documentos/Autobuses_Urbanos/horario_verano"
_ocr = None

def ocr_engine():
    global _ocr
    if _ocr is None:
        _ocr = RapidOCR()
    return _ocr

def fetch_pdf(line_code, day, outdir):
    # day in {'LAB','SAB'}
    name = f"LINEA_{line_code}_{day}.pdf"
    path = os.path.join(outdir, name)
    if not os.path.exists(path):
        url = f"{BASE}/{name}"
        urllib.request.urlretrieve(url, path)
    return path

def render_png(pdf_path, dpi=300):
    png = pdf_path.replace('.pdf', f'_{dpi}.png')
    doc = fitz.open(pdf_path)
    # Algunas tablas ocupan varias páginas; por ahora página 0 (verano L1 = 1 pág).
    page = doc[0]
    pix = page.get_pixmap(dpi=dpi)
    pix.save(png)
    return png, pix.width, pix.height

def ocr_boxes(png_path):
    res, _ = ocr_engine()(png_path)
    return [{'box': r[0], 'text': r[1], 'conf': float(r[2])} for r in (res or [])]

if __name__ == '__main__':
    code, day = sys.argv[1], sys.argv[2]
    outdir = sys.argv[3] if len(sys.argv) > 3 else '.'
    pdf = fetch_pdf(code, day, outdir)
    png, w, h = render_png(pdf)
    boxes = ocr_boxes(png)
    json.dump(boxes, open(os.path.join(outdir, f'boxes_{code}_{day}.json'), 'w'), ensure_ascii=False)
    print(f'{code} {day}: {len(boxes)} cajas, png {w}x{h}')
```

- [ ] **Step 3: Verificar contra L1 LAB**

Run: `python tools/ocr/ocr_timetable.py 1 LAB tools/ocr/out`
Expected: imprime `1 LAB: ~419 cajas, png 3509x1009` y crea `tools/ocr/out/boxes_1_LAB.json`.

- [ ] **Step 4: Commit**

```bash
git add tools/ocr/ocr_timetable.py tools/ocr/requirements.txt
git commit -m "feat(ocr): pipeline descarga+render+ocr de horarios verano"
```

---

## Task 2: Reconstrucción de la rejilla parada×expedición

**Files:**
- Create: `tools/ocr/grid.py`
- Test: `tools/ocr/out/boxes_1_LAB.json` (de Task 1)

- [ ] **Step 1: Implementar el reconstructor (basado en el prototipo validado)**

Crear `tools/ocr/grid.py`. Partir de `tools/ocr/grid_prototype.py` (ya validado) y exponer `build_grid(boxes) -> {'rows': [...], 'cols': [...], 'cells': {(r,c): {'t','suf','conf'}}}`:

```python
import re
from statistics import mean

TIME = re.compile(r'^([0-2]?\d)[:.;]([0-5]\d)([a-zA-Z])?$')

def _center(box):
    return (sum(p[0] for p in box) / 4.0, sum(p[1] for p in box) / 4.0)

def _cluster(vals, tol):
    vals = sorted(vals)
    groups = [[vals[0]]]
    for v in vals[1:]:
        (groups[-1].append(v) if v - groups[-1][-1] <= tol else groups.append([v]))
    return [mean(g) for g in groups]

def parse_times(boxes):
    out = []
    for it in boxes:
        t = it['text'].strip().replace(' ', '')
        m = TIME.match(t)
        if not m:
            continue
        hh, mm = int(m.group(1)), int(m.group(2))
        if hh > 23:
            continue
        cx, cy = _center(it['box'])
        out.append({'cx': cx, 'cy': cy, 't': f'{hh:02d}:{mm:02d}',
                    'suf': (m.group(3) or '').lower(), 'conf': it['conf']})
    return out

def build_grid(boxes, row_tol=18, col_tol=22):
    toks = parse_times(boxes)
    rows = _cluster([t['cy'] for t in toks], row_tol)
    cols = _cluster([t['cx'] for t in toks], col_tol)
    def near(v, cs):
        return min(range(len(cs)), key=lambda i: abs(cs[i] - v))
    cells = {}
    for t in toks:
        key = (near(t['cy'], rows), near(t['cx'], cols))
        cur = cells.get(key)
        if cur is None or t['conf'] > cur['conf']:
            cells[key] = t
    return {'rows': rows, 'cols': cols, 'cells': cells}
```

- [ ] **Step 2: Verificar dimensiones y coherencia**

Run:
```bash
python -c "import json,sys; sys.path.insert(0,'tools/ocr'); from grid import build_grid; g=build_grid(json.load(open('tools/ocr/out/boxes_1_LAB.json',encoding='utf-8'))); print('rows',len(g['rows']),'cols',len(g['cols']),'cells',len(g['cells']))"
```
Expected: `rows ~20 cols ~23 cells ~354` (coherente con el prototipo). Si difiere mucho, ajustar `row_tol`/`col_tol`.

- [ ] **Step 3: Commit**

```bash
git add tools/ocr/grid.py
git commit -m "feat(ocr): reconstruccion de rejilla parada x expedicion"
```

---

## Task 3: Casado de paradas y construcción de expediciones

**Files:**
- Create: `tools/ocr/build_trips.py`

- [ ] **Step 1: Mapear filas→paradas y columnas→expediciones**

Crear `tools/ocr/build_trips.py`. Entrada: grid + lista ordenada de paradas de la ruta (nombre + stop_id, traída de Supabase o del JSON). Lógica:

- Ordenar `rows` por `cy` y `cols` por `cx`.
- Asignar cada índice de fila a la parada en esa posición de orden. Si `len(rows) != len(stops)`: alinear por **nombre** OCR de la columna izquierda (cajas de texto no-hora más a la izquierda) con los nombres de parada (fuzzy, normalizando acentos/espacios); registrar y reportar desajustes para revisión manual.
- Para cada columna (expedición): recoger las celdas presentes `{stop_id: "HH:MM"}` en orden de fila; `departure_time` = primera hora; descartar columnas con < 2 celdas (ruido).
- Devolver `trips = [ {departure, offsets: {stop_id: hhmm}, partial: bool}, ... ]`.

```python
import unicodedata

def norm(s):
    s = unicodedata.normalize('NFD', s or '').encode('ascii', 'ignore').decode()
    return ''.join(ch for ch in s.lower() if ch.isalnum())

def build_trips(grid, stops_in_order):
    # stops_in_order: list of {'stop_id': str, 'name': str}
    rows = sorted(range(len(grid['rows'])), key=lambda i: grid['rows'][i])
    cols = sorted(range(len(grid['cols'])), key=lambda i: grid['cols'][i])
    # Mapa fila->stop por posición (asume mismo orden; validar conteo aparte).
    row_to_stop = {}
    for pos, r in enumerate(rows):
        if pos < len(stops_in_order):
            row_to_stop[r] = stops_in_order[pos]['stop_id']
    trips = []
    for c in cols:
        offsets = {}
        for r in rows:
            cell = grid['cells'].get((r, c))
            sid = row_to_stop.get(r)
            if cell and sid:
                offsets[sid] = cell['t']
        if len(offsets) < 2:
            continue
        departure = min(offsets.values())
        trips.append({'departure': departure, 'offsets': offsets,
                      'partial': len(offsets) < len(stops_in_order)})
    return trips
```

- [ ] **Step 2: Verificar nº de expediciones y cobertura**

Run: un script que cargue grid de L1 LAB + las 19 paradas de L1 (de Supabase via `tools/apply_sql.mjs` o un dump), llame `build_trips`, e imprima: nº de trips, nº de trips parciales, y las horas de la primera parada (deben coincidir con la cabecera del JSON: 21 salidas laborables ± las parciales).
Expected: ~21-23 trips; las horas de cabecera ⊇ las 21 del JSON.

- [ ] **Step 3: Commit**

```bash
git add tools/ocr/build_trips.py
git commit -m "feat(ocr): casado de paradas y construccion de expediciones"
```

---

## Task 4: Validación piloto contra el PDF (ground truth)

**Files:**
- Create: `tools/ocr/validate_pilot.py`

- [ ] **Step 1: Comparar la matriz OCR con una transcripción manual de control**

Para L1 LAB: transcribir manualmente (mirando el PNG a 300 dpi) **3 columnas completas** (primera, una intermedia, última) y compararlas celda a celda con la salida del pipeline. El script reporta discrepancias.

- [ ] **Step 2: Criterio de aceptación**

Expected: 0 discrepancias en las 3 columnas de control tras corrección de sufijos. Si hay errores OCR sistemáticos (p.ej. `8`↔`6`), añadir post-corrección por contexto (monotonía: la hora de una parada crece a lo largo de la columna y entre columnas consecutivas).

- [ ] **Step 3: Commit**

```bash
git add tools/ocr/validate_pilot.py
git commit -m "test(ocr): validacion piloto L1 contra PDF"
```

---

## Task 5: Emitir y aplicar `schedules` con `arrival_offsets` (piloto L1 + 1 circular)

**Files:**
- Create: `tools/ocr/emit_schedules_sql.py`

- [ ] **Step 1: Generar SQL idempotente de schedules por expedición**

`emit_schedules_sql.py` produce, para una ruta+día: `DELETE FROM schedules WHERE route_id=<id> AND day_type='<d>';` seguido de un `INSERT ... VALUES` multi-fila con `(route_id, day_type, 0, departure::time, '<offsets_json>'::jsonb, <notes>)`. Resolver `route_id` y `stop_id` consultando Supabase por `code`/nombre (vía `apply_sql.mjs` con SELECT, o un dump previo).

- [ ] **Step 2: Aplicar a Supabase (piloto: L1 + L8 o L9 circular)**

Run: generar SQL y aplicar con `node tools/apply_sql.mjs <archivo>`.
Expected: HTTP 201. Verificar (SQL): para L1, `select count(*) from schedules where route_id=<L1> and day_type='weekday'` ≈ nº de expediciones; y `arrival_offsets ? '<stop_id_plaza_esteve>'` no vacío.

- [ ] **Step 3: Verificar consulta "horario por parada"**

Run (SQL): para una parada compartida por varias líneas, listar todas las horas de paso por día. Debe devolver filas de **todas** las líneas que pasan.

- [ ] **Step 4: Commit**

```bash
git add tools/ocr/emit_schedules_sql.py
git commit -m "feat(ocr): emitir y aplicar schedules con arrival_offsets (piloto)"
```

---

## Task 6: Escalar a las 20 líneas (LAB + SAB)

**Files:**
- Create: `tools/ocr/run_all.py`

- [ ] **Step 1: Iterar todas las líneas y días disponibles**

`run_all.py` recorre los códigos de línea (1..18, y los especiales `15-EP`/`LEI` con su nombre de archivo real — resolver probando URLs), descarga `LAB` y `SAB` (omitir 404), ejecuta el pipeline y acumula el SQL. Las líneas **circulares** (L8/L9) y de estructura distinta pueden necesitar `row_tol`/`col_tol` u orden de paradas específicos — parametrizar por línea.

- [ ] **Step 2: Validación por muestreo**

Para cada línea, comprobar invariantes: horas monótonas crecientes por columna; nº de paradas casadas == paradas de la ruta (±1, reportar); rango horario plausible (06:00–23:59).

- [ ] **Step 3: Aplicar y verificar totales**

Run: aplicar el SQL agregado; verificar `select route_id, day_type, count(*) from schedules group by 1,2` cubre las 20 líneas en `weekday` y `saturday` (sin `sunday_holiday`).

- [ ] **Step 4: Commit**

```bash
git add tools/ocr/run_all.py
git commit -m "feat(ocr): escalar extraccion a las 20 lineas (LAB+SAB)"
```

---

## Task 7: UI — horario completo por parada con selector de día y multi-línea

**Files:**
- Modify: `lib/data/mock/mock_data_service.dart` (helper `getStopTimetable`)
- Modify: `lib/features/stop_detail/stop_detail_screen.dart`
- Modify: `lib/features/route_detail/widgets/route_detail_schedule_section.dart` (opcional: horas por parada)

- [ ] **Step 1: Helper de horario por parada (lee `arrival_offsets`)**

En el repositorio/servicio que sirve horarios, añadir `List<StopTimetableEntry> getStopTimetable(stopId, {DayType day})` que recorra todas las rutas que pasan por `stopId` y, para cada expedición de cada ruta en ese día, devuelva `{routeId, routeCode, color, time}` leyendo el offset de esa parada. Ordenar por hora. (En modo Supabase, query equivalente sobre `schedules.arrival_offsets`.)

- [ ] **Step 2: Selector de día en la pantalla de parada**

En `stop_detail_screen.dart`, añadir las pestañas **Entre semana / Sábado** (verano no tiene domingo; mostrar nota "Sin servicio dominical en verano" si se selecciona). Reemplazar "Próximas llegadas (5)" por: por cada línea que pasa, su **horario completo** del día seleccionado (próxima resaltada, "ver todas"), agrupado por línea.

- [ ] **Step 3: Widget tests**

Tests: `getStopTimetable` agrega varias líneas; el selector de día cambia el conjunto; una parada de varias líneas muestra todas.

- [ ] **Step 4: Commit**

```bash
git add lib/data/mock/mock_data_service.dart lib/features/stop_detail/stop_detail_screen.dart
git commit -m "feat(schedules): horario completo por parada, multi-linea y selector de dia"
```

---

## Task 8: Regenerar snapshot/asset con horarios exactos

**Files:**
- (Coordinar con Fase B) Modify: el exportador de snapshot incluye `arrival_offsets`.

- [ ] **Step 1: Incluir `arrival_offsets` en el JSON**

Asegurar que el esquema del JSON (y el parser `MockDataService`) puede transportar horas por parada por expedición. Si la Fase B aún no existe, dejar el helper leyendo Supabase en modo online y documentar el campo en el JSON para la Fase B.

- [ ] **Step 2: Commit**

```bash
git commit -m "feat(schedules): exponer arrival_offsets en el snapshot offline"
```

---

## Self-Review (cobertura del spec — Fase E)

- **Horas exactas por parada desde PDFs de verano** → Tasks 1-6 (pipeline OCR + carga). ✓
- **Pipeline OCR automatizado** → Tasks 1-3, 6. ✓
- **Empezar con 2-3 líneas validadas** → Tasks 4-5 (piloto L1 + circular) antes de escalar (Task 6). ✓
- **Horario completo por parada, todas las líneas, selector de día** → Task 7. ✓
- **Verano sin domingos** → Task 6/7 (omitir `sunday_holiday`, nota en UI). ✓
- **`schedules.arrival_offsets` como modelo** → "Modelo de datos" + Task 5. ✓
- **Snapshot offline con horas exactas** → Task 8 (coordina con Fase B). ✓

**Riesgos / abiertos:**
- Líneas circulares (L8/L9) y especiales (`15-EP`, `LEI`): estructura/nombre de archivo distintos → parametrizar (Task 6).
- Desajuste de conteo paradas PDF vs sembradas (L1: 20 filas OCR vs 19 paradas) → reconciliar por nombre en Task 3/4.
- Errores OCR puntuales → post-corrección por monotonía + validación de muestra (Task 4).
- Validez "verano 2025" (30 jun–7 sep): documentar; el de invierno sería una segunda carga futura.
