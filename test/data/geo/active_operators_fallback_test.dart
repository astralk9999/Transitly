import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/cache/hive_box_provider.dart';
import 'package:transitly/data/geo/geo_providers.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/shared/models/operator_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_geo_test_');
    Hive.init(dir.path);
  });

  test('activeOperatorsProvider falls back to mock when location null and '
      'operators cache empty (even with session)', () async {
    final mockData = await MockDataService.init();
    final boxName = 'operators_test_empty_${DateTime.now().microsecondsSinceEpoch}';
    final emptyBox = await Hive.openBox<OperatorModel>(boxName);

    final container = ProviderContainer(
      overrides: [
        mockDataServiceProvider.overrideWithValue(mockData),
        operatorsBoxProvider.overrideWithValue(emptyBox),
        currentLocationProvider.overrideWith((ref) => null),
        supabaseClientProvider.overrideWith(
          (ref) => throw UnimplementedError(
              'fallback should not need supabase client when location null'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(activeOperatorsProvider.future);

    expect(result, isNotEmpty,
        reason: 'fallback must return at least the mock operator');
    expect(result.first.id, equals(mockData.operator_.id));
  });
}
