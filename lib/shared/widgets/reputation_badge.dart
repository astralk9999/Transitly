import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../l10n/generated/app_localizations.dart';
import '../models/enums.dart';
import '../models/reputation.dart';

class ReputationBadge extends StatelessWidget {
  const ReputationBadge(this.level, {super.key, this.score = 0});

  final ReputationLevel level;
  final int score;

  @override
  Widget build(BuildContext context) {
    if (score > 0) {
      final l10n = AppLocalizations.of(context);
      return _buildRankBadge(context, l10n);
    }
    return _buildLevelBadge(context);
  }

  Widget _buildRankBadge(BuildContext context, AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final rank = ReputationRank.forScore(score);
    final label = _rankLabel(l10n, rank);

    return Semantics(
      label: '$label: $score pts',
      child: Container(
        padding: TransitSpacing.paddingBadge,
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(color: rank.color, width: TransitSpacing.strokeThin),
          borderRadius: BorderRadius.circular(TransitSpacing.radiusXs),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(rank.icon, size: 14, color: rank.color),
            const SizedBox(width: TransitSpacing.space4),
            Text(
              label,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: rank.color,
              ),
            ),
            const SizedBox(width: TransitSpacing.space4),
            Text(
              '$score',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: c.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final Color color;
    switch (level) {
      case ReputationLevel.new_:
        color = c.textLo;
      case ReputationLevel.contributor:
        color = c.textMid;
      case ReputationLevel.trusted:
        color = c.accent;
      case ReputationLevel.expert:
        color = c.stateOnTime;
    }

    return Semantics(
      label: 'Reputación: ${level.label}',
      child: Container(
        padding: TransitSpacing.paddingBadge,
        decoration: BoxDecoration(
          color: c.bgRaised,
          border: Border.all(color: color, width: TransitSpacing.strokeThin),
          borderRadius: BorderRadius.circular(TransitSpacing.radiusXs),
        ),
        child: Text(
          level.label.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
            color: color,
          ),
        ),
      ),
    );
  }

  String _rankLabel(AppLocalizations l10n, ReputationRank rank) => switch (rank) {
        ReputationRank.none => l10n.reputationRankNone,
        ReputationRank.novice => l10n.reputationRankNovice,
        ReputationRank.contributor => l10n.reputationRankContributor,
        ReputationRank.advocate => l10n.reputationRankAdvocate,
        ReputationRank.cartographer => l10n.reputationRankCartographer,
        ReputationRank.guardian => l10n.reputationRankGuardian,
        ReputationRank.legend => l10n.reputationRankLegend,
      };
}
