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

/// Editor de paradas de una ruta.
/// - Mapa con marcadores de las paradas de la ruta en la direction
///   activa.
/// - Lista reordenable abajo (drag&drop para cambiar `sequence`).
/// - Tap en el mapa muestra modal para añadir parada existente (de las
///   del mismo operador) o crear una nueva en esas coordenadas.
/// - Tap en marcador permite editar nombre, código, accesibilidad y
///   moverla.
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
  final _mapController = MapController();

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
      final repo = ref.read(adminRoutesRepositoryProvider);
      final r = await repo.getRoute(widget.routeId);
      if (r == null) throw 'Ruta no encontrada';
      final rs = await repo.listRouteStops(widget.routeId);
      final stops = await repo.listStopsOfOperator(r.operatorId);
      if (!mounted) return;
      setState(() {
        _route = r;
        _routeStops = rs;
        _operatorStops = stops;
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
      _mapController.move(const LatLng(36.6837, -6.1366), 13); // Jerez fallback
      return;
    }
    if (pts.length == 1) {
      _mapController.move(pts.first, 15);
      return;
    }
    final bounds = LatLngBounds.fromPoints(pts);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
    );
  }

  Future<void> _onMapTap(TapPosition _, LatLng latlng) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.add_location_alt),
                  title: const Text('Crear nueva parada aquí'),
                  onTap: () => Navigator.pop(ctx, 'create'),
                ),
                ListTile(
                  leading: const Icon(Icons.list),
                  title: const Text('Añadir parada existente'),
                  onTap: () => Navigator.pop(ctx, 'pick'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == 'create') {
      await _createNewStopAt(latlng);
    } else if (choice == 'pick') {
      await _pickExistingStop();
    }
  }

  Future<void> _createNewStopAt(LatLng pos) async {
    final result = await _editStopDialog(
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
      final repo = ref.read(adminRoutesRepositoryProvider);
      final newId = await repo.upsertStop(
        operatorId: _route!.operatorId,
        code: result.code,
        name: result.name,
        lat: result.lat,
        lng: result.lng,
        accessible: result.accessible,
        hasShelter: result.hasShelter,
        hasBench: result.hasBench,
      );
      await repo.addStopToRoute(
        routeId: widget.routeId,
        stopId: newId,
        sequence: _stopsForDir.length + 1,
        direction: _direction,
      );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _pickExistingStop() async {
    final attached = _stopsForDir.map((s) => s.stopId).toSet();
    final available =
        _operatorStops.where((s) => !attached.contains(s.id)).toList();
    final picked = await showModalBottomSheet<AdminStopRow>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (ctx, scroll) => Padding(
            padding: const EdgeInsets.all(12),
            child: GlassCard(
              blur: 24,
              fillOpacity: 0.10,
              borderRadius: 18,
              padding: const EdgeInsets.all(8),
              child: available.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                            'No quedan paradas libres del operador. Crea una nueva tocando el mapa.'),
                      ),
                    )
                  : ListView.builder(
                      controller: scroll,
                      itemCount: available.length,
                      itemBuilder: (_, i) {
                        final s = available[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(s.name),
                          subtitle: Text(s.code.isEmpty ? '—' : s.code),
                          onTap: () => Navigator.pop(ctx, s),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    try {
      await ref.read(adminRoutesRepositoryProvider).addStopToRoute(
            routeId: widget.routeId,
            stopId: picked.id,
            sequence: _stopsForDir.length + 1,
            direction: _direction,
          );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<AdminStopRow?> _editStopDialog({required AdminStopRow initial}) async {
    final code = TextEditingController(text: initial.code);
    final name = TextEditingController(text: initial.name);
    var accessible = initial.accessible;
    var shelter = initial.hasShelter;
    var bench = initial.hasBench;
    var lat = initial.lat;
    var lng = initial.lng;
    final res = await showDialog<AdminStopRow>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return StatefulBuilder(builder: (ctx, setS) {
          return AlertDialog(
            title: Text(initial.id.isEmpty ? 'Nueva parada' : 'Editar parada'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Código'),
                  ),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 8),
                  Text('Lat: ${lat.toStringAsFixed(6)}, '
                      'Lng: ${lng.toStringAsFixed(6)}',
                      style: TransitTypography.bodySmall(c.textMid)),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Accesible silla de ruedas'),
                    value: accessible,
                    onChanged: (v) => setS(() => accessible = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Marquesina'),
                    value: shelter,
                    onChanged: (v) => setS(() => shelter = v),
                  ),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Banco'),
                    value: bench,
                    onChanged: (v) => setS(() => bench = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  AdminStopRow(
                    id: initial.id,
                    operatorId: initial.operatorId,
                    code: code.text.trim(),
                    name: name.text.trim(),
                    lat: lat,
                    lng: lng,
                    accessible: accessible,
                    hasShelter: shelter,
                    hasBench: bench,
                  ),
                ),
                child: const Text('Guardar'),
              ),
            ],
          );
        });
      },
    );
    return res;
  }

  Future<void> _tapMarker(AdminRouteStopRow rs) async {
    if (rs.stop == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(rs.stop!.name),
                  subtitle: Text(
                      'Secuencia ${rs.sequence}${rs.stop!.code.isEmpty ? '' : ' · ${rs.stop!.code}'}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar parada'),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                ListTile(
                  leading: const Icon(Icons.open_with),
                  title: const Text('Mover (toca el mapa)'),
                  onTap: () => Navigator.pop(ctx, 'move'),
                ),
                ListTile(
                  leading: const Icon(Icons.link_off),
                  title: const Text('Quitar de la línea'),
                  onTap: () => Navigator.pop(ctx, 'detach'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (action == 'edit') {
      final upd = await _editStopDialog(initial: rs.stop!);
      if (upd != null) {
        try {
          await ref.read(adminRoutesRepositoryProvider).upsertStop(
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
          if (mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      }
    } else if (action == 'move') {
      setState(() => _pendingMoveStopId = rs.stopId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Toca en el mapa la nueva ubicación'),
        duration: Duration(seconds: 3),
      ));
    } else if (action == 'detach') {
      try {
        await ref.read(adminRoutesRepositoryProvider).removeStopFromRoute(
              routeId: widget.routeId,
              stopId: rs.stopId,
              direction: rs.direction,
            );
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  String? _pendingMoveStopId;

  Future<void> _persistOrder() async {
    final pairs = _stopsForDir
        .asMap()
        .entries
        .map((e) =>
            (stopId: e.value.stopId, sequence: e.key + 1))
        .toList();
    try {
      await ref.read(adminRoutesRepositoryProvider).reorderStops(
            routeId: widget.routeId,
            direction: _direction,
            pairs: pairs,
          );
      await _load();
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
    final routeColor = _parseHex(_route?.color) ?? c.accent;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: 'Paradas · ${_route?.code ?? ''}',
        transparent: true,
      ),
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
                              tooltip: 'Centrar en paradas',
                              onPressed: _fitToStops,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 280,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              initialCenter:
                                  const LatLng(36.6837, -6.1366),
                              initialZoom: 13,
                              onTap: (tp, ll) async {
                                if (_pendingMoveStopId != null) {
                                  final id = _pendingMoveStopId!;
                                  setState(() => _pendingMoveStopId = null);
                                  try {
                                    await ref
                                        .read(adminRoutesRepositoryProvider)
                                        .moveStop(id, ll.latitude,
                                            ll.longitude);
                                    await _load();
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text('Error: $e')));
                                    }
                                  }
                                  return;
                                }
                                await _onMapTap(tp, ll);
                              },
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.all &
                                    ~InteractiveFlag.rotate,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName:
                                    'com.transitly.transitly',
                              ),
                              PolylineLayer(polylines: [
                                Polyline(
                                  points: _stopsForDir
                                      .where((s) => s.stop != null)
                                      .map((s) =>
                                          LatLng(s.stop!.lat, s.stop!.lng))
                                      .toList(),
                                  strokeWidth: 4,
                                  color: routeColor.withValues(alpha: 0.7),
                                ),
                              ]),
                              MarkerLayer(
                                markers: _stopsForDir
                                    .where((s) => s.stop != null)
                                    .map((rs) {
                                  return Marker(
                                    point:
                                        LatLng(rs.stop!.lat, rs.stop!.lng),
                                    width: 36,
                                    height: 36,
                                    child: GestureDetector(
                                      onTap: () => _tapMarker(rs),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: routeColor,
                                          border: Border.all(
                                              color: Colors.white,
                                              width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          '${rs.sequence}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700),
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
                      const SizedBox(height: 12),
                      if (_pendingMoveStopId != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  child: Text(
                                      'Toca el mapa donde quieres reubicar la parada'),
                                ),
                                TextButton(
                                  onPressed: () => setState(
                                      () => _pendingMoveStopId = null),
                                  child: const Text('Cancelar'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      Expanded(
                        child: _stopsForDir.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Aún no hay paradas en esta dirección. Toca el mapa para añadirlas.',
                                    textAlign: TextAlign.center,
                                    style: TransitTypography.bodySecondary(
                                        c.textMid),
                                  ),
                                ),
                              )
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: _stopsForDir.length,
                                onReorder: (oldI, newI) async {
                                  if (newI > oldI) newI--;
                                  setState(() {
                                    final list = [..._routeStops];
                                    final dirList = _stopsForDir;
                                    final item = dirList.removeAt(oldI);
                                    dirList.insert(newI, item);
                                    list.removeWhere(
                                        (s) => s.direction == _direction);
                                    list.addAll(dirList.asMap().entries.map(
                                        (e) => AdminRouteStopRow(
                                              routeId: e.value.routeId,
                                              stopId: e.value.stopId,
                                              sequence: e.key + 1,
                                              direction: e.value.direction,
                                              stop: e.value.stop,
                                            )));
                                    _routeStops = list;
                                  });
                                  await _persistOrder();
                                },
                                itemBuilder: (_, i) {
                                  final rs = _stopsForDir[i];
                                  return Padding(
                                    key: ValueKey('${rs.stopId}-$i'),
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: GlassCard(
                                      blur: 12,
                                      fillOpacity: 0.06,
                                      borderRadius: 12,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: routeColor,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '${rs.sequence}',
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight:
                                                      FontWeight.w700),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(rs.stop?.name ?? '—',
                                                    style: TransitTypography
                                                        .bodyPrimary(
                                                            c.textHi),
                                                    maxLines: 1,
                                                    overflow: TextOverflow
                                                        .ellipsis),
                                                if ((rs.stop?.code ?? '')
                                                    .isNotEmpty)
                                                  Text(rs.stop!.code,
                                                      style: TransitTypography
                                                          .bodySmall(
                                                              c.textMid)),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon:
                                                const Icon(Icons.more_vert),
                                            onPressed: () =>
                                                _tapMarker(rs),
                                          ),
                                          ReorderableDragStartListener(
                                            index: i,
                                            child: Padding(
                                              padding: const EdgeInsets
                                                  .symmetric(horizontal: 6),
                                              child: Icon(Icons.drag_handle,
                                                  color: c.textMid),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _loading || _route == null
          ? null
          : FloatingActionButton.extended(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              onPressed: _pickExistingStop,
              icon: const Icon(Icons.add),
              label: const Text('Añadir parada'),
            ),
    );
  }

  Widget _dirPill(TransitColorScheme c, int dir, String label) => Pressable(
        onTap: () {
          setState(() => _direction = dir);
          _fitToStops();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _direction == dir
                ? c.accent.withValues(alpha: 0.25)
                : c.bgRaised.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _direction == dir ? c.accent : c.border),
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
