import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/enums.dart';
import 'package:transitly/shared/models/route_suggestion_model.dart';

void main() {
  final now = DateTime(2026, 5, 23);

  group('RouteSuggestionModel', () {
    test('fromJson creates model with title-based parsing', () {
      final json = <String, dynamic>{
        'id': 'rs1',
        'proposedBy': 'user1',
        'title': 'Station A - Station B',
        'status': 'idea',
        'votes': 3,
        'contributions': 1,
        'proposedAt': now.toIso8601String(),
      };
      final rs = RouteSuggestionModel.fromJson(json);
      expect(rs.id, 'rs1');
      expect(rs.suggestedBy, 'user1');
      expect(rs.originText, 'Station A');
      expect(rs.destinationText, 'Station B');
      expect(rs.status, SuggestionStatus.idea);
      expect(rs.voteCount, 3);
      expect(rs.contributionCount, 1);
      expect(rs.priority, Priority.medium);
    });

    test('fromJson handles missing title gracefully', () {
      final json = <String, dynamic>{
        'id': 'rs2',
        'proposedBy': 'user2',
        'status': 'inReview',
        'proposedAt': now.toIso8601String(),
      };
      final rs = RouteSuggestionModel.fromJson(json);
      expect(rs.id, 'rs2');
      expect(rs.originText, '');
      expect(rs.destinationText, '');
      expect(rs.status, SuggestionStatus.inReview);
    });

    test('toJson includes all optional fields when present', () {
      final rs = RouteSuggestionModel(
        id: 'rs3',
        suggestedBy: 'user3',
        originText: 'A',
        destinationText: 'B',
        notes: 'test note',
        routeCode: 'X1',
        operatorName: 'TransitCo',
        serviceType: ServiceType.urban,
        status: SuggestionStatus.accepted,
        voteCount: 10,
        contributionCount: 2,
        priority: Priority.medium,
        createdAt: now,
      );
      final json = rs.toJson();
      expect(json['id'], 'rs3');
      expect(json['title'], 'A - B');
      expect(json['description'], 'test note');
      expect(json['routeCode'], 'X1');
      expect(json['operatorName'], 'TransitCo');
      expect(json['serviceType'], 'urban');
      expect(json['status'], 'accepted');
      expect(json['votes'], 10);
      expect(json['proposedAt'], now.toIso8601String());
    });

    test('toJson omits null optional fields', () {
      final rs = RouteSuggestionModel(
        id: 'rs4',
        suggestedBy: 'user4',
        originText: 'C',
        destinationText: 'D',
        status: SuggestionStatus.idea,
        createdAt: now,
      );
      final json = rs.toJson();
      expect(json.containsKey('description'), false);
      expect(json.containsKey('routeCode'), false);
      expect(json.containsKey('operatorName'), false);
      expect(json.containsKey('serviceType'), false);
    });
  });
}
