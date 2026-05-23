# FMTC LRU Cache Configuration

The offline map tile cache is powered by `flutter_map_tile_caching` (FMTC) v10
with the ObjectBox backend. Two tiers of LRU-like eviction protect device
storage.

## Architecture

```
FMTCTileProvider (TileProvider for flutter_map TileLayer)
  └── FMTCStore "transitly" (tile blob files)
        └── FMTCObjectBoxBackend (metadata database)
              └── rootDirectory: {appDir}/fmtc/
```

## Configuration (lib/data/fmtc/fmtc_service.dart)

| Parameter              | Default Value | Description                                       |
|------------------------|---------------|---------------------------------------------------|
| `maxDatabaseSize`      | 50 MB         | ObjectBox database file size cap                  |
| `maxTileCount`         | 50,000 tiles  | Maximum tiles retained in the "transitly" store   |

## Eviction Policy

Two levels of eviction work together:

### 1. ObjectBox backend (metadata LRU)

- **`maxDatabaseSize`** limits the ObjectBox database that stores tile
  metadata (coordinates, URLs, timestamps).
- When the database grows beyond this limit, ObjectBox reclaims space by
  removing the least-recently-accessed records.
- Default: 50 MB (overridden from FMTC's internal 10 MB default).

### 2. Store-level tile limit (count LRU)

- **`maxLength`** limits the number of tiles stored for the "transitly"
  store.
- When exceeded, FMTC internally evicts tiles using last-modified
  timestamps (oldest evicted first), approximating LRU behavior when the
  map is browsed regularly.
- Default: 50,000 tiles. At ~4 KB per 256×256 PNG tile this equals
  approximately 200 MB.
- Checked on startup via `store.manage.maxLength` and updated if the
  configured value differs from the existing store setting.

## Per-Region Configuration

Currently, a single global "transitly" store serves all offline regions.
Per-region isolation is planned for a future phase. To configure per
region when supported:

1. Create a separate `FMTCStore` per region with its own `maxLength`:
   ```dart
   final regionStore = FMTCStore('region_jerez');
   if (!(await regionStore.manage.ready)) {
     await regionStore.manage.create(maxLength: 20000);
   }
   ```

2. Use `FMTCTileProvider.new` with multiple stores or
   `FMTCTileProvider.allStores` to aggregate.

## Initialization Flow

1. `main.dart` → `_initFmtc()` (after Hive bootstrap)
2. `FmtcService.initialise()`:
   - Creates `{appDir}/fmtc/` directory if missing
   - Initialises `FMTCObjectBoxBackend` with `maxDatabaseSize`
   - Creates or updates the "transitly" store with `maxLength`
   - Caches a singleton `FMTCTileProvider` for reuse
3. `map_tab.dart` reads the provider via `fmtcTileProviderProvider`
   and passes it to `TransitMap.fmtcTileProvider`
4. `TransitMap` uses the FMTC provider in its `TileLayer` when set;
   falls back to direct MapTiler URLs when null (guest/error mode)

## Monitoring

- `AppearanceScreen > Storage` (`storage_section.dart`) reads the FMTC
  directory size from `{appDir}/fmtc/store/` and displays it alongside
  Hive and pending action sizes.
- "Clear cache" button deletes the FMTC store and offline regions.

## Tuning Guidelines

| Scenario                       | Recommended `maxTileCount` |
|-------------------------------|---------------------------|
| Jerez urban area (zoom 10–16) | ~10,000 tiles             |
| Full province (zoom 10–16)    | ~30,000 tiles             |
| Multiple cities               | ~50,000 tiles             |

Adjust `maxDatabaseSize` upward if the metadata grows alongside many
disparate regions (each tile has a small metadata record in ObjectBox).

## Dependencies

- `flutter_map_tile_caching: ^10.0.0` (FMTCObjectBoxBackend)
- `path_provider` (for `getApplicationDocumentsDirectory`)
- `objectbox_flutter_libs` (transitive, bundled by FMTC)
