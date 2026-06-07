#!/usr/bin/env python3
"""Extrae el horario exacto por parada de un PDF de COMUJESA (verano) y emite
SQL de `schedules` con arrival_offsets.

Uso: python tools/ocr/extract_line.py <CODE> <LAB|SAB> [outdir]

Requiere out/route_<CODE>.json (de fetch_route.mjs). Cachea PDF/PNG/boxes.
"""
import json, os, re, sys, urllib.request, unicodedata
from difflib import SequenceMatcher
from statistics import mean
import fitz  # PyMuPDF
from rapidocr_onnxruntime import RapidOCR

# La consola de Windows (cp1252) rompe al imprimir nombres OCR con caracteres
# fuera de su tabla (basura CJK ocasional). Forzamos UTF-8 con reemplazo para
# que un nombre raro no aborte la escritura del SQL.
try:
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')
except Exception:
    pass

ROOT = "https://www.jerez.es/fileadmin/Documentos/Autobuses_Urbanos"
# Verano (LAB/SAB) por elección del proyecto; domingos/festivos (FES) no se
# publican en verano, así que se toman del horario de invierno (única fuente
# oficial de domingos). Hybrid documentado en el plan.
SEASON = {"LAB": "horario_verano", "SAB": "horario_verano", "FES": "horario_invierno"}
DAY_TYPE = {"LAB": "weekday", "SAB": "saturday", "FES": "sunday_holiday"}
OPERATOR = "00000000-0000-0000-0000-000000000001"
TIME = re.compile(r'^([0-2]?\d)[:.;]([0-5]\d)([a-zA-Z])?$')

_ocr = None
def ocr_engine():
    global _ocr
    if _ocr is None:
        _ocr = RapidOCR()
    return _ocr

def norm(s):
    s = unicodedata.normalize('NFD', s or '').encode('ascii', 'ignore').decode()
    return ''.join(ch for ch in s.lower() if ch.isalnum())

def center(box):
    return (sum(p[0] for p in box) / 4.0, sum(p[1] for p in box) / 4.0)

def cluster(vals, tol):
    # Compara con el INICIO del grupo (no el último valor) para que un grupo
    # abarque como máximo `tol` px. Evita el encadenamiento que colapsaba todas
    # las filas en una sola cuando hay muchas horas densas (líneas largas).
    vals = sorted(vals)
    groups = [[vals[0]]]
    for v in vals[1:]:
        (groups[-1].append(v) if v - groups[-1][0] <= tol else groups.append([v]))
    return [mean(g) for g in groups]

def pdf_number(code):
    # Código BD 'L1'/'L8'/'L15-EP' -> número de archivo del PDF '1'/'8'/'15'.
    return re.sub(r'^L', '', code).split('-')[0]

def ocr_tiled(png_path, tile=1300, overlap=220, max_side=1600):
    """OCR por franjas verticales para imágenes anchas: rapidocr redimensiona
    el lado largo y pierde el texto pequeño de las tablas grandes. Troceamos en
    columnas, OCRamos cada franja y remapeamos coordenadas a la imagen completa.
    """
    from PIL import Image
    im = Image.open(png_path)
    W, H = im.size
    out = []
    if W <= max_side:
        res, _ = ocr_engine()(png_path)
        for r in (res or []):
            out.append({'box': [[p[0], p[1]] for p in r[0]], 'text': r[1], 'conf': float(r[2])})
        return out
    x = 0
    while x < W:
        x1 = min(x + tile, W)
        tmp = png_path.replace('.png', f'_x{x}.png')
        im.crop((x, 0, x1, H)).save(tmp)
        res, _ = ocr_engine()(tmp)
        for r in (res or []):
            out.append({'box': [[p[0] + x, p[1]] for p in r[0]], 'text': r[1], 'conf': float(r[2])})
        if x1 >= W:
            break
        x += tile - overlap
    return out

