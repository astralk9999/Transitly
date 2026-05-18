import 'package:freezed_annotation/freezed_annotation.dart';

part 'feature_request.freezed.dart';
part 'feature_request.g.dart';

enum FeatureRequestCategory {
  newRoute,
  routeOfficial,
  appFeature,
  dataCorrection,
  other,
}

enum FeatureRequestPriority { low, normal, high }

enum FeatureRequestStatus {
  open,
  inReview,
  accepted,
  rejected,
  scheduled,
  done,
}

/// Petición de feature/incidencia abierta por un usuario. Sustituye al
/// uso difuso de [RouteSuggestionModel] cuando lo solicitado no es una
/// ruta nueva (correcciones de datos, mejoras de la app, oficialización
/// de rutas comunitarias, etc.).
@freezed
abstract class FeatureRequest with _$FeatureRequest {
  const factory FeatureRequest({
    required String id,
    required String title,
    required String description,
    required String submittedBy,
    required FeatureRequestCategory category,
    @Default(FeatureRequestPriority.normal) FeatureRequestPriority priority,
    @Default(FeatureRequestStatus.open) FeatureRequestStatus status,
    @Default(0) int votes,
    Map<String, dynamic>? payload,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? adminNotes,
    String? assigneeId,
  }) = _FeatureRequest;

  factory FeatureRequest.fromJson(Map<String, dynamic> json) =>
      _$FeatureRequestFromJson(json);
}
