import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class DriverPanel extends StatelessWidget {
  const DriverPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 32,
              height: 4,
              decoration: BoxDecoration(
                color: c.textLo,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'MODO CONDUCTOR',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c.accent,
                  ),
                ),
                const Spacer(),
                Text(
                  'COMUJESA · Ana Martín',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Divider(height: 1, thickness: 0.5, color: c.border),
          ),

          // Options
          _option(context, c, Icons.play_arrow, 'Iniciar ruta', '/driver/start'),
          _option(context, c, Icons.route, 'Ruta activa', '/driver/active'),
          _option(context, c, Icons.edit, 'Crear ruta manual', '/driver/editor/manual'),
          _option(context, c, Icons.fiber_manual_record, 'Crear ruta en vivo', '/driver/editor/live'),
          _option(context, c, Icons.history, 'Mis rutas', '/driver/history'),
          _option(context, c, Icons.schedule, 'Importar horarios', '/driver/ai-import'),
          _option(context, c, Icons.inbox, 'Bandeja de gestión', '/driver/stats'),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, TransitColorScheme c, IconData icon,
      String label, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        context.push(route);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: c.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TransitTypography.bodyPrimary(c.textHi)),
            ),
            Icon(Icons.chevron_right, size: 20, color: c.textLo),
          ],
        ),
      ),
    );
  }
}
