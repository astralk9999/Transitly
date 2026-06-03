import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/providers/my_contributions_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/reputation_badge.dart';

class ProfileContributionsSection extends ConsumerWidget {
  const ProfileContributionsSection({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    // Conteos reales desde Supabase. Sin sesión devuelve 0.
    final statsAsync = ref.watch(myContributionsProvider);
    final verifiedAsync = ref.watch(myContributionsVerifiedProvider);

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
              Expanded(
                child: statsAsync.when(
                  data: (stats) {
                    final verified = verifiedAsync.valueOrNull ?? 0;
                    return Text(
                      '${stats.total} contribuciones · $verified verificadas',
                      style: TransitTypography.bodySecondary(c.textMid),
                    );
                  },
                  loading: () => Text(
                    'Cargando…',
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                  error: (_, __) => Text(
                    '— contribuciones',
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Mini desglose por categoría — datos reales.
          statsAsync.when(
            data: (stats) => Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _StatChip(
                    icon: Icons.report_outlined,
                    label: 'Reportes',
                    count: stats.incidents,
                    c: c),
                _StatChip(
                    icon: Icons.alt_route_outlined,
                    label: 'Rutas sugeridas',
                    count: stats.suggestions,
                    c: c),
                _StatChip(
                    icon: Icons.edit_note_outlined,
                    label: 'Feedback',
                    count: stats.feedback,
                    c: c),
                _StatChip(
                    icon: Icons.lightbulb_outline,
                    label: 'Funciones',
                    count: stats.featureRequests,
                    c: c),
                _StatChip(
                    icon: Icons.share_outlined,
                    label: 'Compartidas',
                    count: stats.routeShares,
                    c: c),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
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

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.c,
  });

  final IconData icon;
  final String label;
  final int count;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.bgRaised.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.accent),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: c.textHi,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }
}
