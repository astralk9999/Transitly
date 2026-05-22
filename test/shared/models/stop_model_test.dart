import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/shared/models/stop_model.dart';

void main() {
  group('StopModel', () {
    test('fromJson creates valid stop', () {
      final json = {
        'name': 'Plaza del Caballo',
        'officialCode': 'PC001',
        'lat': 36.6866,
        'lng': -6.1378,
        'municipality': 'Jerez',
        'hasShelter': true,
        'hasBench': true,
        'isAccessible': true,
      };
      final stop = StopModel.fromJson(json);
      expect(stop.id, 'PC001');
      expect(stop.name, 'Plaza del Caballo');
      expect(stop.officialCode, 'PC001');
      expect(stop.lat, 36.6866);
      expect(stop.lng, -6.1378);
      expect(stop.municipality, 'Jerez');
      expect(stop.hasShelter, true);
      expect(stop.hasBench, true);
      expect(stop.isAccessible, true);
      expect(stop.hasDisplay, false);
      expect(stop.zoneId, isNull);
      expect(stop.photoUrl, isNull);
      expect(stop.notes, isNull);
    });

    test('toJson roundtrips correctly', () {
      final stop = StopModel(
        id: 'S001',
        name: 'Test Stop',
        officialCode: 'S001',
        lat: 36.7,
        lng: -6.1,
        municipality: 'Test',
        hasShelter: true,
      );
      final json = stop.toJson();
      expect(json['name'], 'Test Stop');
      expect(json['officialCode'], 'S001');
      expect(json['lat'], 36.7);
      expect(json['lng'], -6.1);
      expect(json['municipality'], 'Test');
      expect(json['hasShelter'], true);
      expect(json['hasBench'], false);
      expect(json['isAccessible'], false);
    });

    test('copyWith preserves unchanged fields', () {
      final stop = StopModel(
        id: 'S001',
        name: 'Original',
        officialCode: 'S001',
        lat: 36.7,
        lng: -6.1,
        municipality: 'Test',
      );
      final copy = stop.copyWith(name: 'Renamed', lat: 36.8);
      expect(copy.name, 'Renamed');
      expect(copy.lat, 36.8);
      expect(copy.id, 'S001');
      expect(copy.officialCode, 'S001');
      expect(copy.municipality, 'Test');
    });
  });
}
