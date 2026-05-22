import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class ContextualHelpButton extends StatelessWidget {
  const ContextualHelpButton({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.help_outline,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return IconButton(
      icon: Icon(icon, color: c.textMid, size: 20),
      tooltip: title,
      onPressed: () => _showHelp(context, c),
    );
  }

  void _showHelp(BuildContext context, TransitColorScheme c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: c.accent, size: 24),
            const SizedBox(width: 10),
            Text(title, style: TransitTypography.subheading(c.textHi)),
          ],
        ),
        content: Text(message, style: TransitTypography.bodyPrimary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TransitTypography.bodyPrimary(c.accent),
            ),
          ),
        ],
      ),
    );
  }
}
