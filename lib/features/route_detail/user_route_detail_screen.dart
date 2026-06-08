import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_route_schedules_repository.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../data/user_stops/user_stops_repository.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
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
  bool _isAdmin = false;
  String? _error;

  bool get _isOwner {
    final uid = ref.read(supabaseClientProvider).auth.currentUser?.id;
    return uid != null && _route != null && _route!.authorId == uid;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _loadScope();
  }

  Future<void> _loadScope() async {
    try {
      final scope = await ref.read(manageScopeProvider.future);
      if (mounted) setState(() => _isAdmin = scope.isAdmin);
    } catch (_) {}
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

  bool _importing = false;

  Future<void> _import() async {
    if (_route == null || _importing) return;
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inicia sesión para importar rutas')));
      return;
    }
    setState(() => _importing = true);
    try {
      await repo.importRoute(_route!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Ruta importada a "Mis rutas" con sus paradas y horarios')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al importar: $e')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  // ── Acciones de admin ──────────────────────────────────────
  Future<void> _adminDelete() async {
    if (_route == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = TransitColorScheme.of(
            Theme.of(ctx).brightness == Brightness.dark);
        return AlertDialog(
          backgroundColor: c.bgElevated,
          title: const Text('Eliminar ruta'),
          content: Text(
              'Se eliminará "${_route!.name}" con sus paradas y horarios. '
              'Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Eliminar',
                    style: TextStyle(color: c.stateCancelled))),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ref.read(userRoutesRepositoryProvider)!.adminDelete(_route!.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ruta eliminada')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _openOfficialize() async {
    if (_route == null) return;
    final result = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OfficializeSheet(route: _route!),
    );
    if (result == null) return;
    try {
      await ref.read(userRoutesRepositoryProvider)!.officialize(
            routeId: _route!.id,
            operatorId: result['operatorId']!,
            zoneId: result['zoneId'],
            code: result['code'],
            color: _route!.routeColor,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Ruta oficializada y publicada')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error al oficializar: $e')));
      }
    }
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
      child: Column(
        children: [
          // El dueño puede editar su propia ruta.
          if (_isOwner) ...[
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: 'Editar ruta',
                icon: Icons.edit_outlined,
                isPrimary: true,
                onPressed: () => context
                    .push('/create-route/${_route!.id}')
                    .then((_) => _load()),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Acciones de admin (oficializar solo desde aquí, rol admin).
          if (_isAdmin) ...[
            Row(
              children: [
                Expanded(
                  child: TransitButton(
                    label: 'Oficializar',
                    icon: Icons.verified_outlined,
                    isPrimary: !_isOwner,
                    onPressed: _openOfficialize,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TransitButton(
                    label: 'Eliminar',
                    icon: Icons.delete_outline,
                    isDanger: true,
                    onPressed: _adminDelete,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Importar solo tiene sentido si NO es tu propia ruta.
          if (!_isOwner) ...[
            SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: _importing ? 'Importando…' : 'Importar a mis rutas',
                icon: Icons.download_outlined,
                isPrimary: !_isAdmin,
                isLoading: _importing,
                onPressed: _import,
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Acciones secundarias compactas (icono + etiqueta pequeña), en una
          // fila de iguales que nunca desborda.
          Row(
            children: [
              Expanded(
                child: _miniAction(
                  c,
                  icon: _hasVoted ? Icons.favorite : Icons.favorite_border,
                  label: _hasVoted ? 'Quitar voto' : 'Votar',
                  active: _hasVoted,
                  onTap: _toggleVote,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniAction(c,
                    icon: Icons.share, label: 'Compartir', onTap: _openShare),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniAction(c,
                    icon: Icons.flag_outlined,
                    label: 'Reportar',
                    onTap: _openReport),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniAction(TransitColorScheme c,
      {required IconData icon,
      required String label,
      bool active = false,
      required VoidCallback onTap}) {
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: active ? c.accent.withValues(alpha: 0.15) : c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: active ? c.accent : c.border,
              width: active ? 1.2 : 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: active ? c.accent : c.textMid),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TransitTypography.bodySmall(
                    active ? c.accent : c.textMid)),
          ],
        ),
      ),
    );
  }

  /// Si la ruta tiene trazado guardado, dibuja sus segmentos (más fiel al
  /// recorrido real); si no, une las paradas en orden con líneas rectas.
  List<Polyline> _buildRoutePolylines(
      List<UserRouteStopModel> stops, Color color) {
    final coordOf = <String, LatLng>{
      for (final s in stops)
        if (s.stop != null) s.userStopId: LatLng(s.stop!.lat, s.stop!.lng),
    };
    final path = _route?.path;
    if (path != null && path.isNotEmpty) {
      final lines = <Polyline>[];
      for (final seg in path) {
        if (seg is! Map) continue;
        final pts = <LatLng>[];
        final from = coordOf[seg['from']];
        if (from != null) pts.add(from);
        for (final p in (seg['points'] as List? ?? const [])) {
          if (p is Map) {
            pts.add(LatLng(
                (p['lat'] as num).toDouble(), (p['lng'] as num).toDouble()));
          }
        }
        final to = coordOf[seg['to']];
        if (to != null) pts.add(to);
        if (pts.length >= 2) {
          lines.add(Polyline(
              points: pts, strokeWidth: 4, color: color.withValues(alpha: 0.85)));
        }
      }
      if (lines.isNotEmpty) return lines;
    }
    // Fallback: unir paradas en orden.
    return [
      Polyline(
        points: stops
            .where((s) => s.stop != null)
            .map((s) => LatLng(s.stop!.lat, s.stop!.lng))
            .toList(),
        strokeWidth: 4,
        color: color.withValues(alpha: 0.8),
      ),
    ];
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
                  userAgentPackageName: 'com.transitly.transitly',
                ),
                // Línea de la ruta uniendo las paradas en orden.
                PolylineLayer(
                  polylines: _buildRoutePolylines(stops, color),
                ),
                MarkerLayer(
                  markers: [
                    for (final entry in stops.asMap().entries)
                      if (entry.value.stop != null)
                        Marker(
                          point: LatLng(entry.value.stop!.lat,
                              entry.value.stop!.lng),
                          width: 26,
                          height: 26,
                          child: Container(
                            decoration: BoxDecoration(
                              color: entry.key == 0
                                  ? c.stateOnTime
                                  : entry.key == stops.length - 1
                                      ? c.stateCancelled
                                      : color,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${entry.key + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                  ],
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

/// Formulario para oficializar una ruta de comunidad. Operador es
/// obligatorio (una ruta oficial debe pertenecer a una operadora); zona y
/// código son opcionales. Devuelve {operatorId, zoneId, code}.
class _OfficializeSheet extends ConsumerStatefulWidget {
  const _OfficializeSheet({required this.route});
  final UserRouteModel route;

  @override
  ConsumerState<_OfficializeSheet> createState() => _OfficializeSheetState();
}

class _OfficializeSheetState extends ConsumerState<_OfficializeSheet> {
  List<OperatorModel> _operators = const [];
  List<ZoneRow> _zones = const [];
  String? _operatorId;
  String? _zoneId;
  late final TextEditingController _code;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.route.code ?? '');
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ops = await ref.read(operatorRepositoryProvider).list();
      final zones = await ref.read(adminRoutesRepositoryProvider).listZones();
      if (!mounted) return;
      setState(() {
        _operators = ops;
        _zones = zones;
        _operatorId = ops.isNotEmpty ? ops.first.id : null;
        _zoneId = zones.isNotEmpty ? zones.first.id : null;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Crea una zona nueva al vuelo (admin) y la selecciona.
  Future<void> _createZone() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nueva zona'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
              labelText: 'Nombre', hintText: 'p.ej. El Puerto de Santa María'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Crear')),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      final repo = ref.read(adminRoutesRepositoryProvider);
      final id = await repo.zoneUpsert(name: name);
      final zones = await repo.listZones();
      if (mounted) {
        setState(() {
          _zones = zones;
          _zoneId = id;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: SafeArea(
          top: false,
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.verified_outlined, color: c.accent),
                          const SizedBox(width: 8),
                          Text('Oficializar ruta',
                              style: TransitTypography.heading(c.textHi)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                          'Se creará la línea oficial con sus paradas y horarios, '
                          'y se retirará la versión comunitaria.',
                          style: TransitTypography.bodySmall(c.textMid)),
                      const SizedBox(height: 16),
                      _label(c, 'Operador (obligatorio)'),
                      const SizedBox(height: 6),
                      _dropdown<String>(
                        c,
                        value: _operatorId,
                        hint: 'Selecciona operador',
                        items: _operators
                            .map((o) => DropdownMenuItem(
                                value: o.id, child: Text(o.shortName)))
                            .toList(),
                        onChanged: (v) => setState(() => _operatorId = v),
                      ),
                      const SizedBox(height: 14),
                      _label(c, 'Zona (opcional)'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: _dropdown<String>(
                              c,
                              value: _zoneId,
                              hint: 'Sin zona',
                              items: [
                                const DropdownMenuItem(
                                    value: null, child: Text('Sin zona')),
                                ..._zones.map((z) => DropdownMenuItem(
                                    value: z.id, child: Text(z.name))),
                              ],
                              onChanged: (v) => setState(() => _zoneId = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: c.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _createZone,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Icon(Icons.add_location_alt_outlined,
                                    color: c.accent),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _label(c, 'Código de línea (opcional)'),
                      const SizedBox(height: 6),
                      Container(
                        decoration: BoxDecoration(
                          color: c.bgRaised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: c.border, width: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          controller: _code,
                          style: TransitTypography.bodyPrimary(c.textHi),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 14),
                            hintText: 'p.ej. L1',
                            hintStyle: TransitTypography.bodySmall(c.textLo),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: c.accent),
                              onPressed: _operatorId == null
                                  ? null
                                  : () => Navigator.pop(context, {
                                        'operatorId': _operatorId,
                                        'zoneId': _zoneId,
                                        'code': _code.text.trim().isEmpty
                                            ? null
                                            : _code.text.trim(),
                                      }),
                              child: const Text('Oficializar'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _label(TransitColorScheme c, String t) =>
      Text(t, style: TransitTypography.bodyPrimary(c.textHi));

  Widget _dropdown<T>(
    TransitColorScheme c, {
    required T? value,
    required String hint,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.bgElevated,
          icon: Icon(Icons.expand_more, color: c.textMid),
          style: TransitTypography.bodyPrimary(c.textHi),
          hint: Text(hint, style: TransitTypography.bodySecondary(c.textLo)),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
