import 'package:hive/hive.dart';

import '../../../shared/models/enums.dart';
import '../../../shared/models/route_suggestion_model.dart';
import '../domain/route_suggestion_repository.dart';

/// Cache local. Convención: `suggestion:<id>`.
class RouteSuggestionLocalRepository implements RouteSuggestionRepository {
  RouteSuggestionLocalRepository(this._box);

  final Box<RouteSuggestionModel> _box;

  static String _key(String id) => 'suggestion:$id';

  @override
  Future<List<RouteSuggestionModel>> list({int? limit, int? offset}) async =>
      _box.values.toList(growable: false);

  @override
  Future<RouteSuggestionModel?> byId(String id) async => _box.get(_key(id));

  @override
  Future<RouteSuggestionModel> create(
      RouteSuggestionModel suggestion) async {
    await _box.put(_key(suggestion.id), suggestion);
    return suggestion;
  }

  /// Voto optimista: incrementa el `voteCount` en cache. Devuelve el
  /// nuevo total o `null` si la sugerencia no está cacheada.
  @override
  Future<int> castVote(String suggestionId) async {
    final s = _box.get(_key(suggestionId));
    if (s == null) return 0;
    final updated = s.copyWith(voteCount: s.voteCount + 1);
    await _box.put(_key(suggestionId), updated);
    return updated.voteCount;
  }

  Future<void> upsert(RouteSuggestionModel s) async {
    await _box.put(_key(s.id), s);
  }

  Future<void> upsertAll(Iterable<RouteSuggestionModel> items) async {
    final entries = <String, RouteSuggestionModel>{
      for (final s in items) _key(s.id): s,
    };
    await _box.putAll(entries);
  }

  Future<void> clear() async => _box.clear();

  @override
  Future<RouteSuggestionModel> updateStatus(String id, String status) async {
    final s = _box.get(_key(id));
    if (s == null) throw Exception('Suggestion not found: $id');
    final newStatus = SuggestionStatus.fromString(status);
    final updated = s.copyWith(status: newStatus);
    await _box.put(_key(id), updated);
    return updated;
  }
}
