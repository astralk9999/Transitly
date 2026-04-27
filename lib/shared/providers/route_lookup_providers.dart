import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_data_service.dart';

/// For every stop, the list of route codes passing through it.
///
/// Built once per [mockDataServiceProvider] change. Use this to replace
/// O(n²) scans of `mockData.routeStops` from screen build methods.
final stopToRouteCodesProvider = Provider<Map<String, List<String>>>((ref) {
  final mockData = ref.watch(mockDataServiceProvider);
  final result = <String, List<String>>{};
  for (final entry in mockData.routeStops.entries) {
    final route = mockData.getRouteById(entry.key);
    if (route == null) continue;
    for (final rs in entry.value) {
      result.putIfAbsent(rs.stopId, () => []).add(route.code);
    }
  }
  return result;
});
