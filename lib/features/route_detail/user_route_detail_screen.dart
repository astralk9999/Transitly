import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/user_routes/user_route_schedules_repository.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/user_stops/user_stops_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/transit_button.dart';
import 'user_route_report_modal.dart';
import 'user_route_share_modal.dart';

// TODO(l10n):
class UserRouteDetailScreen extends ConsumerStatefulWidget {
  const UserRouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<UserRouteDetailScreen> createState() =>
      _UserRouteDetailScreenState();
}

class _UserRouteDetailScreenState extends ConsumerState<UserRouteDetailScreen> {
  UserRouteModel? _route;
  List<UserRouteStopModel> _stops = [];
  List<UserRouteScheduleModel> _schedules = [];
  bool _loading = true;
  bool _hasVoted = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final routesRepo = ref.read(userRoutesRepositoryProvider);
    final stopsRepo = ref.read(userStopsRepositoryProvider);
    final schedulesRepo = ref.read(userRouteSchedulesRepositoryProvider);

    if (routesRepo == null || stopsRepo == null || schedulesRepo == null) {
      if (mounted) setState(() { _loading = false; _error = 'No autenticado'; });
      return;
    }

    try {
      final results = await Future.wait([
        routesRepo.getById(widget.routeId),
        stopsRepo.getStopsForRoute(widget.routeId),
        schedulesRepo.getForRoute(widget.routeId),
      ]);

      if (!mounted) return;

      final route = results[0] as UserRouteModel?;
      if (route == null) {
        setState(() { _error = 'Ruta no encontrada'; _loading = false; });
        return;
      }

      final voted = await routesRepo.hasVoted(widget.routeId);

      setState(() {
        _route = route;
        _stops = results[1] as List<UserRouteStopModel>;
        _schedules = results[2] as List<UserRouteScheduleModel>;
        _hasVoted = voted;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() { _error = e.toString(); _loading = false; });
      }
    }
  }

  Future<void> _toggleVote() async {
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) return;
    try {
      if (_hasVoted) {
        await repo.unvote(widget.routeId);
        if (mounted) {
          setState(() {
            _hasVoted = false;
            _route = _route?.copyWith(voteCount: (_route!.voteCount - 1).clamp(0, 999999));
          });
        }
      } else {
        await repo.vote(widget.routeId);
        if (mounted) {
          setState(() {
            _hasVoted = true;
            _route = _route?.copyWith(voteCount: _route!.voteCount + 1);
          });
        }
      }
    } catch (_) {}
  }

  void _openShare() {
    if (_route == null) return;
    UserRouteShareModal.show(context, _route!);
  }

  void _openReport() {
    if (_route == null) return;
    UserRouteReportModal.show(context, _route!.id);
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF977DDF);
    }
  }

  String _dayTypeLabel(String dt) {
    return switch (dt) {
      'weekday' => 'Lunes a viernes',
      'saturday' => 'Sábados',
      'sunday' => 'Domingos',
      'holiday' => 'Festivos',
      'summer' => 'Verano',
      'winter' => 'Invierno',
      'every_day' => 'Todos los días',
      _ => dt,
    };
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    if (_loading) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _route == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        appBar: AppBar(
          backgroundColor: c.bgRoot,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: c.textHi),
            onPressed: () => context.pop(),
          ),
        ),
        body: EmptyState(
          _error ?? 'Ruta no encontrada',
          'La ruta solicitada no está disponible',
          // TODO: l10n
          icon: Icons.error_outline,
        ),
      );
    }

    final route = _route!;
    final color = _hexToColor(route.routeColor);
    final stopsWithCoords = _stops
        .where((s) => s.stop != null)
        .toList();
    final center = stopsWithCoords.isNotEmpty
        ? LatLng(
            stopsWithCoords.first.stop!.lat,
            stopsWithCoords.first.stop!.lng,
          )
        : const LatLng(36.7, -6.1);

    final groupedSchedules = <String, List<UserRouteScheduleModel>>{};
    for (final s in _schedules) {
      groupedSchedules.putIfAbsent(s.dayType, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: RefreshIndicator(
        onRefresh: _load,
        color: c.accent,
        child: CustomScrollView(
          slivers: [
            // AppBar
            SliverAppBar(
              backgroundColor: c.bgRoot,
              pinned: true,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: c.textHi),
                onPressed: () => context.pop(),
              ),
              title: Text(
                route.name,
                style: TransitTypography.heading(c.textHi),
              ),
            ),

            // Header
            SliverToBoxAdapter(child: _buildHeader(c, route, color)),

            // Stats
            SliverToBoxAdapter(child: _buildStatsRow(c, route)),

            // Action buttons
            SliverToBoxAdapter(child: _buildActionButtons(c)),

            // Map
            if (stopsWithCoords.isNotEmpty)
              SliverToBoxAdapter(child: _buildMap(c, stopsWithCoords, color, center)),

            // Stops
            if (_stops.isNotEmpty)
              SliverToBoxAdapter(child: _buildSectionTitle(c, 'Paradas', Icons.place)),

            if (_stops.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildStopTile(c, _stops[index], index),
                  childCount: _stops.length,
                ),
              ),

            // Schedules
            if (_schedules.isNotEmpty)
              SliverToBoxAdapter(child: _buildSectionTitle(c, 'Horarios', Icons.schedule)),

            if (_schedules.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = groupedSchedules.entries.toList()[index];
                    return _buildScheduleGroup(c, entry.key, entry.value);
                  },
                  childCount: groupedSchedules.length,
                ),
              ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TransitColorScheme c, UserRouteModel route, Color color) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            route.name,
            style: TransitTypography.heading(c.textHi),
          ),
          if (route.description != null && route.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              route.description!,
              style: TransitTypography.bodyPrimary(c.textMid),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsRow(TransitColorScheme c, UserRouteModel route) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(c, Icons.favorite, route.voteCount.toString(), 'Votos'),
          _statItem(c, Icons.visibility, route.viewCount.toString(), 'Vistas'),
          _statItem(c, Icons.place, _stops.length.toString(), 'Paradas'),
        ],
      ),
    );
  }

  Widget _statItem(TransitColorScheme c, IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: c.accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: TransitTypography.displayNumber(c.textHi),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TransitTypography.bodySmall(c.textMid),
        ),
      ],
    );
  }

  Widget _buildActionButtons(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: TransitButton(
              label: _hasVoted ? 'Quitar voto' : 'Votar',
              // TODO: l10n
              icon: _hasVoted ? Icons.favorite : Icons.favorite_border,
              isPrimary: _hasVoted,
              onPressed: _toggleVote,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TransitButton(
              label: 'Compartir',
              // TODO: l10n
              icon: Icons.share,
              isPrimary: false,
              onPressed: _openShare,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TransitButton(
              label: 'Reportar',
              // TODO: l10n
              icon: Icons.flag_outlined,
              isPrimary: false,
              onPressed: _openReport,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap(
    TransitColorScheme c,
    List<UserRouteStopModel> stops,
    Color color,
    LatLng center,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        blur: 12,
        fillOpacity: 0.04,
        borderRadius: 12,
        padding: const EdgeInsets.all(2),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            height: 220,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 13.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.transitly.app',
                ),
                MarkerLayer(
                  markers: stops.asMap().entries.map((entry) {
                    final stop = entry.value;
                    if (stop.stop == null) return const Marker(point: LatLng(0, 0), child: SizedBox());
                    final isFirst = entry.key == 0;
                    final isLast = entry.key == stops.length - 1;
                    return Marker(
                      point: LatLng(stop.stop!.lat, stop.stop!.lng),
                      width: isFirst || isLast ? 32 : 24,
                      height: isFirst || isLast ? 32 : 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isFirst
                              ? c.stateOnTime
                              : isLast
                                  ? c.stateCancelled
                                  : color,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.bgRoot, width: 2),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: c.bgRoot,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(TransitColorScheme c, String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: c.accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: TransitTypography.subheading(c.textHi),
          ),
        ],
      ),
    );
  }

  Widget _buildStopTile(
    TransitColorScheme c,
    UserRouteStopModel rs,
    int index,
  ) {
    final stop = rs.stop;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: GlassCard(
        blur: 8,
        fillOpacity: 0.03,
        borderRadius: 8,
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${index + 1}',
                style: TransitTypography.routeCodeSmall(c.accent),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop?.name ?? 'Parada ${rs.userStopId.substring(0, 8)}',
                    style: TransitTypography.routeName(c.textHi),
                  ),
                  if (stop != null)
                    Text(
                      '${stop.lat.toStringAsFixed(4)}, ${stop.lng.toStringAsFixed(4)}',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: c.textMid),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleGroup(
    TransitColorScheme c,
    String dayType,
    List<UserRouteScheduleModel> schedules,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GlassCard(
        blur: 8,
        fillOpacity: 0.03,
        borderRadius: 8,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayTypeLabel(dayType),
              style: TransitTypography.subheading(c.accent),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: schedules.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: c.accent.withValues(alpha: 0.15), width: 0.5),
                  ),
                  child: Text(
                    s.departureTime,
                    style: TransitTypography.sectionLabel(c.accent),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
