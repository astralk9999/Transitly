import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';

String _formatTime(int sec) {
  final h = sec ~/ 3600;
  final m = (sec % 3600) ~/ 60;
  final s = sec % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class DriverStatsCard extends StatelessWidget {
  const DriverStatsCard({
    super.key,
    required this.isPaused,
    required this.elapsedSeconds,
    required this.tripDistanceKm,
    required this.colorScheme,
    required this.statusPausedLabel,
    required this.statusLiveLabel,
  });

  final bool isPaused;
  final int elapsedSeconds;
  final double tripDistanceKm;
  final TransitColorScheme colorScheme;
  final String statusPausedLabel;
  final String statusLiveLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: colorScheme.bgSurface,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: isPaused ? Colors.orangeAccent : Colors.greenAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isPaused ? statusPausedLabel : statusLiveLabel,
            style: TransitTypography.bodyPrimary(
                    isPaused ? Colors.orangeAccent : Colors.greenAccent)
                .copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            _formatTime(elapsedSeconds),
            style: TransitTypography.bodyPrimary(colorScheme.textHi)
                .copyWith(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 16),
          Text(
            '${tripDistanceKm.toStringAsFixed(1)} km',
            style: TransitTypography.bodySecondary(colorScheme.textMid),
          ),
        ],
      ),
    );
  }
}
