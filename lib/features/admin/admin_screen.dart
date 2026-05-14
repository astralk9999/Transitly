import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          Column(
            children: [
              const TransitAppBar(title: 'Administración'),
              Expanded(
                child: RoleGate(
                  allow: const [UserRole.admin],
                  fallback: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Acceso restringido',
                        style: TransitTypography.heading(c.textMid),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Panel de administración',
                              style: TransitTypography.heading(c.textHi)),
                          const SizedBox(height: 8),
                          Text('Gestiona la plataforma',
                              style:
                                  TransitTypography.bodySecondary(c.textMid)),
                          const SizedBox(height: 24),
                          _OptionCard(
                            c: c,
                            icon: Icons.people,
                            title: 'Gestionar usuarios',
                            subtitle: 'Administrar cuentas y roles',
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.business,
                            title: 'Gestionar operadores',
                            subtitle: 'Supervisar empresas de transporte',
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.inbox,
                            title: 'Bandeja de moderación',
                            subtitle: 'Revisar reportes y contenido',
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
  });

  final TransitColorScheme c;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 16,
      fillOpacity: 0.05,
      borderRadius: 14,
      padding: const EdgeInsets.all(16),
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
    );
  }
}
