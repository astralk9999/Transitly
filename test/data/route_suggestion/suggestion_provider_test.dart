import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/route_suggestion/domain/route_suggestion_repository.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_suggestion_model.dart';

void main() {
  group('RouteSuggestionModel', () {
    test('fromJson parses minimal fields', () {
      final json = <String, dynamic>{
        'id': 'rs-1',
        'proposedBy': 'user-1',
        'title': 'Centro - Norte',
        'status': 'idea',
        'votes': 3,
        'contributions': 0,
        'proposedAt': '2026-05-01T12:00:00.000Z',
      };
      final model = RouteSuggestionModel.fromJson(json);
      expect(model.id, 'rs-1');
      expect(model.originText, 'Centro');
      expect(model.destinationText, 'Norte');
      expect(model.status, SuggestionStatus.idea);
      expect(model.voteCount, 3);
    });

    test('toJson serializes all fields', () {
      final model = RouteSuggestionModel(
        id: 'rs-2',
        suggestedBy: 'u2',
        originText: 'A',
        destinationText: 'B',
        routeCode: 'L1',
        serviceType: ServiceType.urban,
        status: SuggestionStatus.inReview,
        voteCount: 5,
        priority: Priority.high,
        createdAt: DateTime.utc(2026, 5, 1),
      );
      final json = model.toJson();
      expect(json['id'], 'rs-2');
      expect(json['title'], 'A - B');
      expect(json['status'], 'inReview');
      expect(json['votes'], 5);
      expect(json['priority'], 'high');
      expect(json['routeCode'], 'L1');
      expect(json['serviceType'], 'urban');
    });

    test('RouteSuggestionRepositoryError enum has all 6 cases', () {
      expect(RouteSuggestionRepositoryError.values.length, 6);
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.notFound));
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.network));
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.parse));
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.denied));
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.validation));
      expect(RouteSuggestionRepositoryError.values,
          contains(RouteSuggestionRepositoryError.unknown));
    });
  });
}
