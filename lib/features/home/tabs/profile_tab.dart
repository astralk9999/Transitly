import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/providers/theme_provider.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/reputation_badge.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  bool _alertsOn = true;
  bool _busWarningOn = true;
  bool _remindersOn = false;
  int _aboutTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final c = TransitColorScheme.of(isDark);
    final isDriver = ref.watch(isDriverModeProvider);
    final user = ref.watch(currentUserProvider);

    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ContentConstraints(
        maxWidth: 600,
        child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(padding),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 1. HEADER ──
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: c.bgRaised,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials(user.name),
                          style: GoogleFonts.ibmPlexMono(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: c.textHi,
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

                _divider(c),

                // ── 2. APARIENCIA ──
                Text('APARIENCIA',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Modo oscuro',
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

                _divider(c),

                // ── 3. PERFIL DE DEMO ──
                Text('PERFIL DE DEMO',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text('Modo conductor',
                          style: TransitTypography.bodyPrimary(c.textHi)),
                    ),
                    Switch.adaptive(
                      value: isDriver,
                      activeTrackColor: c.accent,
                      onChanged: (v) {
                        ref.read(isDriverModeProvider.notifier).state = v;
                      },
                    ),
                  ],
                ),
                Text(
                  'Activa para ver las funciones de conductor',
                  style: TransitTypography.bodySmall(c.textLo),
                ),

                _divider(c),

                // ── 4. ZONA PRINCIPAL ──
                Text('ZONA PRINCIPAL',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: c.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Jerez de la Frontera',
                          style: TransitTypography.bodyPrimary(c.accent)),
                    ),
                    Icon(Icons.chevron_right, size: 20, color: c.textLo),
                  ],
                ),

                _divider(c),

                // ── 5. MIS FILTROS ──
                Text('MIS FILTROS',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),
                _filterItem(c, 'Solo accesibles'),
                const SizedBox(height: 6),
                _filterItem(c, 'Líneas favoritas'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/profile/filters'),
                  child: Text('GESTIONAR →',
                      style: TransitTypography.bodySecondary(c.accent)),
                ),

                _divider(c),

                // ── 6. MIS CONTRIBUCIONES ──
                Text('MIS CONTRIBUCIONES',
                    style: TransitTypography.sectionTitle(c.textMid)),
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

                _divider(c),

                // ── 7. DATOS OFFLINE ──
                Text(
                  'Jerez de la Frontera · 8.2 MB · Actualizado hace 1 día',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),

                _divider(c),

                // ── 8. NOTIFICACIONES ──
                Text('NOTIFICACIONES',
                    style: TransitTypography.sectionTitle(c.textMid)),
                const SizedBox(height: 12),
                _notifRow(c, 'Alertas de servicio', _alertsOn,
                    (v) => setState(() => _alertsOn = v)),
                _notifRow(c, 'Aviso de bus', _busWarningOn,
                    (v) => setState(() => _busWarningOn = v)),
                _notifRow(c, 'Recordatorios', _remindersOn,
                    (v) => setState(() => _remindersOn = v)),

                _divider(c),

                // ── 9. ACCESIBILIDAD ──
                Text('ACCESIBILIDAD',
                    style: TransitTypography.sectionTitle(c.textMid)),
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

                _divider(c),

                // ── 10. ACERCA DE ──
                Text(
                  'Transitly',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: c.accent,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () {
                    _aboutTapCount++;
                    if (_aboutTapCount >= 5) {
                      _aboutTapCount = 0;
                      context.push('/debug/showcase');
                    }
                  },
                  child: Text(
                    'v0.1.0-demo',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      color: c.textLo,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plataforma universal de transporte público',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),

                _divider(c),

                // ── 11. FOOTER ──
                GestureDetector(
                  onTap: () {},
                  child: Text('Cerrar sesión',
                      style: TransitTypography.bodySecondary(c.textMid)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {},
                  child: Text('Eliminar cuenta',
                      style:
                          TransitTypography.bodySecondary(c.stateCancelled)),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) return parts[0][0].toUpperCase();
    return '?';
  }

  Widget _divider(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, thickness: 0.5, color: c.border),
    );
  }

  Widget _filterItem(TransitColorScheme c, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TransitTypography.bodySecondary(c.textHi)),
    );
  }

  Widget _notifRow(
      TransitColorScheme c, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: TransitTypography.bodyPrimary(c.textHi)),
        ),
        Switch.adaptive(
          value: value,
          activeTrackColor: c.accent,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
