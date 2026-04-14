import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/transit_colors.dart';

class ShimmerSkeleton {
  ShimmerSkeleton._();

  static Widget routeCard(BuildContext context) {
    final c = _colors(context);
    return Shimmer.fromColors(
      baseColor: c.bgRaised,
      highlightColor: c.border,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.bgSurface,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 40,
              decoration: BoxDecoration(
                color: c.bgRaised,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 160,
                    height: 14,
                    decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget stopItem(BuildContext context) {
    final c = _colors(context);
    return Shimmer.fromColors(
      baseColor: c.bgRaised,
      highlightColor: c.border,
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: c.bgRaised,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 14,
                margin: const EdgeInsets.only(right: 80),
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget text(
    BuildContext context, {
    double width = 120,
    double height = 14,
  }) {
    final c = _colors(context);
    return Shimmer.fromColors(
      baseColor: c.bgRaised,
      highlightColor: c.border,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  static Widget list({
    required BuildContext context,
    required int count,
    required Widget Function() builder,
  }) {
    return Column(
      children: List.generate(count, (i) {
        return Padding(
          padding: EdgeInsets.only(bottom: i < count - 1 ? 8 : 0),
          child: builder(),
        );
      }),
    );
  }

  static TransitColorScheme _colors(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TransitColorScheme.of(isDark);
  }
}
