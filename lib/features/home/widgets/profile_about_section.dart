import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/analytics/posthog_service.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../data/supabase/supabase_client_provider.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/role_gate.dart';
import '../../../shared/widgets/transit_button.dart';

class ProfileAboutSection extends ConsumerStatefulWidget {
  const ProfileAboutSection({super.key});

  @override
  ConsumerState<ProfileAboutSection> createState() =>
      _ProfileAboutSectionState();
}

class _ProfileAboutSectionState extends ConsumerState<ProfileAboutSection> {
  int _aboutTapCount = 0;

  void _showSignOutConfirmation(BuildContext context, TransitColorScheme c) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.profileSignOutConfirmTitle,
          style: TransitTypography.heading(c.textHi),
        ),
        content: Text(
          l10n.profileSignOutConfirmMessage,
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TransitButton(
            label: l10n.actionCancel.toUpperCase(),
            isPrimary: false,
            isSmall: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TransitButton(
            label: l10n.actionSignOut.toUpperCase(),
            isSmall: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/sign-in');
              PostHogAnalyticsService.signout();
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TransitColorScheme c) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          l10n.privacyDeleteConfirmTitle,
          style: TransitTypography.heading(c.textHi),
        ),
        content: Text(
          l10n.privacyDeleteConfirmMessage,
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TransitButton(
            label: l10n.privacyDeleteConfirmCancel,
            isPrimary: false,
            isSmall: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TransitButton(
            label: l10n.privacyDeleteConfirmAction,
            isDanger: true,
            isSmall: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              // El borrado real es una solicitud diferida (30 días) vía
              // `data_deletion_requests` — el mismo flujo que la pantalla
              // de Privacidad. No se usa la admin API (requiere
              // service_role; inaccesible desde el cliente).
              final authState = ref.read(authStateProvider).valueOrNull;
              if (authState is! AuthAuthenticated) return;
              try {
                await ref.read(supabaseClientProvider)
                    .from('data_deletion_requests')
                    .insert({
                  'user_id': authState.user.id,
                  'status': 'requested',
                  'requested_at':
                      DateTime.now().toUtc().toIso8601String(),
                  'scheduled_at': DateTime.now()
                      .toUtc()
                      .add(const Duration(days: 30))
                      .toIso8601String(),
                });
                await ref.read(authRepositoryProvider).signOut();
                PostHogAnalyticsService.signout();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.privacyDeletionRequested)),
                  );
                  context.go('/sign-in');
                }
              } catch (e) {
                AppLogger.warn('ProfileAbout', 'delete account failed', e);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.authDeleteAccountError)),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final isAuth = authState is AuthAuthenticated;
    final user = ref.watch(currentUserProvider);
    final isPassenger = user.role == UserRole.passenger;
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
            'Transitly',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            gradient: c.gradientAccent,
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              if (kReleaseMode) return;
              _aboutTapCount++;
              if (_aboutTapCount >= 5) {
                _aboutTapCount = 0;
                context.push('/debug/showcase');
              }
            },
            child: Text(
              'v1.0.0',
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                color: c.textLo,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.appTagline,
            style: TransitTypography.bodySecondary(c.textMid),
          ),
          Divider(
            height: 24,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          if (isAuth) ...[
            RoleGate(
              allow: const [UserRole.admin],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.profileAdminSectionTitle,
                      style: TransitTypography.sectionTitle(c.accent)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => context.push('/admin'),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings,
                            size: 20, color: c.accent),
                        const SizedBox(width: 12),
                        Text(l10n.adminPanelTitle,
                            style:
                                TransitTypography.bodyPrimary(c.textHi)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ],
              ),
            ),
            if (isPassenger) ...[
              GestureDetector(
                onTap: () => context.go('/activate-driver'),
                child: Text(l10n.profileBecomeDriver,
                    style: TransitTypography.bodySecondary(c.accent)),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () => _showSignOutConfirmation(context, c),
              child: Text(l10n.actionSignOut,
                  style: TransitTypography.bodySecondary(c.textMid)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push('/profile/privacy'),
              child: Text(l10n.privacyLinkLabel,
                  style: TransitTypography.bodySecondary(c.accent)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context, c),
              child: Text(l10n.profileDeleteAccount,
                  style: TransitTypography.bodySecondary(c.stateCancelled)),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => context.go('/sign-in'),
              child: Text(l10n.actionSignIn,
                  style: TransitTypography.bodySecondary(c.accent)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.go('/sign-up'),
              child: Text(l10n.profileCreateAccount,
                  style: TransitTypography.bodySecondary(c.textMid)),
            ),
          ],
        ],
      ),
    );
  }
}
