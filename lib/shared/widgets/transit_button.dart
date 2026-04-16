import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import 'pressable.dart';

class TransitButton extends StatelessWidget {
  const TransitButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isPrimary = true,
    this.isSmall = false,
    this.isDanger = false,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isSmall;
  final bool isDanger;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final disabled = onPressed == null;
    final height = isSmall ? TransitSpacing.heightBtnSmall : TransitSpacing.heightBtnPrimary;
    final fontSize = isSmall ? 12.0 : 14.0;

    Color bg;
    Color fg;
    Color borderColor;

    if (isDanger) {
      bg = Colors.transparent;
      fg = c.stateCancelled;
      borderColor = c.stateCancelled;
    } else if (isPrimary) {
      bg = c.accent;
      fg = c.bgRoot;
      borderColor = c.accent;
    } else {
      bg = Colors.transparent;
      fg = c.accent;
      borderColor = c.accent;
    }

    final textStyle = GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
      color: fg,
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: Pressable(
      onTap: disabled || isLoading ? null : onPressed,
      scale: 0.95,
      enabled: !disabled && !isLoading,
      child: Opacity(
        opacity: disabled ? 0.4 : 1.0,
        child: SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(TransitSpacing.radiusSm),
              border: Border.all(color: borderColor, width: TransitSpacing.strokeNormal),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: TransitSpacing.space16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: fg,
                      ),
                    )
                  else ...[
                    if (icon != null) ...[
                      Icon(icon, size: isSmall ? 16 : 18, color: fg),
                      const SizedBox(width: TransitSpacing.space8),
                    ],
                    Text(label.toUpperCase(), style: textStyle),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
