import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/auth/auth_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/reputation.dart';
import '../../shared/models/user_model.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/is_dark_provider.dart';
import '../../shared/providers/user_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/gradient_text.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/user_avatar.dart';
import 'widgets/reputation_history_list.dart';
import 'widgets/reputation_level_card.dart';

class ReputationScreen extends ConsumerStatefulWidget {
  const ReputationScreen({super.key});

  @override
  ConsumerState<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends ConsumerState<ReputationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresca el perfil cada vez que entras a la pantalla — antes el
    // FutureProvider cacheaba la primera lectura para toda la sesión,
    // así que XP añadido en BD no se reflejaba aquí hasta reiniciar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(userProfileFromSupabaseProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final score = user.reputationScore;
    final rank = ReputationRank.forScore(score);

    final nextIdx = ReputationRank.values.indexOf(rank) + 1;
    final isMaxRank = nextIdx >= ReputationRank.values.length;
    final nextMin = isMaxRank ? rank.minScore : ReputationRank.values[nextIdx].minScore;
    final rangeStart = rank.minScore;
    // Progreso absoluto sobre el siguiente umbral (50/200 = 25%).
    // Antes era relativo al rango actual (50-50)/(200-50) = 0%, lo cual
    // dejaba la barra vacía justo al entrar al rango y se interpretaba
    // como "no he avanzado nada".
    final progress = isMaxRank ? 1.0 : (score / nextMin).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Column(
            children: [
              TransitAppBar(
                  title: l10n.reputationTitle, transparent: true),
              Expanded(
                child: RefreshIndicator(
                  color: c.accent,
                  onRefresh: () async {
                    ref.invalidate(userProfileFromSupabaseProvider);
                    await ref.read(userProfileFromSupabaseProvider.future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _HeaderCard(fallbackUser: user, c: c),
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
                      ReputationHistoryList(c: c, l10n: l10n),
                      const SizedBox(height: 16),
                      _SectionHeader(title: l10n.reputationRanks, c: c),
                      const SizedBox(height: 8),
                      ...ReputationRank.values.map(
                        (r) => _RankCard(
                            rank: r, currentRank: rank, c: c, l10n: l10n),
                      ),
                      const SizedBox(height: 20),
                      _TooltipCard(c: c, l10n: l10n),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.fallbackUser, required this.c});

  /// Datos mock — fallback cuando no hay sesión auth.
  final UserModel fallbackUser;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).valueOrNull;
    final authUser = authState is AuthAuthenticated ? authState.user : null;
    final metadata = authUser?.userMetadata ?? const <String, dynamic>{};
    final displayName = (metadata['full_name'] as String?) ??
        (metadata['name'] as String?) ??
        (metadata['display_name'] as String?) ??
        authUser?.email?.split('@').first ??
        fallbackUser.name;
    final displayEmail = authUser?.email ?? fallbackUser.email;
    final photoUrl = (metadata['avatar_url'] as String?) ??
        (metadata['picture'] as String?);

    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: 16,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          UserAvatar(
            name: displayName,
            photoUrl: photoUrl,
            accent: c.accent,
            size: 56,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: c.textHi,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  displayEmail,
                  style: TransitTypography.bodySecondary(c.textMid),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ReputationBadge(
                  fallbackUser.reputationLevel,
                  score: fallbackUser.reputationScore,
                ),
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
                    style: TextStyle(fontFamily: 'DM Sans', 
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
