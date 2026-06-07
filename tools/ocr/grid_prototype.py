import json, re, sys
from statistics import mean

items = json.load(open('ocr_l1_lab.json', encoding='utf-8'))

def center(box):
    xs = [p[0] for p in box]; ys = [p[1] for p in box]
    return (sum(xs)/4.0, sum(ys)/4.0)

TIME = re.compile(r'^([0-2]?\d)[:.;]([0-5]\d)([a-zA-Z])?$')
toks = []
for it in items:
    t = it['text'].strip().replace(' ', '')
    m = TIME.match(t)
    if not m:
        continue
    cx, cy = center(it['box'])
    hh = int(m.group(1)); mm = int(m.group(2)); suf = (m.group(3) or '').lower()
    if hh > 23:
        continue
    toks.append({'cx': cx, 'cy': cy, 't': f'{hh:02d}:{mm:02d}', 'suf': suf, 'conf': it['conf']})

# Cluster into rows by cy
def cluster(vals, tol):
    vals = sorted(vals)
    groups = [[vals[0]]]
    for v in vals[1:]:
        if v - groups[-1][-1] <= tol:
            groups[-1].append(v)
        else:
            groups.append([v])
    return [mean(g) for g in groups]

row_centers = cluster([t['cy'] for t in toks], tol=18)
col_centers = cluster([t['cx'] for t in toks], tol=22)
print('rows (stop-lines) detected:', len(row_centers))
print('cols (trips) detected:', len(col_centers))

def nearest(v, centers):
    return min(range(len(centers)), key=lambda i: abs(centers[i]-v))

# Build grid: grid[row][col] = time
grid = {}
for t in toks:
    r = nearest(t['cy'], row_centers)
    c = nearest(t['cx'], col_centers)
    grid.setdefault((r, c), []).append(t)

filled = len(grid)
print('cells filled:', filled, 'of', len(row_centers)*len(col_centers))
# Print first 6 rows x first 8 cols as a matrix preview
print('\nMATRIX PREVIEW (row x col):')
for r in range(min(8, len(row_centers))):
    line = []
    for c in range(min(8, len(col_centers))):
        cell = grid.get((r, c))
        if cell:
            best = max(cell, key=lambda x: x['conf'])
            line.append(best['t'] + best['suf'])
        else:
            line.append('  --  ')
    print(f'r{r:02d}: ' + '  '.join(line))
# Report multi-token cells (collisions) and suffix counts
collisions = sum(1 for v in grid.values() if len(v) > 1)
sufs = {}
for t in toks:
    if t['suf']:
        sufs[t['suf']] = sufs.get(t['suf'], 0) + 1
print('\ncells with >1 token (collisions):', collisions)
print('suffix counts:', sufs)
