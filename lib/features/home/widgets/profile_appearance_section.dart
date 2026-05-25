import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/is_dark_provider.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';

class ProfileAppearanceSection extends ConsumerWidget {
  const ProfileAppearanceSection({super.key});

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
            l10n.profileSectionAppearance,
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
              Expanded(
                child: Text(l10n.profileDarkMode,
                    style: TransitTypography.bodyPrimary(c.textHi)),
              ),
              Text(
                isDark ? 'OSCURO' : 'CLARO',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  color: c.textMid,
                ),
              ),
              const SizedBox(width: 8),
              Switch.adaptive(
                value: isDark,
                activeTrackColor: c.accent,
                onChanged: (v) {
                  ref.read(themeModeProvider.notifier).state =
                      v ? ThemeMode.dark : ThemeMode.light;
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/appearance'),
            child: Row(
              children: [
                Icon(Icons.palette_outlined, size: 18, color: c.accent),
                const SizedBox(width: 8),
                Text(
                  l10n.appearanceLinkAppearance,
                  style: TransitTypography.bodyPrimary(c.accent),
                ),
                const Spacer(),
                Icon(Icons.chevron_right, size: 20, color: c.accent),
              ],
            ),
          ),
          // El toggle "PERFIL DEMO → modo conductor" se eliminó: el modo
          // conductor solo debe activarse via flujo de activación verificado
          // (/activate-driver) tras autenticarse. Un switch público de demo
          // confunde y permite acceder a UI de conductor sin verificación.
        ],
      ),
    );
  }
}
