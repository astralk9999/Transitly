#!/usr/bin/env node
/**
 * Generates Level-of-Detail (LOD) polylines for each route.
 * 5 levels for smooth zoom-dependent quality scaling:
 *   - lod0: ultra-coarse (~5-12 pts)  for zoom < 12
 *   - lod1: coarse       (~15-30 pts) for zoom 12-13
 *   - lod2: medium       (~40-70 pts) for zoom 13-14.5
 *   - lod3: detailed     (~80-150 pts) for zoom 14.5-16
 *   - lod4: full detail  (all points)  for zoom > 16
 */

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '..', 'assets', 'mock', 'comujesa_data.json');

const LOD_TOLERANCES = {
  lod0: 0.003,    // ~330m — barely recognizable shape, just start/end/major turns
  lod1: 0.0012,   // ~130m — general corridor visible
  lod2: 0.0005,   // ~55m  — curves start to appear
  lod3: 0.00015,  // ~17m  — road-level detail
  // lod4 = original points, no simplification
};

function perpendicularDistance(point, lineStart, lineEnd) {
  const dx = lineEnd[0] - lineStart[0];
  const dy = lineEnd[1] - lineStart[1];
  const lenSq = dx * dx + dy * dy;
  if (lenSq === 0) {
    const ex = point[0] - lineStart[0];
    const ey = point[1] - lineStart[1];
    return Math.sqrt(ex * ex + ey * ey);
  }
  let t = ((point[0] - lineStart[0]) * dx + (point[1] - lineStart[1]) * dy) / lenSq;
  t = Math.max(0, Math.min(1, t));
  const projX = lineStart[0] + t * dx;
  const projY = lineStart[1] + t * dy;
  const ex = point[0] - projX;
  const ey = point[1] - projY;
  return Math.sqrt(ex * ex + ey * ey);
}

function douglasPeucker(points, tolerance) {
  if (points.length <= 2) return points;

  let maxDist = 0;
  let maxIdx = 0;
  const end = points.length - 1;

  for (let i = 1; i < end; i++) {
    const d = perpendicularDistance(points[i], points[0], points[end]);
    if (d > maxDist) {
      maxDist = d;
      maxIdx = i;
    }
  }

  if (maxDist > tolerance) {
    const left = douglasPeucker(points.slice(0, maxIdx + 1), tolerance);
    const right = douglasPeucker(points.slice(maxIdx), tolerance);
    return left.slice(0, -1).concat(right);
  }

  return [points[0], points[end]];
}

function main() {
  const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  const totals = { lod0: 0, lod1: 0, lod2: 0, lod3: 0, lod4: 0 };

  for (const line of data.lines) {
    if (!line.polyline) continue;

    // Get original coordinates (handle both old flat format and already-LOD format)
    let original;
    const coords = line.polyline.coordinates;
    if (Array.isArray(coords)) {
      original = coords;
    } else if (coords) {
      // Pick highest LOD available from previous run
      original = coords.lod4 || coords.lod3 || coords.lod2 || coords.lod1 || coords.lod0;
    }

    if (!original || original.length < 2) continue;

    const lod0 = douglasPeucker(original, LOD_TOLERANCES.lod0);
    const lod1 = douglasPeucker(original, LOD_TOLERANCES.lod1);
    const lod2 = douglasPeucker(original, LOD_TOLERANCES.lod2);
    const lod3 = douglasPeucker(original, LOD_TOLERANCES.lod3);
    const lod4 = original;

    totals.lod0 += lod0.length;
    totals.lod1 += lod1.length;
    totals.lod2 += lod2.length;
    totals.lod3 += lod3.length;
    totals.lod4 += lod4.length;

    console.log(`${line.code.padEnd(6)} lod0=${String(lod0.length).padStart(3)} lod1=${String(lod1.length).padStart(3)} lod2=${String(lod2.length).padStart(3)} lod3=${String(lod3.length).padStart(3)} lod4=${String(lod4.length).padStart(3)}`);

    line.polyline.coordinates = { lod0, lod1, lod2, lod3, lod4 };
  }

  console.log(`\nTotals: lod0=${totals.lod0} lod1=${totals.lod1} lod2=${totals.lod2} lod3=${totals.lod3} lod4=${totals.lod4}`);
  console.log(`Ratio vs full: lod0=${(totals.lod0/totals.lod4*100).toFixed(1)}% lod1=${(totals.lod1/totals.lod4*100).toFixed(1)}% lod2=${(totals.lod2/totals.lod4*100).toFixed(1)}% lod3=${(totals.lod3/totals.lod4*100).toFixed(1)}%`);
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('Done!');
}

main();
