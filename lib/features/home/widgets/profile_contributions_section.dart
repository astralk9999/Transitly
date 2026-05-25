import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/reputation_badge.dart';

class ProfileContributionsSection extends StatelessWidget {
  const ProfileContributionsSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            'MIS CONTRIBUCIONES',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ReputationBadge(user.reputationLevel),
              const SizedBox(width: 12),
              Text('12 reportes · 3 verificadas',
                  style: TransitTypography.bodySecondary(c.textMid)),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/contributions'),
            child: Text('VER TODO →',
                style: TransitTypography.bodySecondary(c.accent)),
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: c.border,
          ),
          Text(
            'Jerez de la Frontera · 8.2 MB · Actualizado hace 1 día',
            style: TransitTypography.bodySecondary(c.textMid),
          ),
        ],
      ),
    );
  }
}
