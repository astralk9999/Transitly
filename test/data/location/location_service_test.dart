import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/geo/location_service.dart';

void main() {
  group('LocationServiceError', () {
    test('has 5 expected enum values', () {
      const values = LocationServiceError.values;
      expect(values.length, 5);
      expect(values, contains(LocationServiceError.denied));
      expect(values, contains(LocationServiceError.deniedForever));
      expect(values, contains(LocationServiceError.disabled));
      expect(values, contains(LocationServiceError.timeout));
      expect(values, contains(LocationServiceError.unknown));
    });
  });

  group('LocationServiceException', () {
    test('stores error and message when provided', () {
      const ex = LocationServiceException(
        LocationServiceError.deniedForever,
        'Permiso denegado permanentemente',
      );
      expect(ex.error, LocationServiceError.deniedForever);
      expect(ex.message, 'Permiso denegado permanentemente');
    });

    test('message is null when omitted and is an Exception', () {
      const ex = LocationServiceException(LocationServiceError.timeout);
      expect(ex.message, isNull);
      expect(ex, isA<Exception>());
    });
  });
}
