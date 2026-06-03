import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reputation_badge.dart';

class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key, required this.user});

  final UserModel user;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final authUser = authState is AuthAuthenticated ? authState.user : null;

    // Modo invitado: no usar datos mock — mostrar CTA para iniciar sesión.
    if (authUser == null) {
      final l10n = AppLocalizations.of(context);
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
              child: Icon(Icons.person_outline, color: c.accent, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileGuestLabel,
                    style: TransitTypography.sectionLabel(c.accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileGuestCta,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/sign-in'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: c.accent.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  l10n.profileGuestSignIn,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final displayName = authUser.userMetadata?['display_name'] as String? ??
        authUser.email?.split('@').first ??
        user.name;
    final displayEmail = authUser.email ?? user.email;
    final initials = _initials(displayName);

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
                  displayName,
                  style: TextStyle(fontFamily: 'DM Sans', 
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: c.textHi,
                  ),
                ),
                Text(
                  displayEmail,
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => context.push('/profile/reputation'),
            child: ReputationBadge(user.reputationLevel,
                score: user.reputationScore),
          ),
        ],
      ),
    );
  }
}
