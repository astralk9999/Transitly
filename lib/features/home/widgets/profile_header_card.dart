import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reputation_badge.dart';

class ProfileHeaderCard extends StatelessWidget {
  const ProfileHeaderCard({super.key, required this.user});

  final UserModel user;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

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
                _initials(user.name),
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
                Text(
                  user.email,
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),
          ReputationBadge(user.reputationLevel),
        ],
      ),
    );
  }
}
