import 'package:freezed_annotation/freezed_annotation.dart';

part 'pending_action.freezed.dart';
part 'pending_action.g.dart';

/// Tipo de mutación encolada para sincronización diferida.
///
/// Cada `kind` se asocia a un `ActionExecutor` registrado por su
/// repositorio. Si el ejecutor no está registrado al drenar, la
/// acción queda en cola hasta que alguien lo registre (típicamente
/// porque la feature aún no ha aterrizado).
enum PendingActionKind {
  createIncident,
  createRouteFeedback,
  createRouteSuggestion,
  createFeatureRequest,
  createCommunityRoute,
  updateUserPrefs,
  submitOfficialRequest,
  claimInvitationCode,
  voteSuggestion,
  voteFeatureRequest,
  markFavorite,
}

/// Mutación pendiente de aplicar contra el backend. Se persiste en
/// la caja Hive `pending_actions` (o `dead_letter_actions` cuando
/// supera 10 intentos fallidos).
@freezed
class PendingAction with _$PendingAction {
  const factory PendingAction({
    required String id,
    required PendingActionKind kind,
    @Default(<String, dynamic>{}) Map<String, dynamic> payload,
    required DateTime createdAt,
    @Default(0) int attempts,
    String? lastError,
  }) = _PendingAction;

  factory PendingAction.fromJson(Map<String, dynamic> json) =>
      _$PendingActionFromJson(json);
}
