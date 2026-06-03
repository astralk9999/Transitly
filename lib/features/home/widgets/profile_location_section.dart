import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileLocationSection extends StatelessWidget {
  const ProfileLocationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
            l10n.profileZoneTitle,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/city-picker'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(l10n.profileZoneLocation,
                      style: TransitTypography.bodyPrimary(c.accent)),
                ),
                Icon(Icons.chevron_right, size: 20, color: c.textLo),
              ],
            ),
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: c.border,
          ),
          GradientText(
            l10n.profileZoneFilters,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          _FilterItem(label: l10n.profileZoneAccessible, color: c),
          const SizedBox(height: 6),
          _FilterItem(label: l10n.profileZoneFavLines, color: c),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.push('/profile/filters'),
            child: Text(l10n.profileZoneManageArrow,
                style: TransitTypography.bodySecondary(c.accent)),
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: c.border,
          ),
          GradientText(
            l10n.profileZoneOffline,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/profile/offline'),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                Icon(Icons.cloud_download_outlined,
                    size: 16, color: c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.profileZoneCacheDesc,
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
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

class _FilterItem extends StatelessWidget {
  const _FilterItem({required this.label, required this.color});

  final String label;
  final TransitColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.accent.withValues(alpha: 0.08),
        border: Border.all(
            color: color.accent.withValues(alpha: 0.15), width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TransitTypography.bodySecondary(color.textHi)),
    );
  }
}
