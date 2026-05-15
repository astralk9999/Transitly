import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileAccessibilitySection extends ConsumerWidget {
  const ProfileAccessibilitySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = isDarkMode(ref, context);
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientText(
            l10n.profileSectionAccessibility,
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
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/offline-regions'),
            child: Row(
              children: [
                Icon(Icons.map_outlined, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  l10n.offlineRegionsMapLink,
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: c.accent),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/widgets'),
            child: Row(
              children: [
                Icon(Icons.widgets_outlined, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  l10n.widgetsTitle,
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: c.accent),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
