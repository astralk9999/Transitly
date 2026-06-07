import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  String? _error;

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
    if (_operatorId == null) return;
    final result = await showStopEditSheet(
      context: context,
      initial: AdminStopRow(
        id: '',
        operatorId: _operatorId!,
        code: '',
        name: '',
        lat: 36.6837, // centro de Jerez por defecto; reubicar en la línea
        lng: -6.1366,
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
                    _searchBar(c),
                    const SizedBox(height: 6),
                    Expanded(
                      child: RefreshIndicator(
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
