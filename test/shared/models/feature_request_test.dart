import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/feature_request.dart';

void main() {
  final now = DateTime(2026, 5, 23);

  group('FeatureRequest', () {
    test('fromJson creates valid FeatureRequest', () {
      final json = <String, dynamic>{
        'id': 'fr1',
        'title': 'Add Route X',
        'description': 'Please add a route from A to B',
        'submittedBy': 'user1',
        'category': 'newRoute',
        'priority': 'high',
        'status': 'open',
        'votes': 5,
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final fr = FeatureRequest.fromJson(json);
      expect(fr.id, 'fr1');
      expect(fr.title, 'Add Route X');
      expect(fr.category, FeatureRequestCategory.newRoute);
      expect(fr.priority, FeatureRequestPriority.high);
      expect(fr.status, FeatureRequestStatus.open);
      expect(fr.votes, 5);
    });

    test('FeatureRequestCategory enum has all values', () {
      expect(FeatureRequestCategory.values, [
        FeatureRequestCategory.newRoute,
        FeatureRequestCategory.routeOfficial,
        FeatureRequestCategory.appFeature,
        FeatureRequestCategory.dataCorrection,
        FeatureRequestCategory.other,
      ]);
    });

    test('copyWith preserves unchanged fields', () {
      final fr = FeatureRequest(
        id: 'fr1',
        title: 'Add Route X',
        description: 'desc',
        submittedBy: 'user1',
        category: FeatureRequestCategory.newRoute,
        priority: FeatureRequestPriority.normal,
        status: FeatureRequestStatus.open,
        votes: 0,
        createdAt: now,
        updatedAt: now,
      );
      final copy = fr.copyWith(status: FeatureRequestStatus.inReview, votes: 3);
      expect(copy.status, FeatureRequestStatus.inReview);
      expect(copy.votes, 3);
      expect(copy.id, 'fr1');
      expect(copy.title, 'Add Route X');
      expect(copy.category, FeatureRequestCategory.newRoute);
    });
  });
}
