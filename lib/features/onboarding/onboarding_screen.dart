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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0.0, -0.4),
            radius: 1.3,
            colors: [
              c.accent.withValues(alpha: 0.15),
              c.bgRoot,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Icono de bus
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: c.accent.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 36,
                    color: c.accent,
                  ),
                ),

                const SizedBox(height: 36),

                // Subtitulo
                Text(
                  'PARECE QUE ESTAS EN',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: c.textMid,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 14),

                // Ciudad
                Text(
                  'JEREZ DE LA\nFRONTERA',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.2,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 20),

                // Descripcion
                Text(
                  'Tu companero de transporte urbano.\nHorarios, rutas y paradas en tiempo real.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: c.textMid,
                    height: 1.6,
                  ),
                ),

                const Spacer(flex: 2),

                // Linea decorativa
                Container(
                  width: 40,
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: c.accent,
                  ),
                ),

                const SizedBox(height: 32),

                // Boton
                SizedBox(
                  width: double.infinity,
                  child: TransitButton(
                    label: 'EMPEZAR',
                    onPressed: () => context.go('/home/inicio'),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
