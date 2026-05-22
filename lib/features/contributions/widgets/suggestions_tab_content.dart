import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../shared/models/route_suggestion_model.dart';
import '../../../shared/widgets/empty_state.dart';

class SuggestionsTabContent extends StatelessWidget {
  const SuggestionsTabContent({
    super.key,
    required this.suggestions,
    required this.colorScheme,
    required this.padding,
  });

  final List<RouteSuggestionModel> suggestions;
  final TransitColorScheme colorScheme;
  final double padding;

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const Center(
        child: EmptyState(
          'SIN SUGERENCIAS',
          'Tus sugerencias de ruta aparecerán aquí',
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.all(padding),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final sug = suggestions[index];
        return GestureDetector(
          onTap: () => context.push('/suggestions/detail/${sug.id}'),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.bgSurface,
              border: Border.all(color: colorScheme.border, width: 0.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'SUGERENCIA',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.textMid,
                      ),
                    ),
                    const Spacer(),
                    if (sug.voteCount > 0)
                      Row(
                        children: [
                          Icon(Icons.arrow_upward,
                              size: 12, color: colorScheme.accent),
                          const SizedBox(width: 2),
                          Text(sug.voteCount.toString(),
                              style: TransitTypography.bodySmall(colorScheme.accent)),
                        ],
                      ),
                    const SizedBox(width: 8),
                    Text(
                      sug.status.label,
                      style: TransitTypography.bodySmall(colorScheme.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${sug.originText} → ${sug.destinationText}',
                  style: TransitTypography.bodySecondary(colorScheme.textHi),
                ),
                if (sug.routeCode != null)
                  Text(
                    sug.routeCode!,
                    style: TransitTypography.bodySmall(colorScheme.textMid),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
