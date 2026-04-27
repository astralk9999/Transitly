import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';

class RouteDetailChangelog extends StatelessWidget {
  const RouteDetailChangelog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('CAMBIOS RECIENTES',
              style: TransitTypography.sectionTitle(c.textMid)),
        ),
        const SizedBox(height: 8),
        _item(c, Icons.edit, '12/03', 'Horario actualizado para días laborables'),
        _item(c, Icons.add_location, '28/02', 'Añadida parada Esteve'),
        _item(c, Icons.verified, '15/02', 'Ruta verificada por la comunidad'),
      ],
    );
  }

  Widget _item(
      TransitColorScheme c, IconData icon, String date, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.textMid),
          const SizedBox(width: 8),
          Text(date, style: TransitTypography.bodySecondary(c.textLo)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              desc,
              style: TransitTypography.bodySecondary(c.textHi),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
