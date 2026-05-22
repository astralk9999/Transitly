# Offline Regions — Transitly

> Map download for offline use · Version: 1.0 · Owner: Platform

## How offline regions work

An offline region bundles two things into a named, manageable unit:

1. **Transit data** — operators, stops, routes, and schedules within a geographic bounding box. Queried from Supabase via the `export_region_data()` RPC and persisted to Hive (`stopsBox`, `routesBox`, `schedulesBox`).
2. **Map tiles** — raster/vector tiles for the same area. Managed by **flutter_map_tile_caching (FMTC)** and stored on-disk under `<appDir>/fmtc/store/`.

The architecture is **local-first**: Hive is the source of truth; Supabase acts as a sync backup between devices. When online, FMTC transparently caches tiles. When offline, cached data and tiles serve the map without a network.

### Data flow

```
User taps "Add Region"
  → RegionDownloadSheet (bottom sheet)
    → Supabase RPC: export_region_data(bounds, zoomMin, zoomMax)
      → Returns JSON { operators, stops, routes, schedules }
    → Parse & upsert into Hive boxes (StopLocalRepository, RouteLocalRepository, ScheduleLocalRepository)
    → FMTC downloads tiles for the same bbox + zoom range
    → OfflineRegion saved to Hive + Supabase (sync)
```

### Status lifecycle

| Status | Meaning |
|--------|---------|
| `downloading` | Download in progress; progress bar shown |
| `ready` | Data and tiles cached; region is fully offline-capable |
| `stale` | Data has not been synced recently; grace period expired |
| `error` | Download or sync failed; user can retry |

Status is displayed via colored badges in `_RegionCard` (`offline_regions_screen.dart` line 214).

## Bounding box format

Regions are defined by a rectangular bounding box:

```dart
@freezed
class OfflineRegionBounds {
  double northLat;  // Northernmost latitude  (e.g. 36.70)
  double southLat;  // Southernmost latitude  (e.g. 36.67)
  double eastLng;   // Easternmost longitude  (e.g. -6.10)
  double westLng;   // Westernmost longitude  (e.g. -6.15)
}
```

### Coordinate conventions

- Latitude/longitude in **WGS84 (EPSG:4326)**.
- `northLat > southLat`, `eastLng > westLng` (standard bbox ordering).
- Current hardcoded default: Jerez de la Frontera area (`36.67–36.70N, 6.10–6.15W`). The `_AreaSelectorPreview` widget in `region_download_sheet.dart` displays a placeholder with plans for an interactive map selector in a future iteration.

### PostGIS serialization

In the `offline_regions` database table, bounds are stored as a PostGIS `geometry(POLYGON, 4326)` column. The remote repository serializes the bbox using WKT:

```sql
SRID=4326;POLYGON((
  westLng southLat,
  eastLng southLat,
  eastLng northLat,
  westLng northLat,
  westLng southLat
))
```

The `export_region_data()` RPC constructs this polygon into a `v_bbox` using `ST_MakeEnvelope()` and filters with `ST_Within()` / `ST_Intersects()`.

## The export_region_data() RPC

Defined in `supabase/migrations/013_offline_export.sql`:

```sql
SELECT * FROM export_region_data(
  p_north  => 36.70,   -- north latitude
  p_south  => 36.67,   -- south latitude
  p_east   => -6.10,   -- east longitude
  p_west   => -6.15,   -- west longitude
  p_zoom_min => 12,    -- minimum zoom level
  p_zoom_max => 16     -- maximum zoom level
);
```

Returns a `jsonb` object with four arrays:
- `operators` — operators whose bbox intersects the region
- `stops` — stops within the region, filtered by operator
- `routes` — routes whose geometry intersects the region
- `schedules` — schedules for the matching routes

Runs as `SECURITY INVOKER` and respects RLS. `p_zoom_min` and `p_zoom_max` are passed through for FMTC tile configuration but the RPC does not filter data by zoom.

## Integration with flutter_map_tile_caching (FMTC)

### Dependency

```
flutter_map: ^7.0.2
flutter_map_tile_caching: ^10.0.0
```

### Architecture

FMTC stores map tiles on the device filesystem under:

```
<appDir>/fmtc/store/
```

The tile cache acts as a **transparent proxy**:
- **Online**: FMTC fetches from MapTiler URLs, writes to cache, serves from cache on subsequent requests.
- **Offline**: FMTC serves exclusively from cache. Tiles not cached show a placeholder or empty grid.

### Storage location and management

The `storage_section.dart` widget (`lib/features/appearance/widgets/storage_section.dart`) exposes FMTC storage to users:
- **Reads** size from `fmtc/store/` directory via `_directorySize()`.
- **Clears** cache by deleting the `fmtc/store/` directory recursively.
- Displayed in Appearance → Storage as "FMTC maps" alongside Hive data.

