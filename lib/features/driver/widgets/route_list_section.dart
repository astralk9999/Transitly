import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/route_model.dart';

class RouteListSection extends StatelessWidget {
  const RouteListSection({
    super.key,
    required this.routes,
    required this.selectedRouteId,
    required this.onRouteSelected,
    required this.routeListKey,
  });

  final List<RouteModel> routes;
  final String? selectedRouteId;
  final ValueChanged<String> onRouteSelected;
  final GlobalKey routeListKey;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.driverStartSelectLine,
          key: routeListKey,
          style: TransitTypography.sectionTitle(c.textMid),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.0,
          children: routes.map((route) {
            final isSelected = selectedRouteId == route.id;
            return GestureDetector(
              onTap: () => onRouteSelected(route.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.bgSurface,
                  border: Border.all(
                    color: isSelected ? c.accent : c.border,
                    width: isSelected ? 1 : 0.5,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      route.code,
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: c.accent,
                      ),
                    ),
                    Text(
                      route.name,
                      style: TransitTypography.bodySmall(c.textMid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
