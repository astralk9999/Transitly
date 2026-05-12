import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/app_logger.dart';
import '../../../shared/models/offline_region.dart';
import '../domain/offline_region_repository.dart';

/// Implementación remota para sincronizar regiones offline entre
/// dispositivos del mismo usuario. Patrón local-first: la cache Hive
/// manda; este repo es solo copia de respaldo.
class OfflineRegionRemoteRepository implements OfflineRegionRepository {
  OfflineRegionRemoteRepository({required SupabaseClient client})
      : _client = client;

  final SupabaseClient _client;

  static const _logTag = 'Repo:OfflineRegion:Remote';

  @override
  Future<List<OfflineRegion>> forUser(String userId) async {
    try {
      final rows = await _client
          .from('offline_regions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return rows.map(_fromRow).toList();
    } catch (e) {
      AppLogger.warn(_logTag, 'forUser failed', e);
      return <OfflineRegion>[];
    }
  }

  @override
  Future<OfflineRegion> add(OfflineRegion region) async {
    final payload = _toDbRow(region);
    try {
      await _client.from('offline_regions').upsert(payload);
      return region;
    } catch (e) {
      AppLogger.warn(_logTag, 'add failed, local still has it', e);
      return region;
    }
  }

  @override
  Future<void> delete(String regionId) async {
    try {
      await _client.from('offline_regions').delete().eq('id', regionId);
    } catch (e) {
      AppLogger.warn(_logTag, 'delete failed, local still has it', e);
    }
  }

  OfflineRegion _fromRow(Map<String, dynamic> row) {
    return OfflineRegion(
      id: row['id'] as String,
      label: row['label'] as String,
      bounds: _parseBounds(row['bounds']),
      zoomMin: row['zoom_min'] as int? ?? 12,
      zoomMax: row['zoom_max'] as int? ?? 16,
      downloadedAt: row['downloaded_at'] != null
          ? DateTime.parse(row['downloaded_at'] as String)
          : DateTime.now(),
      sizeBytes: row['size_bytes'] as int? ?? 0,
      status: _parseStatus(row['status'] as String?),
    );
  }

  Map<String, dynamic> _toDbRow(OfflineRegion r) {
    return <String, dynamic>{
      'id': r.id,
      'label': r.label,
      'bounds': _serializeBounds(r.bounds),
      'zoom_min': r.zoomMin,
      'zoom_max': r.zoomMax,
      'size_bytes': r.sizeBytes,
      'status': r.status.name,
      'downloaded_at': r.downloadedAt.toIso8601String(),
    };
  }

  /// Serializa [OfflineRegionBounds] a WKT POLYGON para PostGIS.
  /// Formato: POLYGON((westLng southLat, eastLng southLat, eastLng northLat, westLng northLat, westLng southLat))
  String _serializeBounds(OfflineRegionBounds b) {
    return 'SRID=4326;POLYGON(('
        '${b.westLng} ${b.southLat},'
        '${b.eastLng} ${b.southLat},'
        '${b.eastLng} ${b.northLat},'
        '${b.westLng} ${b.northLat},'
        '${b.westLng} ${b.southLat}))';
  }

  OfflineRegionBounds _parseBounds(dynamic geom) {
    if (geom == null) {
      return const OfflineRegionBounds(
        northLat: 0, southLat: 0, eastLng: 0, westLng: 0,
      );
    }
    if (geom is Map) {
      return OfflineRegionBounds(
        northLat: (geom['northLat'] as num?)?.toDouble() ?? 0,
        southLat: (geom['southLat'] as num?)?.toDouble() ?? 0,
        eastLng: (geom['eastLng'] as num?)?.toDouble() ?? 0,
        westLng: (geom['westLng'] as num?)?.toDouble() ?? 0,
      );
    }
    return const OfflineRegionBounds(
      northLat: 0, southLat: 0, eastLng: 0, westLng: 0,
    );
  }

  OfflineRegionStatus _parseStatus(String? value) {
    if (value == null) return OfflineRegionStatus.ready;
    return OfflineRegionStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => OfflineRegionStatus.ready,
    );
  }
}
