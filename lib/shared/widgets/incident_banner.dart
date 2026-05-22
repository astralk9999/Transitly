import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';

class IncidentBanner extends ConsumerWidget {
  const IncidentBanner({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = message;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: c.stateDelay.withValues(alpha: 0.15),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: c.stateDelay, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TransitTypography.bodySmall(c.stateDelay),
            ),
          ),
        ],
      ),
    );
  }
}