### TransitMap integration

`TransitMap` (`lib/features/map/transit_map.dart` line 72) accepts an optional `fmtcTileProvider` of type `TileProvider?`:
- When `null`: tiles fetched directly from MapTiler (online-only).
- When set: provider serves cached tiles when offline; transparent cache when online.
- This provider is wired during the F20 region download flow.

## Storage requirements per region

### Tile storage estimation

The download sheet estimates storage using the formula:

```
estimatedTileCount = Σ(4^z) for z in [zoomMin, zoomMax]
estimatedBytes     = estimatedTileCount × 15,000
```

| Zoom range | Tiles (cumulative) | Estimated size |
|-----------|-------------------:|:--------------:|
| 12–12 | 16,777,216 | ~240 MB |
| 12–13 | 88,080,384 | ~1.26 GB |
| 12–14 | 375,809,638 | ~5.25 GB |
| 12–15 | 1,543,045,126 | ~21.6 GB |
| 12–16 | 6,225,268,742 | ~87.0 GB |
| 8–18   | ~1.37 × 10¹¹ | ~1.91 TB |

**Practical notes**:
- These are **global** tile counts. Bounding-box filtering reduces the actual download to tiles that intersect the region.
- Average tile size of 15 KB is conservative; real tiles average 8–25 KB depending on map style and area complexity.
- The download sheet shows estimated size at the bottom of the form (`region_download_sheet.dart` line 414).
- The estimator uses `const avgTileBytes = 15000;` (line 54). This is a rough ceiling; actual sizes are smaller for empty tiles (ocean, rural).

### Data storage (Hive)

Transit data (JSON from `export_region_data`) is stored in three Hive boxes:
- `stopsBox` — `StopModel` entries
- `routesBox` — `RouteModel` entries
- `schedulesBox` — `ScheduleModel` entries

Typical size for a single urban region (e.g., Jerez de la Frontera): **50–500 KB**.

### Total per region

A typical city-scale offline region (zoom 12–14, bounded to city limits) consumes:

| Component | Size |
|-----------|------|
| Transit data (Hive) | ~200 KB |
| FMTC tiles (filtered) | ~15–50 MB |
| Region metadata | ~1 KB |
| **Total** | **~15–50 MB** |

## Data model

```dart
@freezed
class OfflineRegion {
  String id;                  // UUID, e.g. `region-1715892000000`
  String label;               // User-given name
  OfflineRegionBounds bounds;  // Geographic bounding box
  int zoomMin;                // 8–15 (min zoom for tiles)
  int zoomMax;                // 10–18 (max zoom for tiles)
  DateTime downloadedAt;      // Timestamp of last download
  int sizeBytes;              // Total size in bytes (tiles + data)
  OfflineRegionStatus status; // Lifecycle state
  DateTime? dataSyncedAt;     // Last data sync timestamp
}
```

Hive key format: `region:<userId>:<regionId>` (`offline_region_local_repository.dart` line 15).

## Repository pattern

Five-file pattern in `lib/data/offline_region/`:

| File | Role |
|------|------|
| `domain/offline_region_repository.dart` | Abstract interface (`forUser`, `add`, `delete`) |
| `local/offline_region_local_repository.dart` | Hive cache — source of truth |
| `remote/offline_region_remote_repository.dart` | Supabase sync backup |
| `local/offline_region_mock_repository.dart` | Guest mode (empty list) |
| `offline_region_repository_provider.dart` | Riverpod provider, local-first composite |

The provider selects mock when `currentSession == null`. Otherwise it composes `OfflineRegionRepositoryLocalFirst` which reads from Hive and syncs to Supabase in the background (`unawaited(_pushToRemote(...))`).

## UI screens

| File | Description |
|------|-------------|
| `lib/features/offline/offline_regions_screen.dart` | List of downloaded regions with status, size, zoom range, and delete |
| `lib/features/offline/widgets/region_download_sheet.dart` | Bottom sheet: name input, bbox preview, zoom sliders, size estimate, download button |
| `lib/features/appearance/widgets/storage_section.dart` | Storage dashboard: Hive size, FMTC size, clear cache |

## Related documents

- `supabase/migrations/013_offline_export.sql` — `export_region_data()` RPC
- `supabase/migrations/001_init.sql` — `offline_regions` table definition
- `supabase/migrations/002_rls.sql` — RLS policies (line 119, 615–620)
- `lib/shared/models/offline_region.dart` — freezed model
- `lib/features/map/transit_map.dart` — map widget with FMTC tile provider support
- `pubspec.yaml` — `flutter_map: ^7.0.2`, `flutter_map_tile_caching: ^10.0.0`
