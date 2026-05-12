import 'package:hive/hive.dart';

import '../../../shared/models/offline_region.dart';
import '../domain/offline_region_repository.dart';

/// Cache local primaria para regiones offline. La fuente de verdad
/// es Hive; Supabase solo sincroniza entre dispositivos.
///
/// Convención de clave: `region:<userId>:<regionId>`.
class OfflineRegionLocalRepository implements OfflineRegionRepository {
  OfflineRegionLocalRepository(this._box);

  final Box<OfflineRegion> _box;

  static String _key(String userId, String regionId) =>
      'region:$userId:$regionId';

  @override
  Future<List<OfflineRegion>> forUser(String userId) async {
    final prefix = 'region:$userId:';
    final result = <OfflineRegion>[];
    for (final entry in _box.toMap().entries) {
      if ((entry.key as String).startsWith(prefix)) {
        result.add(entry.value);
      }
    }
    return result;
  }

  @override
  Future<OfflineRegion> add(OfflineRegion region) async {
    await _box.put(_key(_extractUserId(region), region.id), region);
    return region;
  }

  @override
  Future<void> delete(String regionId) async {
    for (final key in _box.keys.toList()) {
      if ((key as String).endsWith(':$regionId')) {
        await _box.delete(key);
        return;
      }
    }
  }

  Future<void> upsertAll(Iterable<OfflineRegion> regions) async {
    final entries = <String, OfflineRegion>{};
    for (final r in regions) {
      entries[_key(_extractUserId(r), r.id)] = r;
    }
    await _box.putAll(entries);
  }

  Future<void> deleteByUserId(String userId) async {
    final prefix = 'region:$userId:';
    final keysToDelete = <dynamic>[];
    for (final key in _box.keys) {
      if ((key as String).startsWith(prefix)) {
        keysToDelete.add(key);
      }
    }
    await _box.deleteAll(keysToDelete);
  }

  /// Extrae el userId de la clave de una región ya almacenada.
  /// Para regiones nuevas, el caller debe pasar el userId explícito
  /// en el método [add].
  String _extractUserId(OfflineRegion region) {
    for (final entry in _box.toMap().entries) {
      if (entry.value.id == region.id) {
        final key = entry.key as String;
        final parts = key.split(':');
        if (parts.length >= 2) return parts[1];
      }
    }
    return 'unknown';
  }
}
