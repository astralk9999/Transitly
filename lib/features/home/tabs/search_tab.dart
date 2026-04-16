import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/mock/mock_data_service.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/route_card.dart';
import '../../../shared/widgets/route_search_bar.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';

class SearchTab extends ConsumerStatefulWidget {
  const SearchTab({super.key});

  @override
  ConsumerState<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends ConsumerState<SearchTab> {
  bool _hasSearched = false;
  bool _searchLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: RouteSearchBar(
                availableStops: mockData.stops,
                onSearch: () {
                  setState(() {
                    _searchLoading = true;
                    _hasSearched = true;
                  });
                  Future.delayed(const Duration(milliseconds: 800), () {
                    if (mounted) setState(() => _searchLoading = false);
                  });
                },
              ),
            ),
            // Results or empty state
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _hasSearched
                  ? (_searchLoading
                      ? _buildSearchShimmer(context)
                      : _buildResults(context, c, mockData))
                  : Column(
                      children: [
                        const Expanded(
                          child: EmptyState(
                            'BUSCAR RUTA',
                            'Indica origen y destino',
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
    );
  }

  Widget _buildSearchShimmer(BuildContext context) {
    return Padding(
      key: const ValueKey('search-shimmer'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
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

  Widget _buildResults(
      BuildContext context, TransitColorScheme c, MockDataService mockData) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    final routeL1 = mockData.getRouteById('L1');
    final routeL4 = mockData.getRouteById('L4');
    final routeL5 = mockData.getRouteById('L5');

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Header
        Row(
          children: [
            Text(
              '3 RUTAS ENCONTRADAS',
              style: TransitTypography.sectionTitle(c.textMid),
            ),
            const Spacer(),
            Text(timeStr, style: TransitTypography.stopTime(c.accent)),
          ],
        ),
        const SizedBox(height: 12),

        // Result A: Direct
        _resultHeader(c, 'DIRECTA · 25 min · 1,30 €', c.stateOnTime),
        const SizedBox(height: 6),
        if (routeL1 != null)
          RouteCard(
            route: routeL1,
            activeTrip: mockData.getActiveTripForRoute('L1'),
            estimatedMinutes: '25m',
            onTap: () => context.push('/route/L1'),
          ),
        const SizedBox(height: 16),

        // Result B: Transfer
        _resultHeader(c, '1 TRASBORDO · 35 min · 2,60 €', c.textMid),
        const SizedBox(height: 6),
        if (routeL4 != null)
          RouteCard(
            route: routeL4,
            estimatedMinutes: '15m',
            onTap: () => context.push('/route/L4'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            children: [
              Text('↕', style: TextStyle(fontSize: 14, color: c.textMid)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Trasbordo en Plaza del Arenal · ~5 min',
                  style: GoogleFonts.dmSans(fontSize: 12, color: c.textMid),
                ),
              ),
            ],
          ),
        ),
        if (routeL1 != null)
          RouteCard(
            route: routeL1,
            estimatedMinutes: '15m',
            onTap: () => context.push('/route/L1'),
          ),
        const SizedBox(height: 16),

        // Result C: Alternative
        _resultHeader(c, 'ALTERNATIVA · 40 min', c.stateDelay),
        const SizedBox(height: 6),
        if (routeL5 != null)
          RouteCard(
            route: routeL5,
            estimatedMinutes: '40m',
            onTap: () => context.push('/route/L5'),
          ),
        const SizedBox(height: 24),

        _buildSuggestLink(c),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _resultHeader(TransitColorScheme c, String text, Color color) {
    return Row(
      children: [
        Container(width: 3, height: 14, color: color),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.ibmPlexMono(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
      ],
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
