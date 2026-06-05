import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:transitly/data/cache/hive_box_provider.dart';
import 'package:transitly/data/mock/mock_data_service.dart';
import 'package:transitly/data/supabase/supabase_client_provider.dart';
import 'package:transitly/features/map/map_data_cache.dart';
import 'package:transitly/shared/models/route_model.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('hive_mapcache_test_');
    Hive.init(dir.path);
  });

  test('cache uses mock data when routesBox is empty even with auth session',
      () async {
    final mockData = await MockDataService.init();
    expect(mockData.routes, isNotEmpty,
        reason: 'precondition: mock data must have routes for this test');

    final boxName = 'routes_test_empty_${DateTime.now().microsecondsSinceEpoch}';
    final emptyRoutesBox = await Hive.openBox<RouteModel>(boxName);

    final container = ProviderContainer(
      overrides: [
        mockDataServiceProvider.overrideWithValue(mockData),
        routesBoxProvider.overrideWithValue(emptyRoutesBox),
        supabaseClientProvider.overrideWith(
          (ref) => throw UnimplementedError(
              'supabase client should not be needed for empty-box fallback'),
        ),
      ],
    );
    addTearDown(container.dispose);

    final cache = container.read(mapDataCacheProvider);

    expect(cache.routeMap, isNotEmpty,
        reason: 'fallback to mock should populate routeMap');
    expect(cache.routePathsLod, isNotEmpty,
        reason: 'fallback to mock should populate routePathsLod');
    expect(cache.routeStopsMap, isNotEmpty,
        reason: 'fallback to mock should populate routeStopsMap');
  });
}
