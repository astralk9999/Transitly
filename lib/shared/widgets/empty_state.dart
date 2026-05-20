import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import 'glass_card.dart';
import 'gradient_text.dart';
import 'transit_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.subtitle, {
    super.key,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: TransitSpacing.space32),
        child: GlassCard(
          blur: 16,
          fillOpacity: 0.05,
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 48, color: c.accent),
                const SizedBox(height: TransitSpacing.space16),
              ],
              GradientText(
                title,
                style: TransitTypography.timeEstimate(Colors.white),
                gradient: c.gradientAccent,
              ),
              const SizedBox(height: TransitSpacing.space8),
              Text(
                subtitle,
                style: TransitTypography.bodyPrimary(c.textMid),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 24),
                TransitButton(
                  label: actionLabel!,
                  isPrimary: false,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
