import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/utils/app_logger.dart';

class FmtcServiceException implements Exception {
  const FmtcServiceException(this.message);
  final String message;

  @override
  String toString() => 'FmtcServiceException: $message';
}

class FmtcService {
  FmtcService._();

  static const _logTag = 'Fmtc';
  static const _storePrefix = 'transitly';

  static const _styleKeys = [
    'streets',
    'basic',
    'bright',
    'dark',
    'light',
  ];

  static const databaseSizeDefault = 50 * 1024 * 1024;
  static const maxTileCountDefault = 50000;

  static String storeName(String style) => '$_storePrefix-$style';

  static FMTCStore storeFor(String style) => FMTCStore(storeName(style));

  static FMTCTileProvider? _cachedTileProvider;

  static Future<void> initialise({
    int maxDatabaseSize = databaseSizeDefault,
    int maxTileCount = maxTileCountDefault,
  }) async {
    if (_cachedTileProvider != null) {
      AppLogger.info(_logTag,
          'already initialised, skipping (maxDatabaseSize=$maxDatabaseSize, maxTileCount=$maxTileCount)');
      return;
    }

    final appDir = await getApplicationDocumentsDirectory();
    final fmtcDir =
        Directory('${appDir.path}${Platform.pathSeparator}fmtc');

    if (!fmtcDir.existsSync()) {
      fmtcDir.createSync(recursive: true);
    }

    final backend = FMTCObjectBoxBackend();
    try {
      await backend.initialise(
        rootDirectory: fmtcDir.path,
        maxDatabaseSize: maxDatabaseSize,
      );
      AppLogger.info(_logTag,
          'backend initialised (root=${fmtcDir.path}, maxDatabaseSize=$maxDatabaseSize)');
    } catch (e, st) {
      AppLogger.error(_logTag, 'backend initialise failed', e, st);
      rethrow;
    }

    for (final style in _styleKeys) {
      final store = storeFor(style);
      final isReady = await store.manage.ready;
      if (!isReady) {
        await store.manage.create(maxLength: maxTileCount);
        AppLogger.info(_logTag,
            'store created (name=${storeName(style)}, maxLength=$maxTileCount)');
      }
    }

    final stores = <String, BrowseStoreStrategy>{
      for (final s in _styleKeys) storeName(s): BrowseStoreStrategy.readUpdateCreate,
    };

    final tileProvider = FMTCTileProvider(
      stores: stores,
      loadingStrategy: BrowseLoadingStrategy.cacheFirst,
    );

    _cachedTileProvider = tileProvider;
    AppLogger.info(_logTag, 'tile provider ready (${_styleKeys.length} stores)');
  }

  static FMTCTileProvider? get tileProvider => _cachedTileProvider;

  static Future<int> get tileCount async {
    if (_cachedTileProvider == null) return 0;
    try {
      int total = 0;
      for (final s in _styleKeys) {
        final store = storeFor(s);
        final stats = await store.stats.length;
        total += stats;
      }
      return total;
    } catch (e) {
      AppLogger.warn(_logTag, 'failed to get tile count', e);
      return 0;
    }
  }

  static Future<void> deleteStore() async {
    try {
      for (final s in _styleKeys) {
        final store = storeFor(s);
        final isReady = await store.manage.ready;
        if (isReady) {
          await store.manage.delete();
          AppLogger.info(_logTag, 'store deleted (name=${storeName(s)})');
        }
      }
      _cachedTileProvider = null;
    } catch (e) {
      AppLogger.warn(_logTag, 'store delete failed', e);
    }
  }

  @visibleForTesting
  static void reset() {
    _cachedTileProvider = null;
  }
}
