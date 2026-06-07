#!/usr/bin/env python3
"""Reconcilia la lista de paradas de una línea con su PDF oficial.

Extrae del PDF la secuencia ordenada de paradas (código Nº PARADA + nombre por
fila), casa cada una contra las paradas existentes del operador y emite:
  - un informe de casado (cuántas filas, cuántas casan, cuáles no)
  - SQL para reconstruir route_stops de la línea con la secuencia real del PDF
    (DELETE + INSERT en orden), usando solo paradas existentes.

No crea paradas nuevas: si una fila del PDF no casa con ninguna parada existente
(por nombre), se reporta para revisión manual (probable parada que falta crear).

Uso: python tools/ocr/reconcile_stops.py <CODE> <LAB|SAB|FES>
Requiere out/route_<CODE>.json, out/all_stops.json (dump_stops.mjs) y el PDF.
"""
import json, os, re, sys, unicodedata
from difflib import SequenceMatcher
from statistics import mean

sys.path.insert(0, os.path.dirname(__file__))
from extract_line import get_boxes, center, cluster, row_names, OPERATOR  # reusa pipeline

OUT = 'tools/ocr/out'

def norm(s):
    s = unicodedata.normalize('NFD', s or '').encode('ascii', 'ignore').decode()
    return ''.join(ch for ch in s.lower() if ch.isalnum())

def best_match(name, stops):
    n = norm(name)
    best, score = None, 0.0
    for s in stops:
        r = SequenceMatcher(None, n, norm(s['name'])).ratio()
        if r > score:
            best, score = s, r
    return best, score

def main():
    code, day = sys.argv[1], sys.argv[2]
    route = json.load(open(f'{OUT}/route_{code}.json', encoding='utf-8'))
    all_stops = json.load(open(f'{OUT}/all_stops.json', encoding='utf-8'))
    boxes = get_boxes(code, day, OUT)

    # Anclamos las FILAS a las líneas de HORAS (como extract), no a los nombres
    # sueltos: cada fila de la tabla = una parada con su franja de horas. Esto
    # evita detectar nombres duplicados/ruido (que daban el doble de filas).
    TIME = re.compile(r'^[0-2]?\d[:.;][0-5]\d')
    time_centers = [center(it['box']) for it in boxes
                    if TIME.match(it['text'].strip().replace(' ', ''))]
    if not time_centers:
        print('sin horas, no se puede ubicar la rejilla'); return
    first_time_cx = min(cx for cx, _ in time_centers)
    rows_y = cluster([cy for _, cy in time_centers], 18)
    names = row_names(boxes, rows_y, first_time_cx)

    seq = []
    unmatched = []
    for ri in sorted(range(len(rows_y)), key=lambda i: rows_y[i]):
        nm = names.get(ri)
        if not nm:
            continue
        s, sc = best_match(nm, all_stops)
        if s and sc >= 0.7:
            seq.append({'stop_id': s['id'], 'name': s['name'], 'ocr': nm, 'score': round(sc, 2)})
        else:
            unmatched.append((nm, round(sc, 2), s['name'] if s else '-'))

    # Dedup consecutivos (misma parada repetida por OCR de fragmentos)
    dedup = []
    for e in seq:
        if not dedup or dedup[-1]['stop_id'] != e['stop_id']:
            dedup.append(e)

    print(f'{code} {day}: filas_nombre={len(rows_y)} casadas={len(dedup)} '
          f'sin_casar={len(unmatched)}')
    if unmatched:
        print('  sin casar:', '; '.join(f'{n!r}~{sc}({m})' for n, sc, m in unmatched[:15]))

    # SQL: reconstruye route_stops de la línea con la secuencia del PDF.
    rid = route['route_id']
    lines = ['BEGIN;', f"DELETE FROM route_stops WHERE route_id='{rid}' AND direction=0;"]
    seen = set()
    vals = []
    for i, e in enumerate(dedup):
        key = f"{e['stop_id']}:{i}"
        if key in seen:
            continue
        seen.add(key)
        vals.append(f"('{rid}','{e['stop_id']}',{i},0)")
    if vals:
        lines.append('INSERT INTO route_stops (route_id, stop_id, sequence, direction) VALUES')
        lines.append(',\n'.join(vals) + ' ON CONFLICT DO NOTHING;')
    lines.append('COMMIT;')
    out_sql = f'{OUT}/reconcile_{code}.sql'
    open(out_sql, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')
    # Volcado legible de la secuencia
    with open(f'{OUT}/reconcile_{code}.txt', 'w', encoding='utf-8') as f:
        for i, e in enumerate(dedup):
            f.write(f"{i:2}  {e['name']:32} (ocr={e['ocr']!r} {e['score']})\n")
    print(f'  -> {out_sql} ({len(vals)} paradas en orden del PDF)')

if __name__ == '__main__':
    main()
