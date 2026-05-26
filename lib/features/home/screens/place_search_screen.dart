import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/map_search_provider.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';

class PlaceSearchScreen extends ConsumerStatefulWidget {
  const PlaceSearchScreen({super.key});

  @override
  ConsumerState<PlaceSearchScreen> createState() => _PlaceSearchScreenState();
}

class _PlaceSearchScreenState extends ConsumerState<PlaceSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final padding = ResponsiveScaffold.screenPadding(context);

    return Scaffold(
      backgroundColor: c.bgRoot,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: c.textHi),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          style: TransitTypography.bodyPrimary(c.textHi),
          decoration: InputDecoration(
            hintText: l10n.homeSearchPlacesHint,
            hintStyle: TransitTypography.bodySecondary(c.textMid),
            filled: true,
            fillColor: c.bgSurface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TransitSpacing.radiusXl),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: TransitSpacing.space16,
              vertical: TransitSpacing.space10,
            ),
            prefixIcon:
                Icon(Icons.search, color: c.textMid, size: 20),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: c.textMid, size: 18),
                    onPressed: () {
                      _controller.clear();
                      ref
                          .read(mapSearchQueryProvider.notifier)
                          .state = '';
                    },
                  )
                : null,
          ),
          onChanged: (v) => ref
              .read(mapSearchQueryProvider.notifier)
              .state = v,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: _SearchResultsBody(
            onResultTap: (result) {
              switch (result.type) {
                case MapSearchResultType.route:
                  context.pop();
                  context.push('/route/${result.route!.id}');
                case MapSearchResultType.stop:
                  context.pop();
                  context.go('/home/mapa',
                      extra: LatLng(result.lat!, result.lng!));
                case MapSearchResultType.place:
                  context.pop();
                  context.go('/home/mapa',
                      extra: LatLng(result.lat!, result.lng!));
              }
            },
          ),
        ),
      ),
    );
  }
}

class _SearchResultsBody extends ConsumerWidget {
  const _SearchResultsBody({required this.onResultTap});

  final void Function(MapSearchResult result) onResultTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(mapSearchQueryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);

    if (query.isEmpty) {
      return Center(
        child: Text(
          l10n.homeSearchPlacesHint,
          textAlign: TextAlign.center,
          style: TransitTypography.bodySecondary(c.textMid),
        ),
      );
    }

    final resultsAsync = ref.watch(mapSearchResultsProvider);

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              l10n.mapSearchNoResults,
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          );
        }

        String? lastType;
        final items = <Widget>[];
        for (final r in results) {
          final typeLabel = switch (r.type) {
            MapSearchResultType.route => l10n.mapSearchSectionRoutes,
            MapSearchResultType.stop => l10n.mapSearchSectionStops,
            MapSearchResultType.place => l10n.mapSearchSectionPlaces,
          };
          if (typeLabel != lastType) {
            lastType = typeLabel;
            items.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TransitSpacing.space16,
                  TransitSpacing.space16,
                  TransitSpacing.space16,
                  TransitSpacing.space4,
                ),
                child: Text(
                  typeLabel.toUpperCase(),
                  style: TransitTypography.sectionTitle(c.accent),
                ),
              ),
            );
          }
          items.add(_ResultTile(
            result: r,
            c: c,
            onTap: () => onResultTap(r),
          ));
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: items,
        );
      },
      loading: () => Center(
        child: Padding(
          padding: const EdgeInsets.all(TransitSpacing.space16),
          child: ShimmerSkeleton.routeCard(context),
        ),
      ),
      error: (_, __) => Center(
        child: Text(
          l10n.mapSearchError,
          style: TransitTypography.bodySecondary(c.textMid),
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.result,
    required this.c,
    required this.onTap,
  });

  final MapSearchResult result;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (result.type) {
      case MapSearchResultType.route:
        icon = Icons.directions_bus;
      case MapSearchResultType.stop:
        icon = Icons.location_on;
      case MapSearchResultType.place:
        icon = Icons.place;
    }

    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: c.accent, size: 22),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TransitTypography.bodyPrimary(c.textHi),
      ),
      subtitle: result.subtitle.isNotEmpty
          ? Text(
              result.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TransitTypography.bodySmall(c.textMid),
            )
          : null,
    );
  }
}
