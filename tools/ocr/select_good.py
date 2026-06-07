#!/usr/bin/env python3
"""Evalúa los schedules_*.sql ya generados por monotonía (leyendo los propios
arrival_offsets) y copia a out/apply/ los que cumplen el criterio de calidad:
  - >= 3 expediciones
  - <= MAX_BACK saltos hacia atrás (errores OCR puntuales tolerados)

No depende del stdout del OCR. Imprime un reporte y deja en out/apply/ solo los
fiables. Uso: python tools/ocr/select_good.py [MAX_BACK]
"""
import glob, json, os, re, shutil, sys

OUT = 'tools/ocr/out'
APPLY = os.path.join(OUT, 'apply')
MAX_BACK = int(sys.argv[1]) if len(sys.argv) > 1 else 2
# Excluir L1/L8 (ya cargados aparte) — opcional, se vuelven a evaluar igual.
RE_OFFS = re.compile(r"'(\[.*?\])'::jsonb", re.DOTALL)

def mins(t):
    return int(t[:2]) * 60 + int(t[3:5])

def evaluate(sql_path):
    txt = open(sql_path, encoding='utf-8').read()
    trips = RE_OFFS.findall(txt)
    if not trips:
        return None
    back = 0
    trans = 0
    for raw in trips:
        try:
            seq = json.loads(raw)
        except Exception:
            continue
        times = [e['t'] for e in seq if 't' in e]
        for a, b in zip(times, times[1:]):
            trans += 1
            if mins(b) < mins(a):
                back += 1
    return {'exp': len(trips), 'back': back, 'trans': trans}

def main():
    os.makedirs(APPLY, exist_ok=True)
    rows = []
    for sql in sorted(glob.glob(os.path.join(OUT, 'schedules_*.sql'))):
        m = evaluate(sql)
        name = os.path.basename(sql)
        if not m:
            rows.append(f'[SKIP] {name}: sin expediciones')
            continue
        ratio = m['back'] / m['trans'] if m['trans'] else 1.0
        # Fiable si pocos saltos en absoluto (errores OCR puntuales) O un ratio
        # de saltos muy bajo aunque la tabla sea grande (líneas largas con
        # muchas transiciones). Descarta solo los desórdenes estructurales.
        ok = m['exp'] >= 3 and (m['back'] <= MAX_BACK or ratio <= 0.012)
        tag = 'OK  ' if ok else 'SKIP'
        rows.append(f"[{tag}] {name}: exp={m['exp']} saltos={m['back']}/{m['trans']} ({ratio:.1%})")
        if ok:
            shutil.copy(sql, os.path.join(APPLY, name))
    print('\n'.join(rows))
    oks = sum(1 for r in rows if r.startswith('[OK'))
    print(f'\n== {oks}/{len(rows)} fiables (MAX_BACK={MAX_BACK}). En {APPLY}/')

if __name__ == '__main__':
    main()
