import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'stop_edit_sheet.dart';

/// Editor de paradas de una ruta.
/// - Mapa con polilínea + marcadores numerados de la dirección activa.
/// - Lista reordenable; el nuevo orden se aplica al pulsar "Guardar orden"
///   (no se recarga la página en cada arrastre).
/// - Añadir parada con buscador y opción de crear una nueva al momento.
/// - Las paradas son compartidas: mover/editar una afecta a todas las
///   líneas que pasan por ella.
class RouteStopsEditorScreen extends ConsumerStatefulWidget {
  const RouteStopsEditorScreen({super.key, required this.routeId});
  final String routeId;

  @override
  ConsumerState<RouteStopsEditorScreen> createState() => _State();
}

class _State extends ConsumerState<RouteStopsEditorScreen> {
  int _direction = 0; // 0 ida, 1 vuelta
  AdminRouteRow? _route;
  List<AdminRouteStopRow> _routeStops = const [];
  List<AdminStopRow> _operatorStops = const [];
  bool _loading = true;
  String? _error;
  bool _orderDirty = false;
  String? _pendingMoveStopId;
  final _mapController = MapController();

  AdminRoutesRepository get _repo => ref.read(adminRoutesRepositoryProvider);

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
    try {
      final r = await _repo.getRoute(widget.routeId);
      if (r == null) throw 'Ruta no encontrada';
      final rs = await _repo.listRouteStops(widget.routeId);
      final stops = await _repo.listStopsOfOperator(r.operatorId);
      if (!mounted) return;
      setState(() {
        _route = r;
        _routeStops = rs;
        _operatorStops = stops;
        _orderDirty = false;
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitToStops());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<AdminRouteStopRow> get _stopsForDir =>
      _routeStops.where((s) => s.direction == _direction).toList()
        ..sort((a, b) => a.sequence.compareTo(b.sequence));

  void _fitToStops() {
    final pts = _stopsForDir
        .where((s) => s.stop != null)
        .map((s) => LatLng(s.stop!.lat, s.stop!.lng))
        .toList();
    if (pts.isEmpty) {
      _mapController.move(const LatLng(36.6837, -6.1366), 13);
      return;
    }
    if (pts.length == 1) {
      _mapController.move(pts.first, 15);
      return;
    }
    _mapController.fitCamera(
      CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(pts),
          padding: const EdgeInsets.all(60)),
    );
  }

  // ── Solid bottom-sheet helper (no transparente) ──
  Future<T?> _sheet<T>(Widget Function(BuildContext, TransitColorScheme) body) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return Container(
          decoration: BoxDecoration(
            color: c.bgElevated,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: c.border, width: 0.5),
          ),
          child: SafeArea(top: false, child: body(ctx, c)),
        );
      },
    );
  }

  // ── Añadir parada: buscador + crear nueva ──
  Future<void> _addStopFlow() async {
    final attached = _stopsForDir.map((s) => s.stopId).toSet();
    final action = await _sheet<String>((ctx, c) {
      final searchCtrl = TextEditingController();
      var query = '';
      return StatefulBuilder(builder: (ctx, setS) {
        final available = _operatorStops
            .where((s) => !attached.contains(s.id))
            .where((s) =>
                query.isEmpty ||
                s.name.toLowerCase().contains(query) ||
                s.code.toLowerCase().contains(query))
            .toList();
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                  child: Row(
                    children: [
                      Text('Añadir parada',
                          style: TransitTypography.heading(c.textHi)),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: c.accent),
                        onPressed: () => Navigator.pop(ctx, 'create'),
                        icon: const Icon(Icons.add_location_alt, size: 16),
                        label: const Text('Nueva'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: c.bgRaised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: c.border, width: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: searchCtrl,
                      autofocus: false,
                      onChanged: (v) =>
                          setS(() => query = v.toLowerCase().trim()),
                      style: TransitTypography.bodyPrimary(c.textHi),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        icon: Icon(Icons.search, color: c.textMid, size: 20),
                        hintText: 'Buscar parada por nombre o código',
                        hintStyle: TransitTypography.bodySecondary(c.textLo),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: available.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              query.isEmpty
                                  ? 'No quedan paradas libres. Crea una nueva.'
                                  : 'Sin resultados para "$query".',
                              textAlign: TextAlign.center,
                              style:
                                  TransitTypography.bodySecondary(c.textMid),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: available.length,
                          itemBuilder: (_, i) {
                            final s = available[i];
                            return ListTile(
                              leading: Icon(Icons.place_outlined,
                                  color: c.textMid),
                              title: Text(s.name,
                                  style:
                                      TransitTypography.bodyPrimary(c.textHi)),
                              subtitle: Text(s.code.isEmpty ? '—' : s.code,
                                  style:
                                      TransitTypography.bodySmall(c.textMid)),
                              onTap: () => Navigator.pop(ctx, 'pick:${s.id}'),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      });
    });
    if (action == null) return;
    if (action == 'create') {
      await _createNewStopAt(_mapController.camera.center);
    } else if (action.startsWith('pick:')) {
      final stopId = action.substring(5);
      await _attachStop(stopId);
    }
  }

  Future<void> _attachStop(String stopId) async {
    try {
      await _repo.addStopToRoute(
        routeId: widget.routeId,
        stopId: stopId,
        sequence: _stopsForDir.length + 1,
        direction: _direction,
      );
      await _load();
    } catch (e) {
      _toast('Error: $e');
    }
  }

  Future<void> _createNewStopAt(LatLng pos) async {
    final result = await showStopEditSheet(
      context: context,
      initial: AdminStopRow(
        id: '',
        operatorId: _route!.operatorId,
        code: '',
        name: '',
        lat: pos.latitude,
        lng: pos.longitude,
        accessible: false,
        hasShelter: false,
        hasBench: false,
      ),
    );
    if (result == null) return;
    try {
      final newId = await _repo.upsertStop(
        operatorId: _route!.operatorId,
        code: result.code,
        name: result.name,
        lat: result.lat,
        lng: result.lng,
        accessible: result.accessible,
        hasShelter: result.hasShelter,
        hasBench: result.hasBench,
      );
      await _repo.addStopToRoute(
        routeId: widget.routeId,
        stopId: newId,
        sequence: _stopsForDir.length + 1,
        direction: _direction,
      );
      await _load();
    } catch (e) {
      _toast('Error: $e');
    }
  }

  // ── Menú de una parada (3 puntos) ──
  Future<void> _stopMenu(AdminRouteStopRow rs) async {
    if (rs.stop == null) return;
    final action = await _sheet<String>((ctx, c) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(rs.stop!.name,
                  style: TransitTypography.bodyPrimary(c.textHi)),
              subtitle: Text(
                  'Secuencia ${rs.sequence}'
                  '${rs.stop!.code.isEmpty ? '' : ' · ${rs.stop!.code}'}',
                  style: TransitTypography.bodySmall(c.textMid)),
            ),
            Divider(height: 1, color: c.border),
            ListTile(
              leading: Icon(Icons.edit_outlined, color: c.textHi),
              title: const Text('Editar parada'),
              subtitle: Text('Afecta a todas las líneas que la usan',
                  style: TransitTypography.bodySmall(c.textLo)),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: Icon(Icons.open_with, color: c.textHi),
              title: const Text('Mover (toca el mapa)'),
              subtitle: Text('Reubica la parada en todas sus líneas',
                  style: TransitTypography.bodySmall(c.textLo)),
              onTap: () => Navigator.pop(ctx, 'move'),
            ),
            ListTile(
              leading: Icon(Icons.link_off, color: c.stateCancelled),
              title: const Text('Quitar de esta línea'),
              onTap: () => Navigator.pop(ctx, 'detach'),
            ),
            const SizedBox(height: 8),
          ],
        ));
    if (action == 'edit') {
      final upd = await showStopEditSheet(context: context, initial: rs.stop!);
      if (upd != null) {
        try {
          await _repo.upsertStop(
            id: upd.id,
            operatorId: upd.operatorId,
            code: upd.code,
            name: upd.name,
            lat: upd.lat,
            lng: upd.lng,
            accessible: upd.accessible,
            hasShelter: upd.hasShelter,
            hasBench: upd.hasBench,
          );
          await _load();
        } catch (e) {
          _toast('Error: $e');
        }
      }
    } else if (action == 'move') {
      setState(() => _pendingMoveStopId = rs.stopId);
      _toast('Toca en el mapa la nueva ubicación');
    } else if (action == 'detach') {
      try {
        await _repo.removeStopFromRoute(
            routeId: widget.routeId,
            stopId: rs.stopId,
            direction: rs.direction);
        await _load();
      } catch (e) {
        _toast('Error: $e');
      }
    }
  }

  // ── Reordenado diferido ──
  void _onReorder(int oldI, int newI) {
    if (newI > oldI) newI--;
    setState(() {
      final dirList = _stopsForDir;
      final item = dirList.removeAt(oldI);
      dirList.insert(newI, item);
      final rebuilt = [
        for (var i = 0; i < dirList.length; i++)
          AdminRouteStopRow(
            routeId: dirList[i].routeId,
            stopId: dirList[i].stopId,
            sequence: i + 1,
            direction: dirList[i].direction,
            stop: dirList[i].stop,
          )
      ];
      _routeStops = [
        ..._routeStops.where((s) => s.direction != _direction),
        ...rebuilt,
      ];
      _orderDirty = true;
    });
  }

  Future<void> _saveOrder() async {
    final pairs = _stopsForDir
        .asMap()
        .entries
        .map((e) => (stopId: e.value.stopId, sequence: e.key + 1))
        .toList();
    try {
      await _repo.reorderStops(
          routeId: widget.routeId, direction: _direction, pairs: pairs);
      if (mounted) setState(() => _orderDirty = false);
      _toast('Orden guardado');
    } catch (e) {
      _toast('Error: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final routeColor = _parseHex(_route?.color) ?? c.accent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
          title: 'Paradas · ${_route?.code ?? ''}', transparent: true),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            _dirPill(c, 0, 'Ida'),
                            const SizedBox(width: 8),
                            _dirPill(c, 1, 'Vuelta'),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.center_focus_strong),
                              tooltip: 'Centrar',
                              onPressed: _fitToStops,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 260, child: _map(c, routeColor)),
                      if (_pendingMoveStopId != null) _moveBanner(c),
                      Expanded(child: _list(c, routeColor)),
                      if (_orderDirty) _saveOrderBar(c),
                    ],
                  ),
      ),
      floatingActionButton: _loading || _route == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              onPressed: _addStopFlow,
              icon: const Icon(Icons.add),
              label: const Text('Añadir parada'),
            ),
    );
  }

  Widget _map(TransitColorScheme c, Color routeColor) {
    final pts = _stopsForDir
        .where((s) => s.stop != null)
        .map((s) => LatLng(s.stop!.lat, s.stop!.lng))
        .toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: const LatLng(36.6837, -6.1366),
          initialZoom: 13,
          onTap: (tp, ll) async {
            if (_pendingMoveStopId != null) {
              final id = _pendingMoveStopId!;
              setState(() => _pendingMoveStopId = null);
              try {
                await _repo.moveStop(id, ll.latitude, ll.longitude);
                await _load();
              } catch (e) {
                _toast('Error: $e');
              }
              return;
            }
            await _createNewStopAt(ll);
          },
          interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.transitly.transitly',
          ),
          PolylineLayer(polylines: [
            Polyline(
                points: pts,
                strokeWidth: 4,
                color: routeColor.withValues(alpha: 0.7)),
          ]),
          MarkerLayer(
            markers: [
              for (final rs in _stopsForDir.where((s) => s.stop != null))
                Marker(
                  point: LatLng(rs.stop!.lat, rs.stop!.lng),
                  width: 34,
                  height: 34,
                  child: GestureDetector(
                    onTap: () => _stopMenu(rs),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: routeColor,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text('${rs.sequence}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moveBanner(TransitColorScheme c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: c.stateDelay.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.stateDelay),
          ),
          child: Row(
            children: [
              Icon(Icons.touch_app, color: c.stateDelay),
              const SizedBox(width: 8),
              const Expanded(
                  child: Text('Toca el mapa para reubicar la parada')),
              TextButton(
                onPressed: () => setState(() => _pendingMoveStopId = null),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      );

  Widget _list(TransitColorScheme c, Color routeColor) {
    final stops = _stopsForDir;
    if (stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin paradas en esta dirección.\nUsa "Añadir parada" o toca el mapa.',
            textAlign: TextAlign.center,
            style: TransitTypography.bodySecondary(c.textMid),
          ),
        ),
      );
    }
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: stops.length,
      onReorder: _onReorder,
      itemBuilder: (_, i) {
        final rs = stops[i];
        return Padding(
          key: ValueKey('${rs.stopId}-${rs.direction}'),
          padding: const EdgeInsets.only(bottom: 8),
          child: GlassCard(
            blur: 12,
            fillOpacity: 0.06,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration:
                      BoxDecoration(color: routeColor, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${rs.sequence}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rs.stop?.name ?? '—',
                          style: TransitTypography.bodyPrimary(c.textHi),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if ((rs.stop?.code ?? '').isNotEmpty)
                        Text(rs.stop!.code,
                            style: TransitTypography.bodySmall(c.textMid)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _stopMenu(rs)),
                ReorderableDragStartListener(
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.drag_handle, color: c.textMid),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _saveOrderBar(TransitColorScheme c) => Container(
        color: c.bgElevated,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: c.textMid),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Has cambiado el orden',
                  style: TransitTypography.bodySmall(c.textMid)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: c.accent),
              onPressed: _saveOrder,
              icon: const Icon(Icons.save, size: 16),
              label: const Text('Guardar orden'),
            ),
          ],
        ),
      );

  Widget _dirPill(TransitColorScheme c, int dir, String label) => Pressable(
        onTap: () {
          setState(() => _direction = dir);
          _fitToStops();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color:
                _direction == dir ? c.accent.withValues(alpha: 0.18) : c.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _direction == dir ? c.accent : c.border,
                width: _direction == dir ? 1.2 : 0.5),
          ),
          child: Text(label,
              style: TransitTypography.bodySmall(
                  _direction == dir ? c.accent : c.textMid)),
        ),
      );

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
