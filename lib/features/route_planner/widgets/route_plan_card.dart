import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/glass_card.dart';
import '../route_plan_models.dart';

class RoutePlanCard extends StatelessWidget {
  const RoutePlanCard({
    super.key,
    required this.result,
    this.onTap,
  });

  final RoutePlanResult result;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final headerText = '${result.totalMinutes} min · ${result.transfers} '
        '${result.transfers == 1 ? 'transbordo' : 'transbordos'}';

    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: TransitSpacing.radiusLg,
        padding: const EdgeInsets.all(TransitSpacing.space12),
        margin: const EdgeInsets.only(bottom: TransitSpacing.space12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              headerText,
              style: TransitTypography.routeName(c.accent),
            ),
            const SizedBox(height: TransitSpacing.space8),
            for (var i = 0; i < result.legs.length; i++) ...[
              _LegRow(leg: result.legs[i], c: c),
              if (i < result.legs.length - 1) ...[
                const SizedBox(height: TransitSpacing.space8),
                _TransferRow(
                  transferStopName: result.legs[i].alightStop.name,
                  c: c,
                ),
                const SizedBox(height: TransitSpacing.space8),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _LegRow extends StatelessWidget {
  const _LegRow({required this.leg, required this.c});

  final RoutePlanLeg leg;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    // Responsive: paradas en columna con flecha vertical para no
    // truncar en pantallas estrechas. Antes era una línea
    // "origen → destino" con TextOverflow.ellipsis y se cortaba.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: TransitSpacing.space8,
            vertical: TransitSpacing.space4,
          ),
          decoration: BoxDecoration(
            color: leg.route.routeColor.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
            border: Border.all(
              color: leg.route.routeColor.withValues(alpha: 0.40),
              width: TransitSpacing.strokeThin,
            ),
          ),
          child: Text(
            leg.route.code,
            style: TransitTypography.routeCodeSmall(
              leg.route.routeColor,
            ),
          ),
        ),
        const SizedBox(width: TransitSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Parada origen.
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(color: c.accent, width: 1.5),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leg.boardStop.name,
                      style: TransitTypography.routeName(c.textHi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Línea vertical + número de paradas.
              Padding(
                padding: const EdgeInsets.only(left: 3.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 1,
                      height: 22,
                      color: c.accent.withValues(alpha: 0.4),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${leg.stopsBetween} paradas · ${leg.estimatedMinutes} min',
                        style: TransitTypography.bodySmall(c.textMid),
                      ),
                    ),
                  ],
                ),
              ),
              // Parada destino.
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      leg.alightStop.name,
                      style: TransitTypography.routeName(c.textHi),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({required this.transferStopName, required this.c});

  final String transferStopName;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: TransitSpacing.space4),
        Icon(Icons.swap_horiz, size: 18, color: c.accent),
        const SizedBox(width: TransitSpacing.space8),
        Expanded(
          child: Text(
            'Cambia en $transferStopName',
            style: TransitTypography.bodySmall(c.accent),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
