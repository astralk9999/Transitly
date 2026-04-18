#!/usr/bin/env node
/**
 * Simplifies polylines in comujesa_data.json using Ramer-Douglas-Peucker.
 * Reduces thousands of points to hundreds while preserving road shape.
 */

const fs = require('fs');
const path = require('path');

const DATA_FILE = path.join(__dirname, '..', 'assets', 'mock', 'comujesa_data.json');
const TOLERANCE = 0.00008; // ~9m — higher detail for bus route curves

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
  let totalBefore = 0;
  let totalAfter = 0;

  for (const line of data.lines) {
    if (!line.polyline || !line.polyline.coordinates) continue;
    const before = line.polyline.coordinates.length;
    totalBefore += before;

    const simplified = douglasPeucker(line.polyline.coordinates, TOLERANCE);
    line.polyline.coordinates = simplified;
    totalAfter += simplified.length;

    console.log(`${line.code}: ${before} -> ${simplified.length} points (${Math.round(simplified.length/before*100)}%)`);
  }

  console.log(`\nTotal: ${totalBefore} -> ${totalAfter} points (${Math.round(totalAfter/totalBefore*100)}%)`);
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('Done!');
}

main();
