import 'dart:async';

import 'package:flutter_map/flutter_map.dart' show LatLngBounds, TileLayer;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../../core/utils/app_logger.dart';
import '../../core/map/map_config.dart';
import 'fmtc_service.dart';

class TilePrewarmer {
  TilePrewarmer._();

  static const _logTag = 'TilePrewarmer';

  /// Si el store ya tiene >= este número de tiles, asumimos que un
  /// arranque previo hidrató la zona de Jerez y se hace skip del
  /// prewarming. Evita descargar tiles innecesariamente en cada boot.
  static const _minTilesToConsiderWarm = 50;

  static Future<void> prewarmOnce() async {
    try {
      const style = 'streets';
      final storeName = FmtcService.storeName(style);
      final store = FMTCStore(storeName);

      final isReady = await store.manage.ready;
      if (!isReady) {
        await store.manage.create();
      }

      // Idempotencia: si el store ya tiene tiles cacheadas de un
      // arranque previo, no volvemos a descargar nada.
      try {
        final stats = await store.stats.all;
        final tileCount = stats.length;
        if (tileCount >= _minTilesToConsiderWarm) {
          AppLogger.info(
              _logTag, 'skip prewarm: store has $tileCount tiles');
          return;
        }
      } catch (e) {
        AppLogger.warn(
            _logTag, 'stats check failed, will attempt prewarm anyway', e);
      }

      AppLogger.info(_logTag, 'prewarming Jerez (zoom 13-15)');

      final region = RectangleRegion(LatLngBounds(
        LatLng(36.6500, -6.1700),
        LatLng(36.7100, -6.0700),
      ));

      final downloadable = region.toDownloadable(
        minZoom: 13,
        maxZoom: 15,
        options: TileLayer(
          urlTemplate: MapConfig.tileUrl(style),
          userAgentPackageName: 'com.transitly.transitly',
        ),
      );

      final dlResult = store.download.startForeground(region: downloadable);
      var done = 0;
      dlResult.tileEvents.listen(
        (_) => done++,
        onDone: () =>
            AppLogger.info(_logTag, 'prewarm done: $done tiles'),
        onError: (e) =>
            AppLogger.warn(_logTag, 'prewarm error', e),
      );
    } catch (e, st) {
      AppLogger.warn(_logTag, 'prewarm failed (non-blocking): $e', st);
    }
  }
}
