import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/reputation.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'widgets/reputation_level_card.dart';

class ReputationScreen extends ConsumerWidget {
  const ReputationScreen({super.key});

  static final _events = const [
    ('incidentCreated', Icons.warning_amber, 5),
    ('feedbackSubmitted', Icons.feedback, 3),
    ('feedbackAccepted', Icons.check_circle, 10),
    ('suggestionCreated', Icons.lightbulb, 5),
    ('suggestionVoteReceived', Icons.thumb_up, 2),
    ('suggestionVerified', Icons.verified, 20),
    ('suggestionOfficial', Icons.auto_awesome, 50),
    ('duplicateReport', Icons.content_copy, 1),
    ('incidentRejectedSpam', Icons.block, -10),
  ];

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final score = user.reputationScore;
    final rank = ReputationRank.forScore(score);
    final initials = _initials(user.name);

    final nextIdx = ReputationRank.values.indexOf(rank) + 1;
    final isMaxRank = nextIdx >= ReputationRank.values.length;
    final nextMin = isMaxRank ? rank.minScore : ReputationRank.values[nextIdx].minScore;
    final rangeStart = rank.minScore;
    final rangeSize = nextMin - rangeStart;
    final progress = rangeSize > 0 ? (score - rangeStart) / rangeSize : 1.0;

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          Column(
            children: [
              TransitAppBar(title: l10n.reputationTitle),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _HeaderCard(user: user, c: c, initials: initials),
                    const SizedBox(height: 12),
                    ReputationLevelCard(
                      c: c,
                      l10n: l10n,
                      score: score,
                      rank: rank,
                      progress: progress,
                      rangeStart: rangeStart,
                      nextMin: nextMin,
                      isMaxRank: isMaxRank,
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(title: l10n.reputationHowToEarn, c: c),
                    const SizedBox(height: 8),
                    _HowToEarnCard(c: c, l10n: l10n),
                    const SizedBox(height: 16),
                    _SectionHeader(title: l10n.reputationRanks, c: c),
                    const SizedBox(height: 8),
                    ...ReputationRank.values.map(
                      (r) => _RankCard(rank: r, currentRank: rank, c: c, l10n: l10n),
                    ),
                    const SizedBox(height: 20),
                    _TooltipCard(c: c, l10n: l10n),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.user,
    required this.c,
    required this.initials,
  });

  final UserModel user;
  final TransitColorScheme c;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: c.accent.withValues(alpha: 0.25),
                width: 0.5,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.accent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: c.textHi,
                  ),
                ),
                const SizedBox(height: 4),
                ReputationBadge(user.reputationLevel, score: user.reputationScore),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.c});

  final String title;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: GradientText(
        title.toUpperCase(),
        style: GoogleFonts.ibmPlexMono(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
        gradient: c.gradientAccent,
      ),
    );
  }
}

class _HowToEarnCard extends StatelessWidget {
  const _HowToEarnCard({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: ReputationScreen._events.map((e) {
          final eventKey = e.$1;
          final icon = e.$2;
          final pts = e.$3;
          final label = switch (eventKey) {
            'incidentCreated' => l10n.reputationEventIncidentCreated,
            'incidentRejectedSpam' => l10n.reputationEventIncidentRejectedSpam,
            'feedbackSubmitted' => l10n.reputationEventFeedbackSubmitted,
            'feedbackAccepted' => l10n.reputationEventFeedbackAccepted,
            'suggestionCreated' => l10n.reputationEventSuggestionCreated,
            'suggestionVoteReceived' => l10n.reputationEventSuggestionVoteReceived,
            'suggestionVerified' => l10n.reputationEventSuggestionVerified,
            'suggestionOfficial' => l10n.reputationEventSuggestionOfficial,
            'duplicateReport' => l10n.reputationEventDuplicateReport,
            _ => eventKey,
          };
          final sign = pts >= 0 ? '+' : '';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: c.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                ),
                Text(
                  '$sign$pts',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: pts >= 0 ? c.stateOnTime : c.stateCancelled,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.rank,
    required this.currentRank,
    required this.c,
    required this.l10n,
  });

  final ReputationRank rank;
  final ReputationRank currentRank;
  final TransitColorScheme c;
  final AppLocalizations l10n;

  String _labelFor(ReputationRank r) => switch (r) {
        ReputationRank.none => l10n.reputationRankNone,
        ReputationRank.novice => l10n.reputationRankNovice,
        ReputationRank.contributor => l10n.reputationRankContributor,
        ReputationRank.advocate => l10n.reputationRankAdvocate,
        ReputationRank.cartographer => l10n.reputationRankCartographer,
        ReputationRank.guardian => l10n.reputationRankGuardian,
        ReputationRank.legend => l10n.reputationRankLegend,
      };

  @override
  Widget build(BuildContext context) {
    final isCurrent = rank == currentRank;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        blur: 20,
        fillOpacity: isCurrent ? 0.12 : 0.06,
        borderRadius: 12,
        useAccentBorder: isCurrent,
        accentColor: rank.color,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: rank.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(rank.icon, size: 20, color: rank.color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(rank),
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCurrent ? rank.color : c.textHi,
                    ),
                  ),
                  Text(
                    '${rank.minScore}+ ${l10n.reputationPoints}',
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
              ),
            ),
            if (isCurrent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: rank.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rank.color.withValues(alpha: 0.3)),
                ),
                child: Text(
                  l10n.reputationCurrentRank.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: rank.color,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TooltipCard extends StatelessWidget {
  const _TooltipCard({required this.c, required this.l10n});

  final TransitColorScheme c;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: c.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.reputationTooltip,
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          ),
        ],
      ),
    );
  }
}
