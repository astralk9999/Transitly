import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import 'transit_button.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.subtitle, {
    super.key,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: c.textLo,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
    );
  }
}
