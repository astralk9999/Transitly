import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/data/mock/mock_data_error.dart';
import 'package:transitly/data/mock/mock_data_exception.dart';
import 'package:transitly/data/mock/mock_data_service.dart';

const _emptyJson = '''
{
  "operator": {"id": "op-e", "name": "E", "shortName": "E", "region": "R", "website": "", "phone": ""},
  "lines": []
}
''';

class _StubAssetBundle extends AssetBundle {
  _StubAssetBundle({required this.content});

  final String content;

  @override
  Future<ByteData> load(String key) async {
    final bytes = utf8.encode(content);
    return ByteData.view(Uint8List.fromList(bytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    return content;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MockDataService edge', () {
    test('empty lines yields zero routes and stops', () async {
      final svc = await MockDataService.init(
        bundle: _StubAssetBundle(content: _emptyJson),
      );
      expect(svc.routes, isEmpty);
      expect(svc.stops, isEmpty);
    });

    test('getStopsForRoute returns empty for unknown route', () async {
      final svc = await MockDataService.init(
        bundle: _StubAssetBundle(content: _emptyJson),
      );
      expect(svc.getStopsForRoute('nonexistent'), isEmpty);
    });

    test('getSchedulesForRoute returns empty for unknown route', () async {
      final svc = await MockDataService.init(
        bundle: _StubAssetBundle(content: _emptyJson),
      );
      expect(svc.getSchedulesForRoute('nonexistent'), isEmpty);
    });
  });
}
