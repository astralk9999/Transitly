import '../../../shared/models/route_suggestion_model.dart';
import '../../mock/mock_data_service.dart';
import '../domain/route_suggestion_repository.dart';

class RouteSuggestionMockRepository implements RouteSuggestionRepository {
  RouteSuggestionMockRepository(this._mockData);

  final MockDataService _mockData;
  final List<RouteSuggestionModel> _ephemeralCreates =
      <RouteSuggestionModel>[];
  final Map<String, int> _voteBumps = <String, int>{};

  Iterable<RouteSuggestionModel> get _all =>
      [..._mockData.routeSuggestions, ..._ephemeralCreates];

  @override
  Future<List<RouteSuggestionModel>> list() async {
    return _all.map(_applyVoteBump).toList(growable: false);
  }

  @override
  Future<RouteSuggestionModel?> byId(String id) async {
    final found = _all.where((s) => s.id == id);
    if (found.isEmpty) return null;
    return _applyVoteBump(found.first);
  }

  @override
  Future<RouteSuggestionModel> create(
      RouteSuggestionModel suggestion) async {
    _ephemeralCreates.add(suggestion);
    return suggestion;
  }

  @override
  Future<int> castVote(String suggestionId) async {
    final current = _voteBumps[suggestionId] ?? 0;
    _voteBumps[suggestionId] = current + 1;
    final s = _all.firstWhere(
      (e) => e.id == suggestionId,
      orElse: () => throw StateError('Suggestion not found: $suggestionId'),
    );
    return s.voteCount + _voteBumps[suggestionId]!;
  }

  RouteSuggestionModel _applyVoteBump(RouteSuggestionModel s) {
    final bump = _voteBumps[s.id] ?? 0;
    return bump == 0 ? s : s.copyWith(voteCount: s.voteCount + bump);
  }
}
