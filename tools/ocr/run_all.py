#!/usr/bin/env python3
"""Orquesta la extracción de horarios de varias líneas/días con gate de calidad.

Para cada (linea, dia) ejecuta extract_line.py como subproceso, parsea sus
métricas y decide si el resultado es FIABLE:
  - ratio casadas/filas >= 0.60
  - 0 saltos hacia atrás (monotonía perfecta)
  - >= 3 expediciones
Los SQL fiables se copian a out/apply/; el resto se reporta como DUDOSO para
revisión manual. No aplica nada a la BD (eso se hace después con apply_sql.mjs).

Uso: python tools/ocr/run_all.py L2 L3 ... [--days LAB,SAB,FES]
"""
import os, re, shutil, subprocess, sys

OUT = 'tools/ocr/out'
APPLY = os.path.join(OUT, 'apply')
RE_HEAD = re.compile(r'filas=(\d+) casadas=(\d+) sin_casar=(\d+) bloques=(\d+) columnas=(\d+) expediciones=(\d+)')
RE_MONO = re.compile(r'monotonia: (\d+) saltos')

def run(code, day):
    p = subprocess.run([sys.executable, 'tools/ocr/extract_line.py', code, day, OUT],
                       capture_output=True, text=True)
    out = (p.stdout or '') + (p.stderr or '')
    head = RE_HEAD.search(out)
    mono = RE_MONO.search(out)
    if not head:
        return {'code': code, 'day': day, 'ok': False, 'reason': 'sin datos OCR',
                'metrics': None}
    filas, casadas, sin_casar, bloques, columnas, exp = map(int, head.groups())
    back = int(mono.group(1)) if mono else -1
    ratio = casadas / filas if filas else 0
    ok = ratio >= 0.60 and back == 0 and exp >= 3
    reason = []
    if ratio < 0.60: reason.append(f'casado {ratio:.0%}')
    if back != 0: reason.append(f'{back} saltos')
    if exp < 3: reason.append(f'{exp} exp')
    return {'code': code, 'day': day, 'ok': ok,
            'reason': ', '.join(reason) or 'OK',
            'metrics': dict(filas=filas, casadas=casadas, exp=exp, back=back, ratio=ratio)}

def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    days = ['LAB', 'SAB', 'FES']
    for a in sys.argv[1:]:
        if a.startswith('--days'):
            days = a.split('=', 1)[1].split(',')
    os.makedirs(APPLY, exist_ok=True)
    report = []
    for code in args:
        for day in days:
            r = run(code, day)
            status = 'OK  ' if r['ok'] else 'SKIP'
            m = r['metrics']
            line = (f"[{status}] {code:7} {day}  {r['reason']}"
                    + (f"  (filas={m['filas']} cas={m['casadas']} exp={m['exp']})" if m else ''))
            print(line, flush=True)
            report.append(line)
            if r['ok']:
                src = os.path.join(OUT, f'schedules_{code}_{day}.sql')
                if os.path.exists(src):
                    shutil.copy(src, os.path.join(APPLY, f'schedules_{code}_{day}.sql'))
    open(os.path.join(OUT, 'run_all_report.txt'), 'w', encoding='utf-8').write('\n'.join(report) + '\n')
    oks = sum(1 for l in report if l.startswith('[OK'))
    print(f'\n== {oks}/{len(report)} fiables. SQL en {APPLY}. Reporte: {OUT}/run_all_report.txt')

if __name__ == '__main__':
    main()
