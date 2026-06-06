import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../data/auth/auth_repository.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/reputation_badge.dart';
import '../../../shared/widgets/user_avatar.dart';

class ProfileHeaderCard extends ConsumerWidget {
  const ProfileHeaderCard({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final authState = ref.watch(authStateProvider).valueOrNull;
    final authUser = authState is AuthAuthenticated ? authState.user : null;

    // Modo invitado: no usar datos mock — mostrar CTA para iniciar sesión.
    if (authUser == null) {
      final l10n = AppLocalizations.of(context);
      return GlassCard(
        blur: 20,
        fillOpacity: 0.06,
        borderRadius: 16,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            UserAvatar(name: '', accent: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.profileGuestLabel,
                    style: TransitTypography.sectionLabel(c.accent),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.profileGuestCta,
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/sign-in'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: c.accent.withValues(alpha: 0.4), width: 0.5),
                ),
                child: Text(
                  l10n.profileGuestSignIn,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final metadata = authUser.userMetadata ?? const <String, dynamic>{};
    final displayName = (metadata['full_name'] as String?) ??
        (metadata['name'] as String?) ??
        (metadata['display_name'] as String?) ??
        authUser.email?.split('@').first ??
        user.name;
    final displayEmail = authUser.email ?? user.email;
    final photoUrl = (metadata['avatar_url'] as String?) ??
        (metadata['picture'] as String?);

    // Toda la card es tappable y abre la pantalla de reputación.
    // Antes solo el badge de reputación a la derecha era tappable, lo
    // cual hacía la entrada al perfil/reputación poco accesible.
    return Semantics(
      button: true,
      label: 'Abrir perfil y reputación',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push('/profile/reputation'),
        child: GlassCard(
          blur: 20,
          fillOpacity: 0.06,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              UserAvatar(
                name: displayName,
                photoUrl: photoUrl,
                accent: c.accent,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontFamily: 'DM Sans',
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: c.textHi,
                      ),
                    ),
                    Text(
                      displayEmail,
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ],
                ),
              ),
              // Badge compacto (icono + número, sin label del rango)
              // para no comerle ancho al email/nombre.
              ReputationBadge(
                user.reputationLevel,
                score: user.reputationScore,
                compact: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
