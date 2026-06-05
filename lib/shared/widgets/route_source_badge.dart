import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/enums.dart';

/// Sub P1.5-07: badge que distingue rutas oficiales vs comunidad.
///
/// - Official: badge dorado con icono verificado + "Oficial · {operadorName}".
/// - Community: badge gris con icono usuario + "Comunidad · {ownerName}".
class RouteSourceBadge extends StatelessWidget {
  const RouteSourceBadge({
    super.key,
    required this.source,
    this.operatorName,
    this.ownerName,
    this.compact = false,
  });

  final RouteSource source;
  final String? operatorName;
  final String? ownerName;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final (color, icon, label) = switch (source) {
      RouteSource.official => (
        const Color(0xFFD4A017),
        Icons.verified_rounded,
        operatorName != null ? 'Oficial · $operatorName' : 'Oficial',
      ),
      RouteSource.community => (
        c.textMid,
        Icons.people_alt_outlined,
        ownerName != null ? 'Comunidad · $ownerName' : 'Comunidad',
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 12 : 14, color: color),
          SizedBox(width: compact ? 4 : 6),
          Text(
            label,
            style: (compact
                    ? TransitTypography.bodySmall(color)
                    : TransitTypography.bodySecondary(color))
                .copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
