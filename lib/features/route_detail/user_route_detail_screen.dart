import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import '../../shared/models/enums.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/stop_model.dart';
import '../../shared/providers/search_selection_provider.dart';
import '../../shared/providers/user_favorites_provider.dart';
import '../../shared/providers/user_routes_for_map_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/stop_list_item.dart';
import '../../shared/widgets/transit_button.dart';
import 'widgets/route_detail_header.dart';
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
  String? _authorName;
  // false = vista "recorrido" (estilo línea oficial); true = vista "info de
  // la comunidad" (votos, importar, compartir, acciones de admin).
  bool _showInfo = false;

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

      // Nombre del creador para el badge "COMUNIDAD · <creador>". author_id
      // referencia a auth.users, así que el nombre vive en profiles.
      String? authorName;
      try {
        final prof = await ref
            .read(supabaseClientProvider)
            .from('profiles')
            .select('display_name')
            .eq('id', route.authorId)
            .maybeSingle();
        authorName = (prof?['display_name'] as String?)?.trim();
      } catch (_) {}

      setState(() {
        _route = route;
        _stops = results[1] as List<UserRouteStopModel>;
        _schedules = results[2] as List<UserRouteScheduleModel>;
        _hasVoted = voted;
        _authorName = (authorName != null && authorName.isNotEmpty)
            ? authorName
            : null;
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
      // La ruta importada pasa a ser propia → refrescamos las fuentes del
      // mapa para que aparezca su trazado y paradas sin reiniciar la app.
      ref.invalidate(communityRouteShapesProvider);
      ref.invalidate(userRoutesForMapProvider);
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
    // Fondo transparente SIEMPRE para que se vea el fondo animado global
    // (BackgroundWrapper), igual que el detalle de línea oficial de Jerez.
    final padding = ResponsiveScaffold.screenPadding(context);

    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _route == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back, color: c.textHi),
                onPressed: () => context.pop(),
              ),
              Expanded(
                child: EmptyState(
                  _error ?? 'Ruta no encontrada',
                  'La ruta solicitada no está disponible',
                  icon: Icons.error_outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final route = _route!;
    final color = _hexToColor(route.routeColor);

    final groupedSchedules = <String, List<UserRouteScheduleModel>>{};
    for (final s in _schedules) {
      groupedSchedules.putIfAbsent(s.dayType, () => []).add(s);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          ContentConstraints(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, 96),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _showInfo
                          ? _infoSlivers(c, route, color)
                          : _recorridoSlivers(c, route, color, groupedSchedules),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Botonera inferior fija: [EN EL MAPA] + [DESCARGAR] (si la ruta no
          // es tuya, para importarla a tus rutas). Si es tuya, solo el mapa.
          if (!_showInfo)
            Positioned(
              left: padding,
              right: padding,
              bottom: 16,
              child: Row(
                children: [
                  Expanded(
                    child: TransitButton(
                      label: 'EN EL MAPA',
                      icon: Icons.map_outlined,
                      isPrimary: _isOwner,
                      onPressed: () => _enMapa(route),
                    ),
                  ),
                  if (!_isOwner) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: TransitButton(
                        label: _importing ? 'Descargando…' : 'DESCARGAR',
                        icon: Icons.download_outlined,
                        isPrimary: true,
                        isLoading: _importing,
                        onPressed: _import,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Vista "recorrido": MISMO display que el detalle de línea oficial de
  /// Jerez (RouteDetailHeader + RouteQuickInfoCells + timeline), con el badge
  /// "Comunidad · creador" que ya pinta RouteSourceBadge.
  List<Widget> _recorridoSlivers(TransitColorScheme c, UserRouteModel route,
      Color color, Map<String, List<UserRouteScheduleModel>> grouped) {
    final rm = _toOfficialModel(route, color);
    final stopsCount = _stops.length;
    final estimated = route.totalDurationMin ?? (stopsCount * 3);
    return [
      const SizedBox(height: 48),
      // Cabecera: atrás + estrella favorito + info de la comunidad (iconos
      // arriba, igual que el detalle oficial). El botón grande de abajo es
      // DESCARGAR (importar) cuando la ruta no es tuya.
      Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(Icons.arrow_back, size: 24, color: c.textMid),
          ),
          const Spacer(),
          Consumer(builder: (_, r, __) {
            final isFav = r.watch(userFavoritesProvider).contains(route.id);
            return IconButton(
              icon: Icon(isFav ? Icons.star : Icons.star_border,
                  size: 22, color: c.accent),
              tooltip: isFav ? 'Quitar de favoritas' : 'Añadir a favoritas',
              onPressed: () {
                final n = r.read(userFavoritesProvider.notifier);
                isFav ? n.removeLine(route.id) : n.addLine(route.id);
              },
            );
          }),
          IconButton(
            icon: Icon(Icons.groups_outlined, size: 22, color: c.textMid),
            tooltip: 'Info de la comunidad',
            onPressed: () => setState(() => _showInfo = true),
          ),
        ],
      ),
      const SizedBox(height: 8),
      RouteDetailHeader(route: rm, activeTrip: null),
      Divider(height: 32, thickness: 0.5, color: c.border),
      RouteQuickInfoCells(
        stopsCount: stopsCount,
        estimatedMinutes: estimated,
        frequencyMinutes: null,
      ),
      const SizedBox(height: 24),
      if (_stops.isNotEmpty) _buildTimeline(c, color),
      if (_schedules.isNotEmpty) ...[
        _buildSectionTitle(c, 'Horarios', Icons.schedule),
        for (final entry in grouped.entries)
          _buildScheduleGroup(c, entry.key, entry.value),
      ],
    ];
  }

  /// Vista "info de la comunidad": stats + acciones (votar/importar/etc.).
  List<Widget> _infoSlivers(
      TransitColorScheme c, UserRouteModel route, Color color) {
    return [
      const SizedBox(height: 48),
      Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showInfo = false),
            child: Icon(Icons.arrow_back, size: 24, color: c.textMid),
          ),
          const SizedBox(width: 12),
          Text('Info de la comunidad',
              style: TransitTypography.heading(c.textHi)),
        ],
      ),
      const SizedBox(height: 16),
      _buildInfoHeader(c, route, color),
      _buildStatsRow(c, route),
      _buildActionButtons(c),
    ];
  }

  /// Construye el [RouteModel] oficial equivalente para reusar los widgets
  /// del detalle de línea de Jerez. `ownerDisplayName` alimenta el badge
  /// "Comunidad · creador".
  RouteModel _toOfficialModel(UserRouteModel route, Color color) {
    return RouteModel(
      id: route.id,
      operatorId: 'Comunidad',
      code: (route.code ?? '').isNotEmpty ? route.code! : '∙',
      name: route.name,
      serviceType: switch (route.serviceType) {
        'interurban' => ServiceType.interurban,
        'long_distance' => ServiceType.longDistance,
        'school' => ServiceType.school,
        'on_demand' => ServiceType.onDemand,
        _ => ServiceType.urban,
      },
      routeColor: color,
      source: RouteSource.community,
      status: route.status == 'community_approved'
          ? RouteStatus.official
          : RouteStatus.verified,
      ownerDisplayName: _authorName,
      lastUpdatedAt: route.updatedAt ?? route.createdAt,
    );
  }

  /// Centra el mapa en esta ruta de comunidad (igual que "EN EL MAPA" del
  /// detalle oficial) y deja la tarjeta del pin para reabrir el detalle.
  void _enMapa(UserRouteModel route) {
    final router = GoRouter.of(context);
    final withCoords = _stops.where((s) => s.stop != null).toList();
    final position = withCoords.isNotEmpty
        ? LatLng(withCoords.first.stop!.lat, withCoords.first.stop!.lng)
        : const LatLng(36.6850, -6.1376);
    ref.read(searchSelectionProvider.notifier).state = SearchSelection(
      id: 'community-${route.id}',
      position: position,
      title: (route.code ?? '').isNotEmpty ? 'Línea ${route.code}' : route.name,
      subtitle: route.name,
      icon: Icons.directions_bus,
      color: _hexToColor(route.routeColor),
      pushPath: '/community/route/${route.id}',
      routeId: route.id,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go('/home/mapa');
    });
  }

  /// Timeline de paradas estilo línea oficial (mismo `StopListItem`). Cada
  /// parada muestra la próxima hora de paso del bus (de los horarios) o
  /// "--:--" si esa parada no tiene horas registradas.
  Widget _buildTimeline(TransitColorScheme c, Color color) {
    final stops = _stops.where((s) => s.stop != null).toList();
    final hoursByStop = <String, List<String>>{};
    for (final s in _schedules) {
      if (s.originStopId == null) continue;
      (hoursByStop[s.originStopId!] ??= []).add(s.departureTime);
    }
    for (final l in hoursByStop.values) {
      l.sort();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 16, color: c.accent),
              const SizedBox(width: 8),
              Text('Recorrido',
                  style: TransitTypography.sectionTitle(c.textMid)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < stops.length; i++)
            StopListItem(
              stop: _toStopModel(stops[i]),
              scheduledTime:
                  _nextHour(hoursByStop[stops[i].userStopId]) ?? '--:--',
              isFirst: i == 0,
              isLast: i == stops.length - 1,
            ),
        ],
      ),
    );
  }

  /// Adapta una parada de comunidad a [StopModel] para reusar los widgets
  /// del detalle de línea oficial.
  StopModel _toStopModel(UserRouteStopModel rs) {
    final st = rs.stop;
    return StopModel(
      id: rs.userStopId,
      name: st?.name ?? 'Parada',
      officialCode: '',
      lat: st?.lat ?? 0,
      lng: st?.lng ?? 0,
      municipality: '',
    );
  }

  /// Próxima hora desde ahora de una lista ordenada HH:mm (o la primera de
  /// mañana si todas ya pasaron).
  String? _nextHour(List<String>? hours) {
    if (hours == null || hours.isEmpty) return null;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    for (final h in hours) {
      final p = h.split(':');
      if (p.length < 2) continue;
      final m = (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      if (m >= nowMin) return h;
    }
    return hours.first;
  }

  /// Cabecera estilo línea oficial: badge cuadrado con código + color,
  /// nombre y badge "COMUNIDAD · creador".
  /// Badge verde "COMUNIDAD · creador".
  Widget _communityBadge(String creator) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.groups_outlined,
              size: 13, color: Color(0xFF4CAF50)),
          const SizedBox(width: 5),
          Flexible(
            child: Text('COMUNIDAD · $creator',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TransitTypography.bodySmall(const Color(0xFF4CAF50))
                    .copyWith(fontSize: 10.5, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  /// Cabecera de la vista de info (más sencilla: badge + creador).
  Widget _buildInfoHeader(
      TransitColorScheme c, UserRouteModel route, Color color) {
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
          Text(route.name, style: TransitTypography.heading(c.textHi)),
          const SizedBox(height: 6),
          _communityBadge(_authorName ?? 'Comunidad'),
          if (route.description != null && route.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(route.description!,
                style: TransitTypography.bodyPrimary(c.textMid)),
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

  Widget _buildScheduleGroup(
    TransitColorScheme c,
    String dayType,
    List<UserRouteScheduleModel> schedules,
  ) {
    // Mapea cada parada a su posición/nombre para agrupar y ordenar.
    final nameOf = <String, String>{};
    final orderOf = <String, int>{};
    for (var i = 0; i < _stops.length; i++) {
      final st = _stops[i];
      nameOf[st.userStopId] = st.stop?.name ?? 'Parada ${i + 1}';
      orderOf[st.userStopId] = i;
    }

    // Agrupa las horas de este día por parada de origen.
    final byStop = <String, List<String>>{};
    final noStop = <String>[];
    for (final s in schedules) {
      if (s.originStopId != null && nameOf.containsKey(s.originStopId)) {
        byStop.putIfAbsent(s.originStopId!, () => []).add(s.departureTime);
      } else {
        noStop.add(s.departureTime);
      }
    }
    final stopIds = byStop.keys.toList()
      ..sort((a, b) => (orderOf[a] ?? 999).compareTo(orderOf[b] ?? 999));

    Widget hourChips(List<String> hours) {
      final sorted = [...hours]..sort();
      return Wrap(
        spacing: 8,
        runSpacing: 4,
        children: sorted
            .map((t) => Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: c.accent.withValues(alpha: 0.15), width: 0.5),
                  ),
                  child: Text(t,
                      style: TransitTypography.sectionLabel(c.accent)),
                ))
            .toList(),
      );
    }

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
            Text(_dayTypeLabel(dayType),
                style: TransitTypography.subheading(c.accent)),
            const SizedBox(height: 10),
            // Una sub-sección por parada con sus horas de paso.
            for (final id in stopIds) ...[
              Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Text('${(orderOf[id] ?? 0) + 1}',
                        style: TransitTypography.bodySmall(c.accent)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(nameOf[id] ?? '',
                        style: TransitTypography.bodyPrimary(c.textHi),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              hourChips(byStop[id]!),
              const SizedBox(height: 10),
            ],
            // Horas sin parada asociada (compat con datos antiguos).
            if (noStop.isNotEmpty) ...[
              if (stopIds.isNotEmpty)
                Text('Salidas',
                    style: TransitTypography.bodySmall(c.textMid)),
              const SizedBox(height: 4),
              hourChips(noStop),
            ],
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
