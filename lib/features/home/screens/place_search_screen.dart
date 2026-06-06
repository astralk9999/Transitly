import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_spacing.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/providers/map_search_provider.dart';
import '../../../shared/providers/search_selection_provider.dart';
import '../../../shared/widgets/background_wrapper.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gradient_text.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../../../shared/widgets/shimmer_skeleton.dart';

/// Buscador unificado de paradas / líneas / lugares.
///
/// Rediseño B1: antes era una AppBar con TextField crudo + ListView de
/// ListTiles sin identidad. Ahora glass-card en la cabecera, resultados
/// en cards con badge de tipo, headers con GradientText, fondo decorativo
/// como el resto de pantallas.
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
    _controller.addListener(() => setState(() {}));
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

    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: c.textHi),
            tooltip: 'Volver',
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Buscar',
            style: TransitTypography.heading(c.textHi),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // ── Cabecera con search bar glass ──
              Padding(
                padding: EdgeInsets.fromLTRB(padding, 8, padding, 16),
                child: GlassCard(
                  blur: 20,
                  fillOpacity: 0.08,
                  borderRadius: TransitSpacing.radiusXl + 4,
                  padding: const EdgeInsets.symmetric(
                    horizontal: TransitSpacing.space16,
                    vertical: TransitSpacing.space4,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.search, color: c.accent, size: 22),
                      const SizedBox(width: TransitSpacing.space12),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: true,
                          style: TransitTypography.bodyPrimary(c.textHi),
                          decoration: InputDecoration(
                            hintText: l10n.homeSearchPlacesHint,
                            hintStyle:
                                TransitTypography.bodyPrimary(c.textLo),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 14,
                            ),
                          ),
                          onChanged: (v) => ref
                              .read(mapSearchQueryProvider.notifier)
                              .state = v,
                        ),
                      ),
                      if (_controller.text.isNotEmpty)
                        IconButton(
                          icon: Icon(Icons.close,
                              color: c.textMid, size: 18),
                          tooltip: 'Limpiar',
                          onPressed: () {
                            _controller.clear();
                            ref
                                .read(mapSearchQueryProvider.notifier)
                                .state = '';
                            _focusNode.requestFocus();
                          },
                        ),
                    ],
                  ),
                ),
              ),

              // ── Body ──
              Expanded(
                child: _SearchResultsBody(
                  onResultTap: (result) {
                    switch (result.type) {
                      case MapSearchResultType.route:
                        // B1.4: la línea NO abre el detalle directo.
                        // En su lugar marca pin + resalta polilínea +
                        // pushPath en la tarjeta para "Ver detalles".
                        final routeId = result.route?.id;
                        if (result.lat != null &&
                            result.lng != null &&
                            routeId != null) {
                          ref
                              .read(searchSelectionProvider.notifier)
                              .state = SearchSelection(
                            id: 'route-$routeId',
                            position: LatLng(result.lat!, result.lng!),
                            title: 'Línea ${result.route?.code ?? result.title}',
                            subtitle:
                                result.route?.name ?? result.subtitle,
                            icon: Icons.directions_bus,
                            color: result.route?.routeColor,
                            pushPath: '/route/$routeId',
                            routeId: routeId,
                          );
                          context.pop();
                          context.go('/home/mapa');
                        } else {
                          // Fallback: si no hay posición, push directo.
                          context.pop();
                          context.push('/route/${result.route!.id}');
                        }
                      case MapSearchResultType.stop:
                        // Guardamos la selección como marcador antes de
                        // navegar al mapa. El MapTab lo lee y centra +
                        // pinta un pin destacado tipo Google Maps.
                        ref.read(searchSelectionProvider.notifier).state =
                            SearchSelection(
                          id: 'stop-${result.stop?.id ?? result.title}',
                          position: LatLng(result.lat!, result.lng!),
                          title: result.title,
                          subtitle: result.subtitle.isEmpty
                              ? 'Parada'
                              : result.subtitle,
                          icon: Icons.location_on,
                          pushPath: result.stop != null
                              ? '/stop/${result.stop!.id}'
                              : null,
                        );
                        context.pop();
                        context.go('/home/mapa');
                      case MapSearchResultType.place:
                        ref.read(searchSelectionProvider.notifier).state =
                            SearchSelection(
                          id: 'place-${result.title}',
                          position: LatLng(result.lat!, result.lng!),
                          title: result.title,
                          subtitle: result.subtitle.isEmpty
                              ? 'Lugar'
                              : result.subtitle,
                          icon: Icons.place,
                        );
                        context.pop();
                        context.go('/home/mapa');
                    }
                  },
                ),
              ),
            ],
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
    final padding = ResponsiveScaffold.screenPadding(context);

    // Estado vacío con sugerencias visuales.
    if (query.trim().length < 2) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.travel_explore,
                  size: 72, color: c.accent.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Encuentra paradas, líneas y lugares',
                style: TransitTypography.heading(c.textHi),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Escribe al menos 2 letras del nombre, código o destino.',
                style: TransitTypography.bodySecondary(c.textMid),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _HintChip(c: c, icon: Icons.directions_bus, text: 'L 8'),
                  _HintChip(c: c, icon: Icons.location_on, text: 'Plaza'),
                  _HintChip(c: c, icon: Icons.place, text: 'Estadio'),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final resultsAsync = ref.watch(mapSearchResultsProvider);

    return resultsAsync.when(
      data: (results) {
        if (results.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search_off,
                      size: 72, color: c.textLo),
                  const SizedBox(height: 16),
                  Text(
                    l10n.mapSearchNoResults,
                    style: TransitTypography.heading(c.textHi),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prueba con otro término o revisa la ortografía.',
                    style: TransitTypography.bodySecondary(c.textMid),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
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
                padding: EdgeInsets.fromLTRB(
                  padding,
                  items.isEmpty ? 0 : 16,
                  padding,
                  8,
                ),
                child: GradientText(
                  typeLabel.toUpperCase(),
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                  gradient: c.gradientAccent,
                ),
              ),
            );
          }
          items.add(Padding(
            padding: EdgeInsets.fromLTRB(padding, 0, padding, 8),
            child: _ResultCard(
              result: r,
              c: c,
              onTap: () => onResultTap(r),
            ),
          ));
        }
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: items,
        );
      },
      loading: () => Center(
        child: Padding(
          padding: EdgeInsets.all(padding),
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.c,
    required this.onTap,
  });

  final MapSearchResult result;
  final TransitColorScheme c;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconBg;
    switch (result.type) {
      case MapSearchResultType.route:
        icon = Icons.directions_bus;
        iconBg = result.route?.routeColor ?? c.accent;
      case MapSearchResultType.stop:
        icon = Icons.location_on;
        iconBg = c.accent;
      case MapSearchResultType.place:
        icon = Icons.place;
        iconBg = c.neonPurple;
    }

    // GestureDetector con HitTestBehavior.opaque garantiza que el tap
    // llega aunque el GlassCard tenga BackdropFilter encima. Antes
    // estaba envuelto en Material + InkWell pero los gestos no
    // llegaban al onTap por el blur del GlassCard.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12),
          child: Row(
            children: [
              // Badge con color del tipo / línea.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBg.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: iconBg.withValues(alpha: 0.5), width: 1),
                ),
                alignment: Alignment.center,
                child: result.type == MapSearchResultType.route &&
                        result.route != null
                    ? FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          result.route!.code,
                          style: TextStyle(
                            color: iconBg,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : Icon(icon, color: iconBg, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      result.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TransitTypography.bodyPrimary(c.textHi)
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (result.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TransitTypography.bodySmall(c.textMid),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: c.textLo, size: 20),
            ],
          ),
        ),
    );
  }
}

class _HintChip extends StatelessWidget {
  const _HintChip({
    required this.c,
    required this.icon,
    required this.text,
  });
  final TransitColorScheme c;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c.textLo),
          const SizedBox(width: 4),
          Text(text,
              style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }
}
