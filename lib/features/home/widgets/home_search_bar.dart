import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/pressable.dart';

class HomeSearchBar extends StatelessWidget {
  const HomeSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    return Pressable(
      onTap: () => context.push('/search/places'),
      child: GlassCard(
        borderRadius: TransitSpacing.radiusXl + 4,
        blur: 20,
        fillOpacity: 0.06,
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space16,
          vertical: TransitSpacing.space12,
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: c.textMid, size: 20),
            const SizedBox(width: TransitSpacing.space12),
            Expanded(
              child: Text(
                l10n.homeSearchPlacesHint,
                style: TransitTypography.bodySecondary(c.textMid),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
