import 'package:freezed_annotation/freezed_annotation.dart';

part 'route_share.freezed.dart';
part 'route_share.g.dart';

enum RouteSharePermission { view, edit }

/// Permiso de acceso a una ruta compartida entre dos usuarios. Habilita
/// los flujos de F12 (compartir + oficializar) cuando el tomador puede
/// editar o solo visualizar.
@freezed
abstract class RouteShare with _$RouteShare {
  const factory RouteShare({
    required String routeId,
    required String sharedWithId,
    required String sharedById,
    @Default(RouteSharePermission.view) RouteSharePermission permission,
    required DateTime createdAt,
    DateTime? expiresAt,
  }) = _RouteShare;

  factory RouteShare.fromJson(Map<String, dynamic> json) =>
      _$RouteShareFromJson(json);
}
