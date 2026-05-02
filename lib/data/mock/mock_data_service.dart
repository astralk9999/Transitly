import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/models.dart';

final mockDataServiceProvider = Provider<MockDataService>((ref) {
  throw UnimplementedError('Must be overridden after init');
});

class MockDataService {
  MockDataService._();

  static const String _assetPath = 'assets/mock/comujesa_data.json';

  late OperatorModel operator_;
  late List<RouteModel> routes;
  late List<StopModel> stops;
  late Map<String, List<RouteStopModel>> routeStops;
  late Map<String, List<ScheduleModel>> schedules;
  late List<ActiveTripModel> activeTrips;
  late List<AlertModel> alerts;
  late List<IncidentModel> incidents;
  late List<RouteSuggestionModel> routeSuggestions;
  late List<RouteFeedbackModel> feedbacks;
  late List<UserModel> users;
  late UserCardModel? transitCard;
  late List<UserFavoriteModel> favorites;
  late List<TripHistoryModel> tripHistory;
  late List<AchievementModel> achievements;
  late List<UserAchievementModel> userAchievements;
  late List<RouteChangelogModel> routeChangelogs;
  late Map<String, Map<int, List<List<double>>>> polylinesLod;
  late Map<String, List<double>> routeBounds; // [minLat, minLng, maxLat, maxLng]

  /// Tamaño en bytes del JSON tal como se leyó del bundle.
  late int assetBytes;

  /// Momento de la última carga (primera [init] o [reload]).
  late DateTime loadedAt;

  /// Full-detail polylines (LOD4) for bus interpolation compatibility.
  Map<String, List<List<double>>> get polylines =>
      polylinesLod.map((k, v) => MapEntry(k, v[4] ?? v.values.last));

  static Future<MockDataService> init() async {
    final svc = MockDataService._();
    await svc._loadFromAsset();
    return svc;
  }

  /// Vuelve a leer el JSON desde assets y re-parsea en la misma instancia.
  /// Permite a la UI "recargar" los datos sin reiniciar la app.
  Future<void> reload() => _loadFromAsset();

  Future<void> _loadFromAsset() async {
    final raw = await rootBundle.loadString(_assetPath);
    final data = json.decode(raw) as Map<String, dynamic>;
    assetBytes = utf8.encode(raw).length;
    loadedAt = DateTime.now();
    _parse(data);
  }

