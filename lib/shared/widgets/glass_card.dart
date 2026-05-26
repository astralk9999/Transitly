import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';

/// Card with frosted glass aesthetic that works reliably across platforms.
/// Uses solid semi-transparent backgrounds instead of relying on BackdropFilter
/// which can fail on web and some desktop configurations.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.blur = 24.0,
    this.fillOpacity = 0.14,
    this.borderRadius = 16.0,
    this.borderOpacity = 0.20,
    this.padding,
    this.margin,
    this.useAccentBorder = false,
    this.accentColor,
  });

  final Widget child;
  final double blur;
  final double fillOpacity;
  final double borderRadius;
  final double borderOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useAccentBorder;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final bgColor = isDark ? c.glassBg : c.bgSurface;
    final borderColor = useAccentBorder && accentColor != null
        ? accentColor!.withValues(alpha: 0.30)
        : isDark
            ? c.glassBorder
            : c.border;

    Widget card = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: child,
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}
