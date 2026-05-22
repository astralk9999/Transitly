import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/feature_request/domain/feature_request_repository.dart';
import 'package:transitly/shared/models/feature_request.dart';

void main() {
  group('FeatureRequest', () {
    test('creates with required fields', () {
      final fr = FeatureRequest(
        id: 'fr-1',
        title: 'New bus stop',
        description: 'Add a stop at Main St',
        submittedBy: 'user-1',
        category: FeatureRequestCategory.newRoute,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
      );
      expect(fr.id, 'fr-1');
      expect(fr.title, 'New bus stop');
      expect(fr.category, FeatureRequestCategory.newRoute);
      expect(fr.status, FeatureRequestStatus.open);
      expect(fr.priority, FeatureRequestPriority.normal);
      expect(fr.votes, 0);
    });

    test('copyWith updates editable fields', () {
      final fr = FeatureRequest(
        id: 'fr-2',
        title: 'Fix schedule',
        description: 'Schedule is wrong for L2',
        submittedBy: 'user-2',
        category: FeatureRequestCategory.dataCorrection,
        createdAt: DateTime.utc(2026, 5, 1),
        updatedAt: DateTime.utc(2026, 5, 1),
      );
      final updated = fr.copyWith(
        status: FeatureRequestStatus.inReview,
        votes: 10,
        adminNotes: 'Under review',
      );
      expect(updated.status, FeatureRequestStatus.inReview);
      expect(updated.votes, 10);
      expect(updated.adminNotes, 'Under review');
      expect(updated.id, fr.id);
      expect(updated.title, fr.title);
    });

    test('FeatureRequestRepositoryError enum has 6 cases', () {
      expect(FeatureRequestRepositoryError.values.length, 6);
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.notFound));
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.network));
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.parse));
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.denied));
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.validation));
      expect(FeatureRequestRepositoryError.values,
          contains(FeatureRequestRepositoryError.unknown));
    });
  });
}
