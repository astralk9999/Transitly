import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/user_provider.dart' show currentUserProvider, userProfileFromSupabaseProvider;
import '../../../shared/widgets/responsive_scaffold.dart';
import '../widgets/profile_about_section.dart';
import '../widgets/profile_accessibility_section.dart';
import '../widgets/profile_appearance_section.dart';
import '../widgets/profile_contributions_section.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_location_section.dart';
import '../widgets/profile_notifications_section.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  void initState() {
    super.initState();
    // Refresca el perfil al entrar para mostrar XP/level actualizados.
    // El FutureProvider cachea para toda la sesión por defecto.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.invalidate(userProfileFromSupabaseProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final padding = ResponsiveScaffold.screenPadding(context);
    final isAuthenticated =
        ref.watch(authStateProvider).valueOrNull is AuthAuthenticated;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContentConstraints(
        maxWidth: 600,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ProfileHeaderCard(user: user),
                    const SizedBox(height: 16),
                    const ProfileAppearanceSection(),
                    const SizedBox(height: 16),
                    const ProfileLocationSection(),
                    // Contribuciones solo tras autenticar — sin login no hay
                    // datos reales y mostrar mock confunde al usuario.
                    if (isAuthenticated) ...[
                      const SizedBox(height: 16),
                      ProfileContributionsSection(user: user),
                    ],
                    const SizedBox(height: 16),
                    const ProfileNotificationsSection(),
                    const SizedBox(height: 16),
                    const ProfileAccessibilitySection(),
                    const SizedBox(height: 16),
                    GlassCard(
                      blur: 16,
                      fillOpacity: 0.05,
                      borderRadius: 14,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientText(
                            'Comunidad',
                            style: GoogleFonts.ibmPlexMono(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                            gradient: c.gradientAccent,
                          ),
                          const SizedBox(height: 12),
                          if (isAuthenticated) ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.route_outlined,
                                  size: 24, color: c.accent),
                              title: Text('Mis rutas',
                                  style: TransitTypography.bodyPrimary(
                                      c.textHi)),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textMid),
                              onTap: () =>
                                  context.push('/my-routes'),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.explore_outlined,
                                  size: 24, color: c.accent),
                              title: Text('Explorar comunidad',
                                  style: TransitTypography.bodyPrimary(
                                      c.textHi)),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textMid),
                              onTap: () =>
                                  context.push('/community'),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  Icon(Icons.add_location_alt_outlined,
                                      size: 24, color: c.accent),
                              title: Text('Crear nueva ruta',
                                  style: TransitTypography.bodyPrimary(
                                      c.textHi)),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textMid),
                              onTap: () =>
                                  context.push('/create-route'),
                            ),
                          ] else ...[
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.explore_outlined,
                                  size: 24, color: c.accent),
                              title: Text('Explorar comunidad',
                                  style: TransitTypography.bodyPrimary(
                                      c.textHi)),
                              subtitle: Text(
                                  'Inicia sesión para crear rutas',
                                  style: TransitTypography.bodySecondary(
                                      c.textMid)),
                              trailing: Icon(Icons.chevron_right,
                                  color: c.textMid),
                              onTap: () =>
                                  context.push('/community'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const ProfileAboutSection(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
