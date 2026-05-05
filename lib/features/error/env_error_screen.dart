import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/env.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

/// Pantalla auto-suficiente para fallos de configuración de entorno.
///
/// Se monta como app raíz (sin `ProviderScope`, sin `MaterialApp.router`)
/// cuando `main()` no consigue cargar el `.env` o falta una clave
/// crítica. Su único trabajo es comunicar el problema al desarrollador
/// con instrucciones accionables.
class EnvErrorApp extends StatelessWidget {
  const EnvErrorApp({super.key, required this.exception});

  final EnvException exception;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(builder: (context) {
        const isDark = true;
        final c = TransitColorScheme.of(isDark);
        return Scaffold(
          backgroundColor: c.bgRoot,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, size: 48, color: c.stateCancelled),
                  const SizedBox(height: 24),
                  Text(
                    'CONFIGURACIÓN INCOMPLETA',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      color: c.stateCancelled,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'La app no puede arrancar porque falta una variable de entorno crítica.',
                    style: TransitTypography.bodyPrimary(c.textHi),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.bgSurface,
                      border: Border.all(color: c.border, width: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Error: ${exception.error.name}',
                            style: TransitTypography.bodySecondary(c.textMid)),
                        Text('Clave: ${exception.key}',
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 13, color: c.accent)),
                        if (exception.message != null) ...[
                          const SizedBox(height: 4),
                          Text(exception.message!,
                              style:
                                  TransitTypography.bodySecondary(c.textLo)),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '1. Copia .env.example a .env en la raíz del proyecto.\n'
                    '2. Rellena la clave que falta.\n'
                    '3. Reinicia la app (hot reload no recarga .env).',
                    style: TransitTypography.bodySecondary(c.textMid),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
