import 'package:hive/hive.dart';

import '../../../shared/models/feature_request.dart';
import '../domain/feature_request_repository.dart';

/// Cache local. Convención: `request:<id>`.
class FeatureRequestLocalRepository implements FeatureRequestRepository {
  FeatureRequestLocalRepository(this._box);

  final Box<FeatureRequest> _box;

  static String _key(String id) => 'request:$id';

  @override
  Future<List<FeatureRequest>> list() async =>
      _box.values.toList(growable: false);

  @override
  Future<FeatureRequest?> byId(String id) async => _box.get(_key(id));

  @override
  Future<FeatureRequest> create(FeatureRequest request) async {
    await _box.put(_key(request.id), request);
    return request;
  }

  @override
  Future<int> castVote(String requestId) async {
    final r = _box.get(_key(requestId));
    if (r == null) return 0;
    final updated = r.copyWith(votes: r.votes + 1);
    await _box.put(_key(requestId), updated);
    return updated.votes;
  }

  Future<void> upsert(FeatureRequest r) async {
    await _box.put(_key(r.id), r);
  }

  Future<void> upsertAll(Iterable<FeatureRequest> items) async {
    final entries = <String, FeatureRequest>{
      for (final r in items) _key(r.id): r,
    };
    await _box.putAll(entries);
  }

  Future<void> clear() async => _box.clear();
}
