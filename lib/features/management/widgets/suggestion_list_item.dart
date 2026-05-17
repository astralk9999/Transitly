import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/route_suggestion_model.dart';

class SuggestionListItem extends StatelessWidget {
  const SuggestionListItem({
    required this.suggestion,
    required this.c,
    required this.l10n,
    required this.onTap,
    super.key,
  });

  final RouteSuggestionModel suggestion;
  final TransitColorScheme c;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.bgSurface,
            border: Border(
              left: BorderSide(color: c.accent, width: 2),
              top: BorderSide(color: c.border, width: 0.5),
              right: BorderSide(color: c.border, width: 0.5),
              bottom: BorderSide(color: c.border, width: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.managerInboxSuggestions.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.textMid,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    suggestion.status.label,
                    style: TransitTypography.bodySmall(c.accent),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${suggestion.originText} → ${suggestion.destinationText}',
                style: TransitTypography.bodySecondary(c.textHi),
              ),
              if (suggestion.notes != null)
                Text(
                  suggestion.notes!,
                  style: TransitTypography.bodySmall(c.textMid),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
