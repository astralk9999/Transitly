import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../core/utils/app_logger.dart';
import 'hive_init.dart';

const _logTag = 'StorageRepo';

class StorageRepository {
  const StorageRepository();

  int fileSize(String boxName) {
    try {
      final box = Hive.box(boxName);
      final path = box.path;
      if (path != null) return File(path).lengthSync();
    } catch (e) {
      AppLogger.warn(_logTag, 'file size unavailable for $boxName', e);
    }
    return 0;
  }

  String? boxPath(String boxName) {
    try {
      final box = Hive.box(boxName);
      return box.path;
    } catch (e) {
      AppLogger.warn(_logTag, 'box path unavailable for $boxName', e);
      return null;
    }
  }
}

final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return const StorageRepository();
});
