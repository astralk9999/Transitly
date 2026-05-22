import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/fmtc/fmtc_service.dart';

void main() {
  group('FmtcService', () {
    test('storeName is transitly', () {
      expect(FmtcService.storeName, 'transitly');
    });

    test('databaseSizeDefault is 50 MB', () {
      expect(FmtcService.databaseSizeDefault, 50 * 1024 * 1024);
    });

    test('maxTileCountDefault is 50000', () {
      expect(FmtcService.maxTileCountDefault, 50000);
    });
  });
}
