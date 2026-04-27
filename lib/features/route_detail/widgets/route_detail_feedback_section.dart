import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/widgets/transit_button.dart';

class RouteDetailFeedbackSection extends StatelessWidget {
  const RouteDetailFeedbackSection({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 0.5, color: c.border),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgRaised,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '¿Esta información es correcta?',
                  style: TransitTypography.bodySecondary(c.textMid),
                ),
              ),
              Tooltip(
                message: 'Confirmar información',
                child: IconButton(
                  icon: Icon(Icons.thumb_up_outlined,
                      size: 20, color: c.accent),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('¡Gracias por confirmar!')),
                    );
                  },
                ),
              ),
              Tooltip(
                message: 'Reportar problema',
                child: IconButton(
                  icon: Icon(Icons.thumb_down_outlined,
                      size: 20, color: c.textMid),
                  onPressed: () => context.push('/feedback/$routeId'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TransitButton(
            label: '¿ALGO NO ESTÁ BIEN?',
            isPrimary: false,
            icon: Icons.chat_bubble_outline,
            onPressed: () => context.push('/feedback/$routeId'),
          ),
        ),
      ],
    );
  }
}
