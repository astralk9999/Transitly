import 'package:freezed_annotation/freezed_annotation.dart';

part 'map_filter_state.freezed.dart';
part 'map_filter_state.g.dart';

/// Estado de los filtros del mapa. Se persiste en Hive para
/// sobrevivir al reinicio de la app (key `user_preferences:mapFilters`).
@freezed
class MapFilterState with _$MapFilterState {
  const factory MapFilterState({
    @Default(true) bool showOfficial,
    @Default(true) bool showCommunity,
    @Default(<String>{}) Set<String> activeOperators,
    @Default(<String>{}) Set<String> activeKinds,
    @Default(0) int nextMinutes,
    @Default(false) bool onlyAccessible,
    @Default(false) bool onlyFavorites,
    @Default(5000) double radiusMeters,
  }) = _MapFilterState;

  factory MapFilterState.fromJson(Map<String, dynamic> json) =>
      _$MapFilterStateFromJson(json);
}

/// Kind de ruta para el filtro del mapa (urbano, interurbano, nocturno, etc.).
enum RouteKind { urbano, interurbano, metropolitano, nocturno, escolar }