def _dedup(boxes, tol=12):
    """Elimina detecciones duplicadas en las zonas de solape (mismo texto y
    centro cercano), conservando la de mayor confianza."""
    def c(b):
        return (sum(p[0] for p in b) / 4.0, sum(p[1] for p in b) / 4.0)
    kept = []
    for it in sorted(boxes, key=lambda z: -z['conf']):
        cx, cy = c(it['box'])
        if any(it['text'] == k['text'] and abs(cx - kc[0]) < tol and abs(cy - kc[1]) < tol
               for k, kc in kept):
            continue
        kept.append((it, (cx, cy)))
    return [k for k, _ in kept]

def get_boxes(code, day, outdir):
    cache = os.path.join(outdir, f'boxes_{code}_{day}.json')
    if os.path.exists(cache):
        return json.load(open(cache, encoding='utf-8'))
    num = pdf_number(code)
    # Orden de temporadas a intentar: la preferida del día primero, la otra
    # como fallback (algunas líneas publican un tipo de día solo en una
    # temporada — p.ej. sábados de L17 solo en invierno).
    preferred = SEASON[day]
    seasons = [preferred] + [s for s in ('horario_verano', 'horario_invierno') if s != preferred]
    pdf = None
    for season in seasons:
        cand = os.path.join(outdir, f'LINEA_{num}_{day}_{season[-7:]}.pdf')
        if os.path.exists(cand) and os.path.getsize(cand) > 1000:
            pdf = cand
            break
        try:
            import urllib.error
            req = urllib.request.Request(f'{ROOT}/{season}/LINEA_{num}_{day}.pdf',
                                         headers={'User-Agent': 'Mozilla/5.0'})
            data = urllib.request.urlopen(req, timeout=30).read()
            if len(data) > 1000 and data[:4] == b'%PDF':
                with open(cand, 'wb') as f:
                    f.write(data)
                pdf = cand
                break
        except Exception:
            continue
    if pdf is None:
        return []  # sin PDF en ninguna temporada
    doc = fitz.open(pdf)
    all_boxes = []
    y_off = 0
    for page in doc:  # algunas tablas (líneas largas) ocupan varias páginas
        png = pdf.replace('.pdf', f'_p{page.number}.png')
        pix = page.get_pixmap(dpi=300)
        pix.save(png)
        for it in ocr_tiled(png):
            it['box'] = [[p[0], p[1] + y_off] for p in it['box']]
            all_boxes.append(it)
        y_off += pix.height
    all_boxes = _dedup(all_boxes)
    # Escritura atómica: evita cachés corruptas si el proceso se corta a mitad.
    tmp = cache + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as f:
        json.dump(all_boxes, f, ensure_ascii=False)
    os.replace(tmp, cache)
    return all_boxes

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
        cx, cy = center(it['box'])
        out.append({'cx': cx, 'cy': cy, 't': f'{hh:02d}:{mm:02d}',
                    'suf': (m.group(3) or '').lower(), 'conf': it['conf']})
    return out

def row_names(boxes, row_centers, first_time_cx, tol=11):
    """Para cada fila (y-center), el nombre de parada = caja(s) de texto con
    letras, a la izquierda de la primera columna de horas. `tol` estrecho para
    no capturar nombres de filas vecinas (clave en líneas con filas juntas).
    Solo une fragmentos cuyo cy esté MUY cerca (mismo renglón partido)."""
    names = {}
    for ri, ry in enumerate(row_centers):
        cands = []
        for it in boxes:
            cx, cy = center(it['box'])
            if abs(cy - ry) > tol or cx >= first_time_cx - 5:
                continue
            txt = it['text'].strip()
            if any(ch.isalpha() for ch in txt):  # descarta el código numérico
                cands.append((cy, cx, txt))
        if not cands:
            continue
        # Renglón más cercano al centro; une solo fragmentos a ±4px de ese cy.
        cands.sort(key=lambda z: abs(z[0] - ry))
        base_cy = cands[0][0]
        frag = sorted((c for c in cands if abs(c[0] - base_cy) <= 4), key=lambda z: z[1])
        names[ri] = ' '.join(t for _, _, t in frag)
    return names

