import '../../../shared/models/offline_region.dart';
import '../domain/offline_region_repository.dart';

/// Mock repo para modo invitado. Las regiones offline requieren cuenta
/// real (F20). En modo invitado, devolvemos lista vacía.
class OfflineRegionMockRepository implements OfflineRegionRepository {
  final List<OfflineRegion> _ephemeral = <OfflineRegion>[];

  @override
  Future<List<OfflineRegion>> forUser(String userId) async =>
      _ephemeral.toList(growable: false);

  @override
  Future<OfflineRegion> add(OfflineRegion region) async {
    _ephemeral.add(region);
    return region;
  }

  @override
  Future<void> delete(String regionId) async {
    _ephemeral.removeWhere((r) => r.id == regionId);
  }
}
