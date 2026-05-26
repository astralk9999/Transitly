import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/transit_animations.dart';
import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/models/stop_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/route_search_bar.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  bool _hasSearched = false;
  final bool _searchLoading = false;

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
              Expanded(
                child: AnimatedSwitcher(
                  duration: TransitAnimations.normal,
                  child: _hasSearched
                      ? (_searchLoading
                          ? _buildSearchShimmer(context)
                          : Column(
                              children: [
                                Expanded(
                                  child: EmptyState(
                                    l10n.searchUnderConstructionTitle,
                                    l10n.searchUnderConstructionSubtitle,
                                    actionLabel: l10n.searchReportRouteAction,
                                    onAction: () =>
                                        context.push('/suggestions/new'),
                                  ),
                                ),
                                _buildSuggestLink(c),
                              ],
                            ))
                      : Column(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSearch(StopModel? origin, StopModel? destination, bool useMyLocation) {
    if ((!useMyLocation && origin == null) || destination == null) return;
    setState(() => _hasSearched = true);
    context.push('/route-plan', extra: {
      'fromStopId': origin?.id,
      'toStopId': destination.id,
      'useMyLocation': useMyLocation,
    });
  }

  Widget _buildSearchShimmer(BuildContext context) {
    final padding = ResponsiveScaffold.screenPadding(context);
    return Padding(
      key: const ValueKey('search-shimmer'),
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShimmerSkeleton.text(context, width: 180),
          const SizedBox(height: 16),
          ShimmerSkeleton.routeCard(context),
          const SizedBox(height: 12),
          ShimmerSkeleton.routeCard(context),
          const SizedBox(height: 12),
          ShimmerSkeleton.routeCard(context),
        ],
      ),
    );
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
