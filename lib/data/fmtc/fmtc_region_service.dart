import 'dart:async';

import 'package:flutter_map/flutter_map.dart' show LatLngBounds, TileLayer;
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../../core/utils/app_logger.dart';
import '../../features/map/map_config.dart';
import 'fmtc_service.dart';

/// Servicio para descargar regiones de tiles reales con FMTC v10.
///
/// La API de v10 separa la región (geográfica) de su forma descargable:
/// `RectangleRegion(bounds).toDownloadable(...)` añade rango de zoom + opciones.
class FmtcRegionService {
  static const _logTag = 'FmtcRegion';

  static Future<Stream<int>> downloadRegion({
    required String style,
    required LatLngBounds bounds,
    required int minZoom,
    required int maxZoom,
  }) async {
    final storeName = FmtcService.storeName(style);
    final store = FMTCStore(storeName);

    final isReady = await store.manage.ready;
    if (!isReady) {
      await store.manage.create();
    }

    final region = RectangleRegion(bounds);
    final downloadable = region.toDownloadable(
      minZoom: minZoom,
      maxZoom: maxZoom,
      options: TileLayer(
        urlTemplate: MapConfig.tileUrl(style),
        subdomains: MapConfig.subdomains,
        userAgentPackageName: 'com.transitly.transitly',
      ),
    );

    AppLogger.info(_logTag,
        'starting download style=$style zoom=$minZoom-$maxZoom');

    final streamCtrl = StreamController<int>();
    var downloaded = 0;

    try {
      // En FMTC v10 startForeground devuelve un record con dos streams:
      // downloadProgress (alto nivel) y tileEvents (cada tile). Usamos
      // tileEvents para contar tiles descargadas.
      final dlResult = store.download.startForeground(region: downloadable);
      dlResult.tileEvents.listen(
        (_) {
          downloaded++;
          if (downloaded % 25 == 0) {
            streamCtrl.add(downloaded);
          }
        },
        onDone: () {
          streamCtrl.add(downloaded);
          AppLogger.info(_logTag,
              'download complete style=$style tiles=$downloaded');
          streamCtrl.close();
        },
        onError: (Object e) {
          AppLogger.warn(_logTag, 'download error', e);
          streamCtrl.addError(e);
          streamCtrl.close();
        },
        cancelOnError: true,
      );
    } catch (e) {
      AppLogger.warn(_logTag, 'download start failed', e);
      streamCtrl.addError(e);
      streamCtrl.close();
    }

    return streamCtrl.stream;
  }

  static Future<void> deleteRegion({required String style}) async {
    final store = FMTCStore(FmtcService.storeName(style));
    final isReady = await store.manage.ready;
    if (isReady) {
      await store.manage.reset();
      AppLogger.info(_logTag, 'region deleted style=$style');
    }
  }
}
