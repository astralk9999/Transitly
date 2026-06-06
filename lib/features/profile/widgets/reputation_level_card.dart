import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/reputation.dart';
import '../../../shared/widgets/glass_card.dart';

class ReputationLevelCard extends StatelessWidget {
  const ReputationLevelCard({
    super.key,
    required this.c,
    required this.l10n,
    required this.score,
    required this.rank,
    required this.progress,
    required this.rangeStart,
    required this.nextMin,
    required this.isMaxRank,
  });

  final TransitColorScheme c;
  final AppLocalizations l10n;
  final int score;
  final ReputationRank rank;
  final double progress;
  final int rangeStart;
  final int nextMin;
  final bool isMaxRank;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(rank.icon, size: 20, color: rank.color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$score ${l10n.reputationPoints}',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.textHi,
                  ),
                ),
              ),
              if (!isMaxRank)
                Text(
                  '$score/$nextMin',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textMid,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Mínimo 3% visible cuando ya estás dentro del rango: en el
          // límite exacto (score == rangeStart) progress era 0 y la
          // barra quedaba completamente vacía, dando la impresión de
          // no haber avanzado nada.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: isMaxRank
                  ? 1.0
                  : progress.clamp(0.0, 1.0) < 0.03
                      ? 0.03
                      : progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: c.bgSurface,
              valueColor: AlwaysStoppedAnimation(rank.color),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMaxRank
                ? l10n.reputationMaxRank
                : '${l10n.reputationNextRank}: ${nextMin - score} ${l10n.reputationPoints}',
            style: TransitTypography.bodySecondary(c.textMid),
          ),
        ],
      ),
    );
  }
}
