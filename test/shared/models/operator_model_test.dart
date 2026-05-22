import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/operator_model.dart';

void main() {
  group('OperatorModel', () {
    test('fromJson creates valid operator', () {
      final json = {
        'id': '1',
        'name': 'Test Op',
        'shortName': 'TO',
        'slug': 'test',
        'region': 'Test',
      };
      final op = OperatorModel.fromJson(json);
      expect(op.name, 'Test Op');
      expect(op.slug, 'test');
      expect(op.shortName, 'TO');
    });

    test('toJson roundtrips correctly', () {
      final op = OperatorModel(
        id: '1',
        name: 'Test',
        shortName: 'TEST',
        slug: 'test',
        region: 'Region',
        website: '',
        contactEmail: '',
        phone: '',
      );
      final json = op.toJson();
      expect(json['id'], '1');
      expect(json['name'], 'Test');
    });

    test('copyWith preserves unchanged fields', () {
      final op = OperatorModel(
        id: '1',
        name: 'Test',
        shortName: 'TEST',
        slug: 'test',
        region: 'Region',
        website: '',
        contactEmail: '',
        phone: '',
      );
      final copy = op.copyWith(name: 'New');
      expect(copy.name, 'New');
      expect(copy.slug, 'test');
      expect(copy.id, '1');
    });
  });
}
