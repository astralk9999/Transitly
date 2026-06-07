import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';

class OperatorDashboardScreen extends ConsumerWidget {
  const OperatorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).operatorPanelTitle,
                      style: TransitTypography.heading(c.textHi)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context).operatorPanelSubtitle,
                      style: TransitTypography.bodySecondary(c.textMid)),
                  const SizedBox(height: 24),

                  _OptionCard(
                    c: c,
                    icon: Icons.vpn_key,
                    title: 'Códigos de invitación',
                    subtitle: 'Genera y gestiona códigos para conductores',
                    onTap: () =>
                        context.push('/operator-admin/invitation-codes'),
                  ),
                  const SizedBox(height: 12),

                  _OptionCard(
                    c: c,
                    icon: Icons.people,
                    title: 'Conductores',
                    subtitle: 'Lista de conductores asignados',
                    onTap: () => context.push('/operator-admin/drivers'),
                  ),
                  const SizedBox(height: 12),

                  _OptionCard(
                    c: c,
                    icon: Icons.alt_route,
                    title: 'Gestión de líneas',
                    subtitle:
                        'Editar rutas, paradas y horarios de tu operadora',
                    onTap: () => context.push('/management/routes'),
                  ),
                  const SizedBox(height: 12),

                  _OptionCard(
                    c: c,
                    icon: Icons.place_outlined,
                    title: 'Gestión de paradas',
                    subtitle: 'Ver, crear y editar paradas de tu operadora',
                    onTap: () => context.push('/management/stops'),
                  ),
                  const SizedBox(height: 12),

                  _OptionCard(
                    c: c,
                    icon: Icons.inbox,
                    title: 'Bandeja',
                    subtitle:
                        'Mejoras, incidencias y sugerencias de tus líneas',
                    onTap: () => context.push('/management/inbox'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.c,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final TransitColorScheme c;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Row(
          children: [
            Icon(icon, color: c.accent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TransitTypography.bodySecondary(c.textMid)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textLo),
          ],
        ),
      ),
    );
  }
}
