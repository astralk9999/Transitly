import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../features/auth/auth_provider.dart';
import '../../../features/auth/auth_repository.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '¿Cerrar sesión?',
          style: TransitTypography.heading(c.textHi),
        ),
        content: Text(
          'Volverás a la pantalla de inicio de sesión.',
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TransitButton(
            label: 'CANCELAR',
            isPrimary: false,
            isSmall: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TransitButton(
            label: 'CERRAR SESIÓN',
            isSmall: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authRepositoryProvider).signOut();
              if (context.mounted) context.go('/sign-in');
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, TransitColorScheme c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '¿Eliminar cuenta?',
          style: TransitTypography.heading(c.textHi),
        ),
        content: Text(
          'Esta acción es irreversible.',
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TransitButton(
            label: 'CANCELAR',
            isPrimary: false,
            isSmall: true,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TransitButton(
            label: 'ELIMINAR',
            isDanger: true,
            isSmall: true,
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await ref.read(authRepositoryProvider).deleteAccount();
                if (context.mounted) context.go('/sign-in');
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('No se pudo eliminar la cuenta')),
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
          Divider(
            height: 24,
            thickness: 0.5,
            color: Colors.white.withValues(alpha: 0.06),
          ),
          if (isAuth) ...[
            if (isPassenger) ...[
              GestureDetector(
                onTap: () => context.go('/activate-driver'),
                child: Text('Activar modo conductor',
                    style: TransitTypography.bodySecondary(c.accent)),
              ),
              const SizedBox(height: 8),
            ],
            GestureDetector(
              onTap: () => _showSignOutConfirmation(context, c),
              child: Text('Cerrar sesión',
                  style: TransitTypography.bodySecondary(c.textMid)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _showDeleteConfirmation(context, c),
              child: Text('Eliminar cuenta',
                  style: TransitTypography.bodySecondary(c.stateCancelled)),
            ),
          ] else ...[
            GestureDetector(
              onTap: () => context.go('/sign-in'),
              child: Text('Iniciar sesión',
                  style: TransitTypography.bodySecondary(c.accent)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.go('/sign-up'),
              child: Text('Crear cuenta',
                  style: TransitTypography.bodySecondary(c.textMid)),
            ),
          ],
        ],
      ),
    );
  }
}
