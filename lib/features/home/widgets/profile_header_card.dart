import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/auth/auth_repository.dart';
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

    final displayName = authUser?.userMetadata?['display_name'] as String? ??
        authUser?.email?.split('@').first ??
        user.name;
    final displayEmail = authUser?.email ?? user.email;
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
                  style: GoogleFonts.dmSans(
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
