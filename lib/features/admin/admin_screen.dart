import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      // appBar: deja a Material gestionar el padding del status bar
      // (consistente con todas las pantallas que también usan este
      // patrón). Antes el TransitAppBar iba en el body con SafeAreas
      // distintos por pantalla, lo que daba alturas dispares.
      appBar: const TransitAppBar(
          title: 'Administración', transparent: true),
      body: RoleGate(
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
                          Text(AppLocalizations.of(context).adminPanelTitle,
                              style: TransitTypography.heading(c.textHi)),
                          const SizedBox(height: 8),
                          Text(AppLocalizations.of(context).adminPanelSubtitle,
                              style:
                                  TransitTypography.bodySecondary(c.textMid)),
                          const SizedBox(height: 24),
                          _OptionCard(
                            c: c,
                            icon: Icons.people,
                            title: 'Gestionar usuarios',
                            subtitle: 'Administrar cuentas y roles',
                            onTap: () => context.push('/admin/users'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.business,
                            title: 'Gestionar operadores',
                            subtitle: 'Supervisar empresas de transporte',
                            onTap: () => context.push('/admin/operators'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.inbox,
                            title: 'Bandeja',
                            subtitle:
                                'Mejoras, incidencias, sugerencias, zonas, operadores y RGPD en un solo sitio',
                            onTap: () => context.push('/management/inbox'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.location_on_outlined,
                            title: 'Avisos geo',
                            subtitle: 'Anunciar en zona con radio',
                            onTap: () => context.push('/admin/geo-alerts'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.alt_route,
                            title: 'Gestión de líneas',
                            subtitle:
                                'Editar rutas, paradas y horarios de cualquier operador',
                            onTap: () =>
                                context.push('/management/routes'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.place_outlined,
                            title: 'Gestión de paradas',
                            subtitle:
                                'Ver, crear y editar paradas de cualquier operador',
                            onTap: () => context.push('/management/stops'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.groups_outlined,
                            title: 'Gestión de comunidad',
                            subtitle:
                                'Rutas de la comunidad: revisar y oficializar',
                            onTap: () =>
                                context.push('/management/community'),
                          ),
                          const SizedBox(height: 12),
                          _OptionCard(
                            c: c,
                            icon: Icons.map_outlined,
                            title: 'Gestión de zonas',
                            subtitle:
                                'Zonas con perímetro (centro y radio) para perfil y mapa',
                            onTap: () => context.push('/management/zones'),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
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
    final card = GlassCard(
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

    if (onTap != null) {
      return Pressable(onTap: onTap, child: card);
    }
    return card;
  }
}
