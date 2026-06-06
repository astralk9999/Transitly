import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/map_search_provider.dart';
import '../../../shared/providers/search_selection_provider.dart';

void showMapSearchSheet(
  BuildContext context,
  WidgetRef ref,
  MapController mapController,
) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final c = TransitColorScheme.of(isDark);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: c.bgRoot,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textLo.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(ctx).mapSearchHint,
                      hintStyle: TransitTypography.bodySecondary(c.textMid),
                      filled: true,
                      fillColor: c.bgSurface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          Icon(Icons.search, color: c.textMid, size: 20),
                      suffixIcon: Consumer(
                        builder: (_, ref, __) {
                          final query =
                              ref.watch(mapSearchQueryProvider);
                          if (query.isEmpty) return const SizedBox.shrink();
                          return IconButton(
                            icon: Icon(Icons.clear, color: c.textMid, size: 18),
                            onPressed: () =>
                                ref.read(mapSearchQueryProvider.notifier).state = '',
                          );
                        },
                      ),
                    ),
                    style: TransitTypography.bodyPrimary(c.textHi),
                    onChanged: (v) => ref
                        .read(mapSearchQueryProvider.notifier)
                        .state = v,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: _SearchResults(
                    mapController: mapController,
                    onClose: () => Navigator.of(sheetCtx).pop(),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({
    required this.mapController,
    required this.onClose,
  });

  final MapController mapController;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(mapSearchQueryProvider);
    if (query.isEmpty) {
      return Center(
        child: Text(
          AppLocalizations.of(context).mapSearchHint,
          style: TransitTypography.bodySecondary(
            TransitColorScheme.of(
              Theme.of(context).brightness == Brightness.dark,
            ).textMid,
          ),
        ),
      );
    }

    final resultsAsync = ref.watch(mapSearchResultsProvider);
    final c = TransitColorScheme.of(
      Theme.of(context).brightness == Brightness.dark,
    );

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Text(
              AppLocalizations.of(context).mapSearchNoResults,
              style: TransitTypography.bodySecondary(c.textMid),
            ),
          );
        }

        String? lastType;
        final items = <Widget>[];
        for (final r in results) {
          final typeLabel = _typeLabel(r.type, context);
          if (typeLabel != lastType) {
            lastType = typeLabel;
            items.add(
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
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
            onTap: () {
              // B1.2: en lugar de abrir el detalle directamente,
              // marcamos la selección con un pin destacado. El usuario
              // puede pulsar "Ver detalles" en la tarjeta del pin si
              // quiere abrir la pantalla completa.
              switch (r.type) {
                case MapSearchResultType.route:
                  // Para línea: centramos en la primera parada (o el
                  // primer punto del trazado) y dejamos el pin con
                  // pushPath a /route/${id}.
                  final stop = r.route != null
                      ? r.route!.id
                      : null;
                  if (r.lat != null && r.lng != null) {
                    ref.read(searchSelectionProvider.notifier).state =
                        SearchSelection(
                      id: 'route-${r.route?.id ?? r.title}',
                      position: LatLng(r.lat!, r.lng!),
                      title: 'Línea ${r.route?.code ?? r.title}',
                      subtitle: r.route?.name ?? r.subtitle,
                      icon: Icons.directions_bus,
                      color: r.route?.routeColor,
                      pushPath: stop != null ? '/route/$stop' : null,
                    );
                  } else {
                    // Sin posición → push directo como antes.
                    onClose();
                    return;
                  }
                  onClose();
                case MapSearchResultType.stop:
                  ref.read(searchSelectionProvider.notifier).state =
                      SearchSelection(
                    id: 'stop-${r.stop?.id ?? r.title}',
                    position: LatLng(r.lat!, r.lng!),
                    title: r.title,
                    subtitle:
                        r.subtitle.isEmpty ? 'Parada' : r.subtitle,
                    icon: Icons.location_on,
                    pushPath:
                        r.stop != null ? '/stop/${r.stop!.id}' : null,
                  );
                  onClose();
                case MapSearchResultType.place:
                  ref.read(searchSelectionProvider.notifier).state =
                      SearchSelection(
                    id: 'place-${r.title}',
                    position: LatLng(r.lat!, r.lng!),
                    title: r.title,
                    subtitle:
                        r.subtitle.isEmpty ? 'Lugar' : r.subtitle,
                    icon: Icons.place,
                  );
                  onClose();
              }
            },
          ));
        }
        return ListView(
          padding: EdgeInsets.zero,
          children: items,
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (_, __) => Center(
        child: Text(
          AppLocalizations.of(context).mapSearchError,
          style: TransitTypography.bodySecondary(c.textMid),
        ),
      ),
    );
  }

  String _typeLabel(MapSearchResultType type, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (type) {
      MapSearchResultType.route => l10n.mapSearchSectionRoutes,
      MapSearchResultType.stop => l10n.mapSearchSectionStops,
      MapSearchResultType.place => l10n.mapSearchSectionPlaces,
    };
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
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TransitTypography.bodySmall(c.textMid),
      ),
    );
  }
}
