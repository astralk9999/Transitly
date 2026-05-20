import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import 'transit_button.dart';

class ErrorCard extends StatelessWidget {
  const ErrorCard(this.message, {super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Container(
            width: 2,
            height: 40,
            color: c.stateCancelled,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ERROR · $message',
                  style: TransitTypography.errorText(c.textMid),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  TransitButton(
                    label: 'REINTENTAR',
                    isPrimary: false,
                    isSmall: true,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
