import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/user_location_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'route_plan_models.dart';
import 'route_planner_provider.dart';
import 'widgets/route_plan_card.dart';

class RoutePlanResultsScreen extends ConsumerStatefulWidget {
  const RoutePlanResultsScreen({
    super.key,
    this.fromStopId,
    required this.toStopId,
    this.useMyLocation = false,
  });

  final String? fromStopId;
  final String toStopId;
  final bool useMyLocation;

  @override
  ConsumerState<RoutePlanResultsScreen> createState() =>
      _RoutePlanResultsScreenState();
}

class _RoutePlanResultsScreenState
    extends ConsumerState<RoutePlanResultsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final mockData = ref.watch(mockDataServiceProvider);
    final padding = TransitSpacing.space16;

    final toStop = mockData.getStopById(widget.toStopId);
    if (toStop == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: SafeArea(
          child: Column(
            children: [
              const TransitAppBar(title: 'Ruta'),
              ErrorCard('Parada destino no encontrada: ${widget.toStopId}'),
            ],
          ),
        ),
      );
    }

    if (widget.useMyLocation) {
      final loc = ref.watch(userLocationLatLngProvider);
      if (loc == null) {
        return Scaffold(
          backgroundColor: c.bgRoot,
          body: const SafeArea(
            child: Column(
              children: [
                TransitAppBar(title: 'Ruta'),
                EmptyState(
                  'Activa la ubicación',
                  'Necesitamos tu ubicación para buscar rutas desde tu posición actual.',
                  icon: Icons.location_searching,
                ),
              ],
            ),
          ),
        );
      }

      final nearby = mockData.getNearbyStops(loc.latitude, loc.longitude, 1);
      if (nearby.isEmpty) {
        return Scaffold(
          backgroundColor: c.bgRoot,
          body: SafeArea(
            child: Column(
              children: [
                const TransitAppBar(title: 'Ruta'),
                EmptyState(
                  l10n.searchEmptyTitle,
                  l10n.searchEmptySubtitle,
                ),
              ],
            ),
          ),
        );
      }

      final fromStop = nearby.first;
      final resultsAsync =
          ref.watch(routePlanResultsProvider((from: fromStop, to: toStop)));

      return _buildBody(resultsAsync, fromStop, toStop, c, l10n, padding);
    }

    if (widget.fromStopId == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: const SafeArea(
          child: Column(
            children: [
              TransitAppBar(title: 'Ruta'),
              ErrorCard('Falta la parada de origen'),
            ],
          ),
        ),
      );
    }

    final fromStop = mockData.getStopById(widget.fromStopId!);
    if (fromStop == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: SafeArea(
          child: Column(
            children: [
              const TransitAppBar(title: 'Ruta'),
              ErrorCard('Parada origen no encontrada: ${widget.fromStopId}'),
            ],
          ),
        ),
      );
    }

    final resultsAsync =
        ref.watch(routePlanResultsProvider((from: fromStop, to: toStop)));

    return _buildBody(resultsAsync, fromStop, toStop, c, l10n, padding);
  }

  Widget _buildBody(
    AsyncValue<List<RoutePlanResult>> resultsAsync,
    StopModel fromStop,
    StopModel toStop,
    TransitColorScheme c,
    AppLocalizations l10n,
    double padding,
  ) {
    return Scaffold(
      backgroundColor: c.bgRoot,
      body: SafeArea(
        child: Column(
          children: [
            TransitAppBar(
              title: '${fromStop.name} \u2192 ${toStop.name}',
            ),
            Expanded(
              child: resultsAsync.when(
                loading: () => Padding(
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerSkeleton.text(context, width: 180),
                      const SizedBox(height: TransitSpacing.space16),
                      ShimmerSkeleton.routeCard(context),
                      const SizedBox(height: TransitSpacing.space12),
                      ShimmerSkeleton.routeCard(context),
                      const SizedBox(height: TransitSpacing.space12),
                      ShimmerSkeleton.routeCard(context),
                    ],
                  ),
                ),
                error: (err, _) => Center(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: ErrorCard(
                      err.toString(),
                      onRetry: () => ref.invalidate(routePlanResultsProvider(
                          (from: fromStop, to: toStop))),
                    ),
                  ),
                ),
                data: (results) {
                  if (results.isEmpty) {
                    return EmptyState(
                      l10n.searchEmptyTitle,
                      l10n.searchEmptySubtitle,
                      icon: Icons.route,
                      actionLabel: 'Probar otras paradas',
                      onAction: () => Navigator.of(context).pop(),
                    );
                  }

                  final title =
                      '${results.length} ${results.length == 1 ? 'ruta encontrada' : 'rutas encontradas'}';

                  return ListView.builder(
                    padding: EdgeInsets.all(padding),
                    itemCount: results.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(
                              bottom: TransitSpacing.space12),
                          child: Text(
                            title,
                            style:
                                TransitTypography.sectionLabel(c.textMid),
                          ),
                        );
                      }

                      final result = results[index - 1];
                      return RoutePlanCard(result: result);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
