import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import 'pressable.dart';

class TransitChip extends StatelessWidget {
  const TransitChip(this.code, {super.key, this.color, this.onTap});

  final String code;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final fg = color ?? c.accent;

    final chip = Container(
      padding: TransitSpacing.paddingChip,
      constraints: const BoxConstraints(minHeight: TransitSpacing.minTapTarget),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border.all(color: c.border, width: TransitSpacing.strokeThin),
        borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
      ),
      alignment: Alignment.center,
      child: Text(
        code,
        style: TransitTypography.routeCodeSmall(fg),
      ),
    );

    if (onTap != null) {
      return Pressable(onTap: onTap, child: chip);
    }
    return chip;
  }
}
