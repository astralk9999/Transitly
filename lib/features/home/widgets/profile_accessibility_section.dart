import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileAccessibilitySection extends StatelessWidget {
  const ProfileAccessibilitySection({super.key});

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
            'ACCESIBILIDAD',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/accessibility'),
            child: Row(
              children: [
                Expanded(
                  child: Text('Modo: Ninguno',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textLo),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
