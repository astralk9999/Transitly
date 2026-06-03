import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_filter_state.freezed.dart';
part 'map_filter_state.g.dart';

@freezed
abstract class MapFilterState with _$MapFilterState {
  const factory MapFilterState({
    @Default(true) bool showOfficial,
    @Default(true) bool showCommunity,
    @Default(<String>{}) Set<String> disabledOperators,
    @Default(<String>{}) Set<String> disabledKinds,
    @Default(<String>{}) Set<String> disabledLines,
    @Default(<String>{}) Set<String> disabledZones,
    @Default(<String>{}) Set<String> disabledRouteIds,
    @Default(0) int nextMinutes,
    @Default(false) bool onlyAccessible,
    @Default(false) bool onlyFavorites,
    @Default(false) bool showAllStops,
    @Default(5000) double radiusMeters,
  }) = _MapFilterState;

  factory MapFilterState.fromJson(Map<String, dynamic> json) =>
      _$MapFilterStateFromJson(json);
}

enum RouteKind { urbano, interurbano, metropolitano, nocturno, escolar }
