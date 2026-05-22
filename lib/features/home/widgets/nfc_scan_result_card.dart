import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/nfc/nfc_card_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class NfcScanResultCard extends StatelessWidget {
  const NfcScanResultCard({
    super.key,
    required this.c,
    required this.result,
  });

  final TransitColorScheme c;
  final NfcCardResult result;

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(result.scannedAt);
    final timeAgo = elapsed.inMinutes < 1
        ? 'Ahora mismo'
        : elapsed.inMinutes < 60
            ? 'Hace ${elapsed.inMinutes} min'
            : 'Hace ${elapsed.inHours}h';

    return GlassCard(
      blur: 30,
      fillOpacity: 0.10,
      borderRadius: 20,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GradientText(
                'TARJETA CONSORCIO',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
                gradient: c.gradientAccent,
              ),
              const Spacer(),
              Icon(Icons.nfc, size: 20, color: c.accent),
            ],
          ),
          const SizedBox(height: 28),
          Semantics(
            label: AppLocalizations.of(context).nfcCardBalance(result.balance.toStringAsFixed(2)),
            child: Center(
              child: GradientText(
                '${result.balance.toStringAsFixed(2)} \u20AC',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
                gradient: c.gradientAccent,
              ),
            ),
          ),
          Center(
            child: Text(
              'saldo disponible',
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            result.cardId,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: c.textLo,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(timeAgo, style: TransitTypography.bodySmall(c.textLo)),
        ],
      ),
    );
  }
}
