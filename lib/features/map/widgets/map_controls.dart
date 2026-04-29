import 'package:flutter/material.dart';

import '../../../core/theme/transit_colors.dart';

class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.isDark,
    required this.onCenter,
    required this.onFilter,
    this.onSearch,
  });

  final bool isDark;
  final VoidCallback onCenter;
  final VoidCallback onFilter;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);

    // SafeArea keeps the top buttons clear of the status bar / camera
    // notch and the bottom button clear of the gesture bar / nav pill.
    return SafeArea(
      child: Stack(
        children: [
          // Search button - top left
          if (onSearch != null)
            Positioned(
              top: 16,
              left: 16,
              child: _ControlButton(
                icon: Icons.search,
                colors: c,
                onTap: onSearch!,
              ),
            ),
          // Filter button - top right
          Positioned(
            top: 16,
            right: 16,
            child: _ControlButton(
              icon: Icons.tune,
              colors: c,
              onTap: onFilter,
            ),
          ),
          // Center / my-location button - bottom right.
          // Pinch-to-zoom replaces the +/- buttons (flutter_map handles it).
          Positioned(
            bottom: 16,
            right: 16,
            child: _ControlButton(
              icon: Icons.my_location,
              colors: c,
              onTap: onCenter,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.icon,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final TransitColorScheme colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border, width: 0.5),
        ),
        child: Icon(icon, size: 20, color: colors.textHi),
      ),
    );
  }
}
