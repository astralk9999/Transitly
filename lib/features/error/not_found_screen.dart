import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../shared/widgets/transit_button.dart';

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: TransitSpacing.space32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wrong_location_outlined, size: 56, color: c.textLo),
              const SizedBox(height: TransitSpacing.space16),
              Text(
                '404',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: c.textLo,
                ),
              ),
              const SizedBox(height: TransitSpacing.space8),
              Text(
                'Página no encontrada',
                style: TransitTypography.bodyPrimary(c.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: TransitSpacing.space24),
              TransitButton(
                label: 'IR AL INICIO',
                onPressed: () => context.go('/home/inicio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
