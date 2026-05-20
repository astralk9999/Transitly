import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
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
    final height = isSmall ? 36.0 : 48.0;
    final fontSize = isSmall ? 11.0 : 13.0;
    final radius = BorderRadius.circular(14);

    Color bg;
    Color fg;
    Color borderColor;
    List<BoxShadow> shadows;

    if (isDanger) {
      bg = c.stateCancelled.withValues(alpha: 0.20);
      fg = c.stateCancelled;
      borderColor = c.stateCancelled.withValues(alpha: 0.40);
      shadows = [];
    } else if (isPrimary) {
      bg = c.accent;
      fg = Colors.white;
      borderColor = c.accent;
      shadows = [
        BoxShadow(
          color: c.accent.withValues(alpha: 0.35),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];
    } else {
      bg = isDark
          ? Colors.white.withValues(alpha: 0.10)
          : Colors.black.withValues(alpha: 0.06);
      fg = c.textHi;
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.15)
          : Colors.black.withValues(alpha: 0.12);
      shadows = [];
    }

    // GoogleFonts mantenido aquí por decisión: fontSize es dinámico
    // (isSmall? 11 : 13) y TransitTypography usa tamaños fijos. Es el
    // único GoogleFonts. restante en shared/widgets/ (10/11 migrados).
    final textStyle = GoogleFonts.ibmPlexMono(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: 1,
      color: fg,
    );

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: Pressable(
        onTap: disabled || isLoading ? null : onPressed,
        scale: 0.96,
        enabled: !disabled && !isLoading,
        child: Opacity(
          opacity: disabled ? 0.35 : 1.0,
          child: Container(
            height: height,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: radius,
              border: Border.all(color: borderColor, width: isPrimary ? 0 : 1),
              boxShadow: shadows,
            ),
            padding: EdgeInsets.symmetric(horizontal: isSmall ? 14 : 24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: fg,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, size: isSmall ? 15 : 17, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(label.toUpperCase(), style: textStyle),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
