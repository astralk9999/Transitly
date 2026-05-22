import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_logger.dart';
import 'fmtc_service.dart';

final fmtcTileProviderProvider = Provider<FMTCTileProvider?>(
  (ref) {
    final tp = FmtcService.tileProvider;
    if (tp == null) {
      AppLogger.warn('FmtcProvider', 'tileProvider requested but FMTC not initialised yet');
    }
    return tp;
  },
);
