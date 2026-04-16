import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/stop_model.dart';
import 'pressable.dart';
import 'transit_chip.dart';

class StopListItem extends StatelessWidget {
  const StopListItem({
    super.key,
    required this.stop,
    required this.scheduledTime,
    this.realTime,
    this.isCurrent = false,
    this.isPassed = false,
    this.isFirst = false,
    this.isLast = false,
    this.transferLines,
    this.onTap,
  });

  final StopModel stop;
  final String scheduledTime;
  final String? realTime;
  final bool isCurrent;
  final bool isPassed;
  final bool isFirst;
  final bool isLast;
  final List<String>? transferLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    final textColor = isPassed ? c.textLo : c.textHi;

    return Pressable(
      onTap: onTap,
      scale: 0.98,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 60),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Left: connector + circle
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    // Line above
                    Expanded(
                      child: isFirst
                          ? const SizedBox.shrink()
                          : Center(
                              child: Container(
                                width: 1,
                                color: c.border,
                              ),
                            ),
                    ),
                    // Circle
                    _buildCircle(c),
                    // Line below
                    Expanded(
                      child: isLast
                          ? const SizedBox.shrink()
                          : Center(
                              child: Container(
                                width: 1,
                                color: c.border,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              // Center: name + transfers
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stop.name,
                        style: TransitTypography.bodyPrimary(textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (stop.municipality.isNotEmpty ||
                          (transferLines != null &&
                              transferLines!.isNotEmpty)) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (stop.municipality.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  stop.municipality,
                                  style: TransitTypography.bodySmall(c.textMid),
                                ),
                              ),
                            if (transferLines != null)
                              ...transferLines!.map(
                                (line) => Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: TransitChip(line),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Right: time
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      realTime ?? scheduledTime,
                      style: TransitTypography.stopTime(textColor),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircle(TransitColorScheme c) {
    if (isCurrent) {
      return Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: c.accent,
          shape: BoxShape.circle,
        ),
      );
    }
    if (isPassed) {
      return Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: c.textLo,
          shape: BoxShape.circle,
        ),
      );
    }
    // Future stop: outline
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: c.textLo, width: 1),
      ),
    );
  }
}
