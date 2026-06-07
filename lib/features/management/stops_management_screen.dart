import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/transit_app_bar.dart';
import 'stop_edit_sheet.dart';

/// Gestión de paradas (admin / operator_admin).
/// Lista todas las paradas del operador con buscador y permite crear,
/// editar y borrar. Admin puede cambiar de operador.
class StopsManagementScreen extends ConsumerStatefulWidget {
  const StopsManagementScreen({super.key});

  @override
  ConsumerState<StopsManagementScreen> createState() => _State();
}

class _State extends ConsumerState<StopsManagementScreen> {
  bool _isAdmin = false;
  List<OperatorModel> _operators = const [];
  String? _operatorId;
  List<AdminStopRow> _stops = const [];
  String _query = '';
  bool _loading = true;
  bool _mapMode = false;
  String? _error;
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
      final scope = await ref.read(manageScopeProvider.future);
      _isAdmin = scope.isAdmin;
      final opRepo = ref.read(operatorRepositoryProvider);
      _operators = scope.isAdmin
          ? await opRepo.list()
          : (scope.operatorId == null
              ? const []
              : [await opRepo.byId(scope.operatorId!)]
                  .whereType<OperatorModel>()
                  .toList());
      _operatorId ??= scope.isAdmin
          ? (_operators.isNotEmpty ? _operators.first.id : null)
          : scope.operatorId;
      final stops = _operatorId == null
          ? <AdminStopRow>[]
          : await _repo.listStopsOfOperator(_operatorId!);
      if (!mounted) return;
      setState(() {
        _stops = stops;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  List<AdminStopRow> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _stops;
    return _stops
        .where((s) =>
            s.name.toLowerCase().contains(q) ||
            s.code.toLowerCase().contains(q))
        .toList();
  }

  Future<void> _create() async {
    // En modo lista usa el centro del mapa (o Jerez); en modo mapa el
    // usuario coloca tocando el mapa (ver _createAt).
    final center = _stops.isNotEmpty
        ? LatLng(_stops.first.lat, _stops.first.lng)
        : const LatLng(36.6837, -6.1366);
    await _createAt(center);
  }

  Future<void> _createAt(LatLng pos) async {
    if (_operatorId == null) return;
    final result = await showStopEditSheet(
      context: context,
      initial: AdminStopRow(
        id: '',
        operatorId: _operatorId!,
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
      await _repo.upsertStop(
        operatorId: _operatorId!,
        code: result.code,
        name: result.name,
        lat: result.lat,
        lng: result.lng,
        accessible: result.accessible,
        hasShelter: result.hasShelter,
        hasBench: result.hasBench,
      );
      await _load();
    } catch (e) {
      _toast('Error: $e');
    }
  }

  Future<void> _edit(AdminStopRow s) async {
    final result = await showStopEditSheet(context: context, initial: s);
    if (result == null) return;
    try {
      await _repo.upsertStop(
        id: result.id,
        operatorId: result.operatorId,
        code: result.code,
        name: result.name,
        lat: result.lat,
        lng: result.lng,
        accessible: result.accessible,
        hasShelter: result.hasShelter,
        hasBench: result.hasBench,
      );
      await _load();
    } catch (e) {
      _toast('Error: $e');
    }
  }

  Future<void> _delete(AdminStopRow s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar parada'),
        content: Text('¿Eliminar "${s.name}"? '
            'No se puede si pertenece a alguna línea.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await _repo.deleteStop(s.id);
      await _load();
    } catch (e) {
      _toast('No se pudo eliminar (¿está en una línea?): $e');
    }
  }

  void _toast(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: 'Gestión de paradas',
        transparent: true,
        actions: [
          IconButton(
            icon: Icon(_mapMode ? Icons.view_list : Icons.map_outlined,
                color: c.accent),
            tooltip: _mapMode ? 'Ver lista' : 'Ver mapa',
            onPressed: () => setState(() => _mapMode = !_mapMode),
          ),
          IconButton(
            icon: Icon(Icons.add_location_alt, color: c.accent),
            tooltip: 'Nueva parada',
            onPressed: _operatorId == null ? null : _create,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    _statsHeader(c),
                    if (_isAdmin && _operators.length > 1)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: _operatorSelector(c),
                      ),
                    if (!_mapMode) _searchBar(c),
                    const SizedBox(height: 6),
                    Expanded(
                      child: _mapMode
                          ? _mapView(c)
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: c.accent,
                              child: _filtered.isEmpty
                                  ? ListView(children: const [
                                      SizedBox(height: 60),
                                      EmptyState(
                                        'Sin paradas',
                                        'Crea la primera con el botón +.',
                                        icon: Icons.place_outlined,
                                      ),
                                    ])
                                  : ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 4, 16, 16),
                                      itemCount: _filtered.length,
                                      itemBuilder: (_, i) =>
                                          _stopTile(c, _filtered[i]),
                                    ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _mapView(TransitColorScheme c) {
    final pts = _filtered
        .map((s) => LatLng(s.lat, s.lng))
        .toList();
    final center = pts.isNotEmpty ? pts.first : const LatLng(36.6837, -6.1366);
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            onTap: (_, ll) async {
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
              await _createAt(ll);
            },
            interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.transitly.transitly',
            ),
            MarkerLayer(
              markers: [
                for (final s in _filtered)
                  Marker(
                    point: LatLng(s.lat, s.lng),
                    width: 32,
                    height: 32,
                    child: GestureDetector(
                      onTap: () => _stopMapMenu(s),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: c.accent,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4),
                          ],
                        ),
                        child: const Icon(Icons.directions_bus,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Hint flotante.
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _pendingMoveStopId != null
                  ? c.stateDelay.withValues(alpha: 0.95)
                  : c.bgElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: _pendingMoveStopId != null
                      ? c.stateDelay
                      : c.border,
                  width: 0.5),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, size: 16,
                    color: _pendingMoveStopId != null
                        ? Colors.white
                        : c.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pendingMoveStopId != null
                        ? 'Toca el mapa para reubicar la parada'
                        : 'Toca el mapa para crear una parada · toca un marcador para gestionarla',
                    style: TransitTypography.bodySmall(
                        _pendingMoveStopId != null
                            ? Colors.white
                            : c.textMid),
                  ),
                ),
                if (_pendingMoveStopId != null)
                  GestureDetector(
                    onTap: () => setState(() => _pendingMoveStopId = null),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _stopMapMenu(AdminStopRow s) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final c = TransitColorScheme.of(
            Theme.of(ctx).brightness == Brightness.dark);
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.bgElevated,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.border, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: Text(s.name,
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  subtitle: Text(s.code.isEmpty ? 'Sin código' : s.code,
                      style: TransitTypography.bodySmall(c.textMid)),
                ),
                Divider(height: 1, color: c.border),
                ListTile(
                  leading: Icon(Icons.edit_outlined, color: c.textHi),
                  title: Text('Editar parada',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
                ListTile(
                  leading: Icon(Icons.open_with, color: c.textHi),
                  title: Text('Mover (toca el mapa)',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                  subtitle: Text('Afecta a todas las líneas que la usan',
                      style: TransitTypography.bodySmall(c.textLo)),
                  onTap: () => Navigator.pop(ctx, 'move'),
                ),
                ListTile(
                  leading: Icon(Icons.delete_outline, color: c.stateCancelled),
                  title: Text('Eliminar parada',
                      style: TransitTypography.bodyPrimary(c.stateCancelled)),
                  onTap: () => Navigator.pop(ctx, 'delete'),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
    if (action == 'edit') {
      await _edit(s);
    } else if (action == 'move') {
      setState(() => _pendingMoveStopId = s.id);
      _toast('Toca en el mapa la nueva ubicación de la parada');
    } else if (action == 'delete') {
      await _delete(s);
    }
  }

  Widget _statsHeader(TransitColorScheme c) {
    final total = _filtered.length;
    final accesibles = _filtered.where((s) => s.accessible).length;
    final marquesina = _filtered.where((s) => s.hasShelter).length;
    final banco = _filtered.where((s) => s.hasBench).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _statPill(
                  c, Icons.place_outlined, '$total', 'Paradas', c.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.accessible, '$accesibles',
                  'Accesibles', const Color(0xFF4CAF50))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.umbrella, '$marquesina',
                  'Marquesina', const Color(0xFF2196F3))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.chair_outlined, '$banco', 'Banco',
                  c.textMid)),
        ],
      ),
    );
  }

  Widget _statPill(TransitColorScheme c, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: TransitTypography.bodyPrimary(c.textHi)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TransitTypography.bodySmall(c.textLo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _operatorSelector(TransitColorScheme c) => Container(
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _operatorId,
            isExpanded: true,
            dropdownColor: c.bgElevated,
            icon: Icon(Icons.expand_more, color: c.textMid),
            style: TransitTypography.bodyPrimary(c.textHi),
            items: _operators
                .map((o) =>
                    DropdownMenuItem(value: o.id, child: Text(o.shortName)))
                .toList(),
            onChanged: (v) {
              setState(() => _operatorId = v);
              _load();
            },
          ),
        ),
      );

  Widget _searchBar(TransitColorScheme c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Container(
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextField(
          onChanged: (v) => setState(() => _query = v),
          style: TransitTypography.bodyPrimary(c.textHi),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            icon: Icon(Icons.search, color: c.textMid, size: 20),
            hintText: 'Buscar por nombre o código',
            hintStyle: TransitTypography.bodySecondary(c.textLo),
          ),
        ),
        ),
      );

  Widget _stopTile(TransitColorScheme c, AdminStopRow s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        child: ListTile(
          leading: Icon(Icons.place_outlined, color: c.accent),
          title: Text(s.name, style: TransitTypography.bodyPrimary(c.textHi)),
          subtitle: Text(
            '${s.code.isEmpty ? 'Sin código' : s.code} · '
            '${s.lat.toStringAsFixed(4)}, ${s.lng.toStringAsFixed(4)}',
            style: TransitTypography.bodySmall(c.textMid),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (s.accessible)
                Icon(Icons.accessible, size: 16, color: c.textMid),
              IconButton(
                icon: Icon(Icons.delete_outline, color: c.stateCancelled),
                onPressed: () => _delete(s),
              ),
            ],
          ),
          onTap: () => _edit(s),
        ),
      );
}
