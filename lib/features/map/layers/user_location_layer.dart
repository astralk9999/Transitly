import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../shared/providers/user_location_provider.dart';

class UserLocationLayer extends StatelessWidget {
  const UserLocationLayer({
    super.key,
    required this.fix,
    required this.isDark,
  });

  final UserLocationFix fix;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);

    final accuracy = fix.accuracy.clamp(8.0, 200.0);

    return Stack(
      children: [
        CircleLayer(circles: [
          CircleMarker(
            point: fix.position,
            radius: accuracy,
            useRadiusInMeter: true,
            color: c.accent.withValues(alpha: 0.10),
            borderColor: c.accent.withValues(alpha: 0.35),
            borderStrokeWidth: 1,
          ),
        ]),
        MarkerLayer(
          markers: [
            Marker(
              point: fix.position,
              width: 24,
              height: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF4285F4),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            Marker(
              point: fix.position,
              width: 48,
              height: 48,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
