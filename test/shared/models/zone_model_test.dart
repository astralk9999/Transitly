import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/zone_model.dart';

void main() {
  group('ZoneModel', () {
    test('fromJson parses all fields', () {
      final json = <String, dynamic>{
        'id': 'z-1',
        'name': 'Jerez de la Frontera',
        'zoneType': 'municipality',
        'parentZoneId': 'prov-cadiz',
      };

      final zone = ZoneModel.fromJson(json);

      expect(zone.id, 'z-1');
      expect(zone.name, 'Jerez de la Frontera');
      expect(zone.zoneType, 'municipality');
      expect(zone.parentZoneId, 'prov-cadiz');
    });

    test('fromJson defaults missing zoneType and parentZoneId', () {
      final json = <String, dynamic>{
        'id': 'z-2',
        'name': 'Cádiz',
      };

      final zone = ZoneModel.fromJson(json);

      expect(zone.zoneType, 'municipality');
      expect(zone.parentZoneId, isNull);
    });

    test('toJson roundtrips and omits null parentZoneId', () {
      final original = ZoneModel(
        id: 'z-3',
        name: 'Sevilla',
        zoneType: 'province',
      );

      final json = original.toJson();
      final restored = ZoneModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.zoneType, original.zoneType);
      expect(restored.parentZoneId, original.parentZoneId);
      expect(json.containsKey('parentZoneId'), isFalse);
    });
  });
}
