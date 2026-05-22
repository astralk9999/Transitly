import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';

class RegionStatusBadge extends StatelessWidget {
  const RegionStatusBadge({
    super.key,
    required this.isDownloading,
    required this.progress,
    required this.c,
  });

  final bool isDownloading;
  final double progress;
  final TransitColorScheme c;

  @override
  Widget build(BuildContext context) {
    if (!isDownloading) return const SizedBox.shrink();

    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: c.border,
          valueColor: AlwaysStoppedAnimation<Color>(c.accent),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
