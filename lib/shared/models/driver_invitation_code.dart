import 'package:freezed_annotation/freezed_annotation.dart';

part 'driver_invitation_code.freezed.dart';
part 'driver_invitation_code.g.dart';

enum InvitationKind { driver, operatorAdmin }

/// Código de invitación de un solo uso (formato XXX-XXXX-XX) que un
/// operador genera para que un conductor o administrador secundario se
/// vincule a la organización en F6.
@freezed
class DriverInvitationCode with _$DriverInvitationCode {
  const factory DriverInvitationCode({
    required String code,
    required String operatorId,
    required String createdBy,
    @Default(1) int maxUses,
    @Default(0) int uses,
    required DateTime expiresAt,
    @Default(InvitationKind.driver) InvitationKind kind,
  }) = _DriverInvitationCode;

  factory DriverInvitationCode.fromJson(Map<String, dynamic> json) =>
      _$DriverInvitationCodeFromJson(json);
}
