#!/usr/bin/env node
/**
 * Generates road-following polylines for each bus route using OSRM public API.
 * Usage: node scripts/generate_polylines.js
 */

const fs = require('fs');
const path = require('path');
const https = require('https');

const DATA_FILE = path.join(__dirname, '..', 'assets', 'mock', 'comujesa_data.json');

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    https.get(url, { headers: { 'User-Agent': 'TransitlyApp/1.0' } }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode !== 200) {
          reject(new Error(`HTTP ${res.statusCode}`));
          return;
        }
        try { resolve(JSON.parse(data)); }
        catch (e) { reject(e); }
      });
    }).on('error', reject);
  });
}

function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function getRouteGeometry(stops) {
  const coords = stops.map(s => `${s.lng},${s.lat}`).join(';');
  const url = `https://router.project-osrm.org/route/v1/driving/${coords}?overview=full&geometries=geojson`;

  const result = await httpsGet(url);
  if (result.code === 'Ok' && result.routes && result.routes.length > 0) {
    return result.routes[0].geometry.coordinates;
  }
  return null;
}

async function main() {
  console.log('Reading data file...');
  const data = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
  const lines = data.lines;

  let updated = 0;

  for (const line of lines) {
    const stops = line.stops;
    if (!stops || stops.length < 2) {
      console.log(`${line.code}: skipped (< 2 stops)`);
      continue;
    }

    // Sort by order
    const ordered = [...stops]
      .filter(s => s.lat && s.lng)
      .sort((a, b) => a.order - b.order);

    if (ordered.length < 2) {
      console.log(`${line.code}: skipped (< 2 geocoded stops)`);
      continue;
    }

    console.log(`${line.code}: querying OSRM (${ordered.length} stops)...`);

    try {
      const geometry = await getRouteGeometry(ordered);
      if (geometry && geometry.length > 0) {
        line.polyline = {
          type: 'LineString',
          coordinates: geometry.map(c => [
            Math.round(c[0] * 10000000) / 10000000,
            Math.round(c[1] * 10000000) / 10000000,
          ]),
        };
        console.log(`  -> ${geometry.length} points`);
        updated++;
      } else {
        console.log(`  -> no result, keeping existing`);
      }
    } catch (err) {
      console.log(`  -> error: ${err.message}, keeping existing`);
    }

    // Rate limit for OSRM public API
    await sleep(1100);
  }

  console.log(`\nWriting ${updated} updated polylines...`);
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log('Done!');
}

main().catch(console.error);
