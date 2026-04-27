import '../../l10n/generated/app_localizations.dart';
import 'nfc_card_service.dart';

extension NfcCardErrorL10n on NfcCardError {
  String localizedMessage(AppLocalizations l10n, {String? fallback}) {
    return switch (this) {
      NfcCardError.unsupported => l10n.nfcErrorUnsupported,
      NfcCardError.notMifareClassic => l10n.nfcErrorNotMifareClassic,
      NfcCardError.authFailed => l10n.nfcErrorAuthFailed,
      NfcCardError.readFailed => l10n.nfcErrorReadFailed,
      NfcCardError.tagLost => l10n.nfcErrorTagLost,
      NfcCardError.unknown => fallback ?? l10n.nfcErrorUnknown,
    };
  }
}
