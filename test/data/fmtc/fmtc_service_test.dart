import 'package:flutter_test/flutter_test.dart';
import 'package:transitly/data/fmtc/fmtc_service.dart';

void main() {
  group('FmtcService', () {
    test('storeName builds transitly-<style>', () {
      // storeName ahora es una función que toma el style del mapa
      // (streets/basic/bright/dark/light) para soportar caches por estilo.
      expect(FmtcService.storeName('streets'), 'transitly-streets');
      expect(FmtcService.storeName('dark'), 'transitly-dark');
    });

    test('databaseSizeDefault is 50 MB', () {
      expect(FmtcService.databaseSizeDefault, 50 * 1024 * 1024);
    });

    test('maxTileCountDefault is 50000', () {
      expect(FmtcService.maxTileCountDefault, 50000);
    });
  });
}
