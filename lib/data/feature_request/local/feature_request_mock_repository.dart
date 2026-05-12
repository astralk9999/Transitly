import '../../../shared/models/feature_request.dart';
import '../../mock/mock_data_service.dart';
import '../domain/feature_request_repository.dart';

/// Mock repo para modo invitado. `MockDataService` no expone aún una
/// colección de feature requests (no estaban en el JSON v1), así que
/// el storage es 100% efímero — la lista vive solo durante esta
/// instancia del repo.
class FeatureRequestMockRepository implements FeatureRequestRepository {
  FeatureRequestMockRepository(this._mockData);

  // ignore: unused_field
  final MockDataService _mockData;

  final List<FeatureRequest> _ephemeral = <FeatureRequest>[];
  final Map<String, int> _voteBumps = <String, int>{};

  @override
  Future<List<FeatureRequest>> list() async =>
      _ephemeral.map(_applyBump).toList(growable: false);

  @override
  Future<FeatureRequest?> byId(String id) async {
    final found = _ephemeral.where((r) => r.id == id);
    if (found.isEmpty) return null;
    return _applyBump(found.first);
  }

  @override
  Future<FeatureRequest> create(FeatureRequest request) async {
    _ephemeral.add(request);
    return request;
  }

  @override
  Future<int> castVote(String requestId) async {
    final current = _voteBumps[requestId] ?? 0;
    _voteBumps[requestId] = current + 1;
    final r = _ephemeral.firstWhere(
      (e) => e.id == requestId,
      orElse: () =>
          throw StateError('Feature request not found: $requestId'),
    );
    return r.votes + _voteBumps[requestId]!;
  }

  FeatureRequest _applyBump(FeatureRequest r) {
    final bump = _voteBumps[r.id] ?? 0;
    return bump == 0 ? r : r.copyWith(votes: r.votes + bump);
  }
}
