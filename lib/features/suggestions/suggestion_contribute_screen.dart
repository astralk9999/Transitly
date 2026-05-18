import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/route_suggestion_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Lista de sugerencias de ruta abiertas a contribución de la comunidad.
/// Al tocar una, se abre el detalle existente (`/suggestions/:id`) donde
/// se puede aportar trazado, paradas u horarios.
class SuggestionContributeScreen extends ConsumerWidget {
  const SuggestionContributeScreen({super.key});

  static const _openStatuses = {
    SuggestionStatus.idea,
    SuggestionStatus.inReview,
    SuggestionStatus.enriched,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mock = ref.watch(mockDataServiceProvider);

    final open = mock.routeSuggestions
        .where((s) => _openStatuses.contains(s.status))
        .toList()
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
            child: SmokeBackground(color: c.accent, isDark: isDark),
          ),
          Column(
            children: [
              TransitAppBar(title: l10n.suggestionContributeTitle),
              Expanded(
                child: open.isEmpty
                    ? EmptyState(
                        l10n.suggestionContributeEmptyTitle,
                        l10n.suggestionContributeEmptySubtitle,
                        icon: Icons.volunteer_activism,
                      )
                : ListView.separated(
                    padding: const EdgeInsets.all(TransitSpacing.space16),
                    itemCount: open.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: TransitSpacing.space8),
                    itemBuilder: (context, i) {
                      final s = open[i];
                      return _SuggestionTile(
                        c: c,
                        suggestion: s,
                        onTap: () => context.push('/suggestions/${s.id}'),
                      );
                    },
                  ),
          ),
        ],
      ),
      ],
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.c,
    required this.suggestion,
    required this.onTap,
  });

  final TransitColorScheme c;
  final RouteSuggestionModel suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = suggestion;
    return Container(
      decoration: BoxDecoration(
        color: c.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text('${s.originText} → ${s.destinationText}',
            style: TransitTypography.bodyPrimary(c.textHi),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _Pill(c: c, icon: Icons.how_to_vote, label: '${s.voteCount}'),
              const SizedBox(width: 8),
              _Pill(
                  c: c,
                  icon: Icons.edit_note,
                  label: '${s.contributionCount}'),
              const SizedBox(width: 8),
              Text(s.status.label,
                  style: TransitTypography.bodySecondary(c.textMid)),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: c.textMid),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.c, required this.icon, required this.label});
  final TransitColorScheme c;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: c.accent),
        const SizedBox(width: 3),
        Text(label, style: TransitTypography.bodySecondary(c.textMid)),
      ],
    );
  }
}