def longest_non_decreasing(values):
    """Índices que forman la subsecuencia no-decreciente más larga (LIS).
    Se usa para quedarnos solo con las horas coherentes de una expedición y
    descartar las celdas con OCR/casado erróneo (las que rompen la monotonía),
    en vez de mostrar una hora incorrecta."""
    n = len(values)
    if n == 0:
        return set()
    piles, pile_idx, prev = [], [], [-1] * n
    for i, v in enumerate(values):
        lo, hi = 0, len(piles)
        while lo < hi:
            mid = (lo + hi) // 2
            if piles[mid] <= v:
                lo = mid + 1
            else:
                hi = mid
        if lo > 0:
            prev[i] = pile_idx[lo - 1]
        if lo == len(piles):
            piles.append(v); pile_idx.append(i)
        else:
            piles[lo] = v; pile_idx[lo] = i
    k = pile_idx[-1]
    keep = set()
    while k != -1:
        keep.add(k); k = prev[k]
    return keep

def match_stop(name, stops):
    n = norm(name)
    best, score = None, 0.0
    for s in stops:
        r = SequenceMatcher(None, n, norm(s['name'])).ratio()
        if r > score:
            best, score = s, r
    return best, score

def main():
    code, day = sys.argv[1], sys.argv[2]
    outdir = sys.argv[3] if len(sys.argv) > 3 else 'tools/ocr/out'
    route = json.load(open(os.path.join(outdir, f'route_{code}.json'), encoding='utf-8'))
    stops = route['stops']
    # Universo de casado: las paradas de la ruta + (si existe) TODAS las del
    # operador. El recorrido real del PDF puede incluir paradas que el seed
    # asignó a otras líneas (p.ej. Luz Shopping, Alcampo en L9); casar contra
    # todas recupera esas. El filtro de monotonía descarta casados erróneos.
    universe = stops
    allp = os.path.join(outdir, 'all_stops.json')
    if os.path.exists(allp):
        extra = json.load(open(allp, encoding='utf-8'))
        seen = {s['stop_id'] for s in stops}
        merged = list(stops)
        for e in extra:
            if e['id'] not in seen:
                merged.append({'stop_id': e['id'], 'name': e['name']})
        universe = merged
    boxes = get_boxes(code, day, outdir)
    toks = parse_times(boxes)
    if not toks:
        print(f'{code} {day}: SIN horas detectadas'); return
    row_centers = cluster([t['cy'] for t in toks], 18)
    first_time_cx = min(t['cx'] for t in toks)

    def near(v, cs):
        return min(range(len(cs)), key=lambda i: abs(cs[i] - v))

    for t in toks:
        t['row'] = near(t['cy'], row_centers)

    # Detección de bloques: algunos PDFs (p.ej. sábados) apilan dos tablas
    # verticalmente. Partimos por huecos verticales grandes entre filas para
    # NO mezclar expediciones de bloques distintos en una misma columna.
    import statistics
    sorted_rows = sorted(range(len(row_centers)), key=lambda i: row_centers[i])
    ys = [row_centers[i] for i in sorted_rows]
    gaps = [ys[i + 1] - ys[i] for i in range(len(ys) - 1)]
    med = statistics.median(gaps) if gaps else 0
    blocks = [[sorted_rows[0]]]
    for k in range(len(gaps)):
        if med and gaps[k] > 1.8 * med:
            blocks.append([])
        blocks[-1].append(sorted_rows[k + 1])

    # Nombre de parada por fila + casado (global)
    names = row_names(boxes, row_centers, first_time_cx)
    row_stop, unmatched = {}, []
    for ri in range(len(row_centers)):
        nm = names.get(ri)
        if not nm:
            unmatched.append((ri, '(sin nombre OCR)')); continue
        # Primero contra las paradas de la propia ruta (umbral permisivo);
        # si no casa, contra todo el operador (umbral más estricto para no
        # casar con una parada homónima de otra zona).
        s, sc = match_stop(nm, stops)
        if s and sc >= 0.5:
            row_stop[ri] = s['stop_id']
        else:
            s2, sc2 = match_stop(nm, universe)
            if s2 and sc2 >= 0.62:
                row_stop[ri] = s2['stop_id']
            else:
                unmatched.append((ri, f'{nm!r} (mejor {max(sc, sc2):.2f})'))

    # Expediciones: por bloque, clustering de columnas LOCAL al bloque.
    trips = []
    total_cols = 0
    for blk in blocks:
        blk_set = set(blk)
        blk_toks = [t for t in toks if t['row'] in blk_set]
        if not blk_toks:
            continue
        cols = cluster([t['cx'] for t in blk_toks], 22)
        total_cols += len(cols)
        cells = {}
        for t in blk_toks:
            k = (t['row'], near(t['cx'], cols))
            if k not in cells or t['conf'] > cells[k]['conf']:
                cells[k] = t
        order_cols = sorted(range(len(cols)), key=lambda i: cols[i])
        order_rows = sorted(blk, key=lambda r: row_centers[r])
        for c in order_cols:
            seq = []
            for r in order_rows:
                cell = cells.get((r, c))
                sid = row_stop.get(r)
                if cell and sid:
                    seq.append({'s': sid, 't': cell['t']})
            # Filtro de monotonía: nos quedamos con la subsecuencia de horas
            # coherente más larga y descartamos las celdas que rompen el orden
            # (OCR/casado erróneo). Si tras filtrar se pierde >40% de paradas,
            # la expedición es poco fiable y se descarta entera.
            if len(seq) >= 2:
                def _m(e):
                    return int(e['t'][:2]) * 60 + int(e['t'][3:5])
                keep = longest_non_decreasing([_m(e) for e in seq])
                clean = [e for i, e in enumerate(seq) if i in keep]
                if len(clean) >= 2 and len(clean) >= 0.6 * len(seq):
                    trips.append(clean)

    # Resumen de validación
    matched = len(row_stop)
    print(f'{code} {day}: filas={len(row_centers)} casadas={matched} '
          f'sin_casar={len(unmatched)} bloques={len(blocks)} columnas={total_cols} '
          f'expediciones={len(trips)}')
    if unmatched:
        print('  sin casar:', '; '.join(f'r{ri}:{info}' for ri, info in unmatched[:12]))

    # Validación de monotonía: dentro de una expedición la hora no debe
    # decrecer (salvo cruce de medianoche, inexistente aquí). Cuenta saltos
    # hacia atrás > 0 min como sospechosos.
    def mins(t):
        h, m = t.split(':'); return int(h) * 60 + int(m)
    name_by_id = {s['stop_id']: s['name'] for s in stops}
    bad = 0
    for seq in trips:
        for a, b in zip(seq, seq[1:]):
            if mins(b['t']) < mins(a['t']):
                bad += 1
    print(f'  monotonia: {bad} saltos hacia atras en {sum(len(s)-1 for s in trips)} transiciones')
    if trips:
        s0 = trips[0]
        preview = ' | '.join(f"{name_by_id.get(e['s'],'?')[:14]}={e['t']}" for e in s0[:6])
        print('  expedicion[0]:', preview)
    # Volcado legible
    dump = os.path.join(outdir, f'trips_{code}_{day}.txt')
    with open(dump, 'w', encoding='utf-8') as f:
        for i, seq in enumerate(trips):
            f.write(f'== expedicion {i} ==\n')
            for e in seq:
                f.write(f"  {name_by_id.get(e['s'],'?'):28} {e['t']}\n")

    # Emitir SQL
    day_type = DAY_TYPE[day]
    rid = route['route_id']
    lines = ['BEGIN;', f"DELETE FROM schedules WHERE route_id='{rid}' AND day_type='{day_type}';"]
    vals = []
    for seq in trips:
        dep = seq[0]['t']
        offs = json.dumps(seq, ensure_ascii=False).replace("'", "''")
        vals.append(f"('{rid}','{day_type}',0,'{dep}','{offs}'::jsonb)")
    if vals:
        lines.append("INSERT INTO schedules (route_id, day_type, direction, departure_time, arrival_offsets) VALUES")
        lines.append(',\n'.join(vals) + ';')
    lines.append('COMMIT;')
    sql_path = os.path.join(outdir, f'schedules_{code}_{day}.sql')
    open(sql_path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    print(f'  SQL -> {sql_path} ({len(trips)} expediciones)')

if __name__ == '__main__':
    main()
