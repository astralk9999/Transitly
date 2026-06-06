import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/route_search_bar.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);

    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContentConstraints(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(padding),
                child: RouteSearchBar(
                  availableStops: mockData.stops,
                  onSearchWith: _handleSearch,
                ),
              ),
              // Empty state mientras no se busque. Al pulsar buscar
              // navegamos a /route-plan; ese screen muestra el shimmer
              // y los resultados reales. Antes había un EmptyState
              // "Búsqueda en construcción" placeholder que ocultaba que
              // el motor sí funciona.
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: EmptyState(
                        l10n.searchEmptyTitle,
                        l10n.searchEmptySubtitle,
                      ),
                    ),
                    _buildSuggestLink(c),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearch(
      StopModel? origin, StopModel? destination, bool useMyLocation) {
    if ((!useMyLocation && origin == null) || destination == null) return;
    context.push('/route-plan', extra: {
      'fromStopId': origin?.id,
      'toStopId': destination.id,
      'useMyLocation': useMyLocation,
    });
  }

  Widget _buildSuggestLink(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: () => context.push('/suggestions/new'),
        child: Text(
          '¿No encuentras tu ruta? Sugiere que la añadamos →',
          style: TransitTypography.bodySecondary(c.accent),
        ),
      ),
    );
  }
}
