import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/transit_button.dart';

class ProfileAboutSection extends StatefulWidget {
  const ProfileAboutSection({super.key});

  @override
  State<ProfileAboutSection> createState() => _ProfileAboutSectionState();
}

class _ProfileAboutSectionState extends State<ProfileAboutSection> {
  int _aboutTapCount = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

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
          GestureDetector(
            onTap: () {},
            child: Text('Cerrar sesión',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showDeleteConfirmation(context, c),
            child: Text('Eliminar cuenta',
                style:
                    TransitTypography.bodySecondary(c.stateCancelled)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          '¿Eliminar cuenta?',
          style: TransitTypography.heading(c.textHi),
        ),
        content: Text(
          'Esta acción es irreversible. Se eliminarán todos tus datos, favoritos y contribuciones.',
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
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cuenta eliminada (demo)')),
              );
            },
          ),
        ],
      ),
    );
  }
}
