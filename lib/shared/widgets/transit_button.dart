import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';

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

    return Opacity(
      opacity: disabled ? 0.4 : 1.0,
      child: SizedBox(
        height: height,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: BorderSide(color: borderColor, width: 1),
          ),
          child: InkWell(
            onTap: disabled || isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(4),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      const SizedBox(width: 8),
                    ],
                    Text(label.toUpperCase(), style: textStyle),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