  void _parse(Map<String, dynamic> data) {
    // Operator
    operator_ = OperatorModel.fromJson(data['operator'] as Map<String, dynamic>);

    // Routes, stops, routeStops, schedules, polylines
    final lines = data['lines'] as List<dynamic>;
    final routeList = <RouteModel>[];
    final stopMap = <String, StopModel>{};
    final rStops = <String, List<RouteStopModel>>{};
    final sched = <String, List<ScheduleModel>>{};
    final polysLod = <String, Map<int, List<List<double>>>>{};
    final bounds = <String, List<double>>{};

    for (final line in lines) {
      final lj = line as Map<String, dynamic>;
      final route = RouteModel.fromJson(lj, operatorId: operator_.id);
      routeList.add(route);

      // Stops
      final lineStops = <RouteStopModel>[];
      for (final sj in lj['stops'] as List<dynamic>) {
        final sm = sj as Map<String, dynamic>;
        final stop = StopModel.fromJson(sm);
        stopMap[stop.id] = stop;
        lineStops.add(RouteStopModel.fromJson(sm, routeId: route.id));
      }
      rStops[route.id] = lineStops;

      // Schedules
      final schedJ = lj['schedules'] as Map<String, dynamic>;
      final lineSchedules = <ScheduleModel>[];
      var idx = 0;
      for (final entry in schedJ.entries) {
        final dayType = DayType.fromString(entry.key);
        for (final time in entry.value as List<dynamic>) {
          lineSchedules.add(ScheduleModel(
            id: '${route.id}-$idx',
            routeId: route.id,
            departureTime: time as String,
            dayType: dayType,
          ));
          idx++;
        }
      }
      sched[route.id] = lineSchedules;

      // Polyline — LOD format { lod0..lod4 }
      final polyJ = lj['polyline'] as Map<String, dynamic>?;
      if (polyJ != null) {
        final coordsRaw = polyJ['coordinates'];
        final lodMap = <int, List<List<double>>>{};

        if (coordsRaw is Map<String, dynamic>) {
          for (final lodKey in ['lod0', 'lod1', 'lod2', 'lod3', 'lod4']) {
            final lodIdx = int.parse(lodKey.substring(3));
            final pts = (coordsRaw[lodKey] as List<dynamic>?)
                ?.map((c) => [(c as List<dynamic>)[1] as double, c[0] as double])
                .toList();
            if (pts != null && pts.isNotEmpty) lodMap[lodIdx] = pts;
          }
        } else if (coordsRaw is List<dynamic>) {
          // Legacy flat format
          final pts = coordsRaw
              .map((c) => [(c as List<dynamic>)[1] as double, c[0] as double])
              .toList();
          lodMap[4] = pts;
        }

        if (lodMap.isNotEmpty) {
          polysLod[route.id] = lodMap;

          // Compute bounding box from highest LOD
          final fullPts = lodMap[4] ?? lodMap.values.last;
          var minLat = double.infinity, minLng = double.infinity;
          var maxLat = double.negativeInfinity, maxLng = double.negativeInfinity;
          for (final p in fullPts) {
            if (p[0] < minLat) minLat = p[0];
            if (p[0] > maxLat) maxLat = p[0];
            if (p[1] < minLng) minLng = p[1];
            if (p[1] > maxLng) maxLng = p[1];
          }
          bounds[route.id] = [minLat, minLng, maxLat, maxLng];
        }
      }
    }

    routes = routeList;
    stops = stopMap.values.toList();
    routeStops = rStops;
    schedules = sched;
    polylinesLod = polysLod;
    routeBounds = bounds;

    // Active trips
    activeTrips = (data['activeTrips'] as List<dynamic>?)
            ?.map((e) =>
                ActiveTripModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Alerts
    alerts = (data['alerts'] as List<dynamic>?)
            ?.map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Incidents
    incidents = (data['incidents'] as List<dynamic>?)
            ?.map((e) => IncidentModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Suggestions
    routeSuggestions = (data['routeSuggestions'] as List<dynamic>?)
            ?.map((e) =>
                RouteSuggestionModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Feedbacks
    feedbacks = (data['feedbacks'] as List<dynamic>?)
            ?.map((e) =>
                RouteFeedbackModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Users
    final profiles = data['userProfiles'] as Map<String, dynamic>?;
    users = profiles?.values
            .map((e) => UserModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Transit card
    final cardJ = data['transitCard'] as Map<String, dynamic>?;
    transitCard = cardJ != null ? UserCardModel.fromJson(cardJ) : null;

    // Favorites
    favorites = (data['favorites'] as List<dynamic>?)
            ?.map(
                (e) => UserFavoriteModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Trip history
    tripHistory = (data['tripHistory'] as List<dynamic>?)
            ?.map(
                (e) => TripHistoryModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    // Badges → achievements + user progress
    final badgesJ = data['badges'] as List<dynamic>? ?? [];
    achievements = badgesJ
        .map((e) => AchievementModel.fromJson(e as Map<String, dynamic>))
        .toList();
    userAchievements = badgesJ
        .map((e) =>
            UserAchievementModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Route changelogs
    routeChangelogs = (data['routeChangelogs'] as List<dynamic>?)
            ?.map((e) =>
                RouteChangelogModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
  }

  // ── Helpers ──────────────────────────────────────────────

  RouteModel? getRouteById(String id) {
    for (final r in routes) {
      if (r.id == id) return r;
    }
    return null;
  }

  StopModel? getStopById(String id) {
    for (final s in stops) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<StopModel> getStopsForRoute(String routeId) {
    final rs = routeStops[routeId];
    if (rs == null) return [];
    final ordered = List<RouteStopModel>.from(rs)
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return ordered
        .map((rs) => getStopById(rs.stopId))
        .whereType<StopModel>()
        .toList();
  }

  List<ScheduleModel> getSchedulesForRoute(String routeId,
      {DayType? dayType}) {
    final all = schedules[routeId] ?? [];
    if (dayType == null) return all;
    return all.where((s) => s.dayType == dayType).toList();
  }

  List<StopModel> getNearbyStops(double lat, double lng, int count) {
    final sorted = List<StopModel>.from(stops)
      ..sort((a, b) {
        final dA = _distSq(a.lat, a.lng, lat, lng);
        final dB = _distSq(b.lat, b.lng, lat, lng);
        return dA.compareTo(dB);
      });
    return sorted.take(count).toList();
  }

  List<ScheduleModel> getNextDepartures(
      String routeId, String stopId, int count) {
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final weekday = now.weekday;
    final dayType = weekday == 6
        ? DayType.saturday
        : weekday == 7
            ? DayType.sundayHoliday
            : DayType.weekday;

    final all = getSchedulesForRoute(routeId, dayType: dayType);
    final future = all.where((s) {
      final parts = s.departureTime.split(':');
      final m = int.parse(parts[0]) * 60 + int.parse(parts[1]);
      return m >= nowMinutes;
    }).toList()
      ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

    return future.take(count).toList();
  }

  ActiveTripModel? getActiveTripForRoute(String routeId) {
    for (final t in activeTrips) {
      if (t.routeId == routeId && t.status != TripStatus.cancelled) return t;
    }
    return null;
  }

  List<AlertModel> getAlertsForRoute(String routeId) =>
      alerts.where((a) => a.routeId == routeId).toList();

  List<IncidentModel> getIncidentsForRoute(String routeId) =>
      incidents.where((i) => i.routeId == routeId).toList();

  /// Devuelve los cambios registrados para una ruta, ordenados de más
  /// reciente a más antiguo.
  List<RouteChangelogModel> getChangelogForRoute(String routeId) {
    final entries =
        routeChangelogs.where((c) => c.routeId == routeId).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  static double _distSq(double lat1, double lng1, double lat2, double lng2) {
    final dLat = lat1 - lat2;
    final dLng = (lng1 - lng2) * cos(lat1 * pi / 180);
    return dLat * dLat + dLng * dLng;
  }
}
