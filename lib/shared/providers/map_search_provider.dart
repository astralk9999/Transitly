import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../core/utils/app_logger.dart';
import '../../data/mock/mock_data_service.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';

const _logTag = 'Provider:MapSearch';

enum MapSearchResultType { route, stop, place }

class MapSearchResult {
  const MapSearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    this.route,
    this.stop,
    this.lat,
    this.lng,
  });

  final MapSearchResultType type;
  final String title;
  final String subtitle;
  final RouteModel? route;
  final StopModel? stop;
  final double? lat;
  final double? lng;
}

final mapSearchQueryProvider = StateProvider<String>((ref) => '');

final mapSearchResultsProvider =
    FutureProvider.autoDispose<List<MapSearchResult>>((ref) async {
  final query = ref.watch(mapSearchQueryProvider).trim();
  if (query.isEmpty) return [];

  await Future<void>.delayed(const Duration(milliseconds: 300));

  final results = <MapSearchResult>[];

  // Routes
  try {
    final mockData = ref.read(mockDataServiceProvider);
    final routes = mockData.routes.where((r) {
      final q = query.toLowerCase();
      return r.code.toLowerCase().contains(q) ||
          r.name.toLowerCase().contains(q);
    }).take(5);

    for (final r in routes) {
      results.add(MapSearchResult(
        type: MapSearchResultType.route,
        title: '${r.code} · ${r.name}',
        subtitle: r.serviceType.label,
        route: r,
      ));
    }
  } catch (_) {}

  // Stops
  try {
    final mockData = ref.read(mockDataServiceProvider);
    final stops = mockData.stops.where((s) {
      final q = query.toLowerCase();
      return s.name.toLowerCase().contains(q) ||
          s.officialCode.toLowerCase().contains(q);
    }).take(5);

    for (final s in stops) {
      results.add(MapSearchResult(
        type: MapSearchResultType.stop,
        title: s.name,
        subtitle: s.officialCode,
        stop: s,
        lat: s.lat,
        lng: s.lng,
      ));
    }
  } catch (_) {}

  // Places via Nominatim
  if (results.length < 8) {
    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'q': query,
          'format': 'json',
          'limit': '5',
          'bounded': '1',
          'viewbox': '-6.30,36.55,-5.90,36.80',
        },
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 5));
      if (resp.statusCode == 200) {
        final list = json.decode(resp.body) as List<dynamic>;
        for (final item in list.take(5)) {
          final displayName = item['display_name'] as String;
          final nameParts = displayName.split(',');
          final title = nameParts.first.trim();
          final subtitle = nameParts.length > 1
              ? nameParts.skip(1).take(2).map((s) => s.trim()).join(', ')
              : '';
          final lat = double.tryParse(item['lat'] as String? ?? '');
          final lng = double.tryParse(item['lon'] as String? ?? '');
          results.add(MapSearchResult(
            type: MapSearchResultType.place,
            title: title,
            subtitle: subtitle,
            lat: lat,
            lng: lng,
          ));
        }
      }
    } catch (e) {
      AppLogger.warn(_logTag, 'Nominatim search failed', e);
    }
  }

  return results;
});
