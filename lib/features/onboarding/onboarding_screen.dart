import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../shared/widgets/transit_button.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'PARECE QUE ESTÁS EN',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: c.textMid,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'JEREZ DE LA FRONTERA',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: c.accent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: TransitButton(
                  label: 'EMPEZAR',
                  onPressed: () => context.go('/home/inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
