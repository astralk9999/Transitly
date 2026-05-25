import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';

class UserLocationLayer extends StatelessWidget {
  const UserLocationLayer({
    super.key,
    required this.position,
    required this.isDark,
  });

  final LatLng position;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);

    return MarkerLayer(
      markers: [
        Marker(
          point: position,
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
          point: position,
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
    );
  }
}
