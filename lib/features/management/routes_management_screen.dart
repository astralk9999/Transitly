import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Pantalla común admin/operator_admin para gestionar líneas.
/// - Admin: ve todas las rutas, puede filtrar por operador.
/// - Operator_admin: solo las de su operador (filtrado automático).
class RoutesManagementScreen extends ConsumerStatefulWidget {
  const RoutesManagementScreen({super.key});

  @override
  ConsumerState<RoutesManagementScreen> createState() => _State();
}

enum _SortBy { code, status, updated, stops }

class _State extends ConsumerState<RoutesManagementScreen> {
  String _query = '';
  String? _filterOperatorId;
  RouteStatus? _filterStatus;
  _SortBy _sortBy = _SortBy.code;
  bool _groupByOperator = false;
  final Set<String> _collapsedOps = {};
  List<AdminRouteRow> _all = const [];
  List<OperatorModel> _operators = const [];
  bool _loading = true;
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
    try {
      final scope = await ref.read(manageScopeProvider.future);
      final repo = ref.read(adminRoutesRepositoryProvider);
      final opRepo = ref.read(operatorRepositoryProvider);
      final opId = scope.isAdmin ? null : scope.operatorId;
      final routes = await repo.listRoutes(operatorId: opId);
      final ops = scope.isAdmin
          ? await opRepo.list()
          : (opId == null
              ? const <OperatorModel>[]
              : [await opRepo.byId(opId)].whereType<OperatorModel>().toList());
      if (!mounted) return;
      setState(() {
        _all = routes;
        _operators = ops;
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

  List<AdminRouteRow> get _filtered {
    final q = _query.trim().toLowerCase();
    final list = _all.where((r) {
      if (_filterOperatorId != null && r.operatorId != _filterOperatorId) {
        return false;
      }
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (q.isEmpty) return true;
      return r.code.toLowerCase().contains(q) ||
          r.name.toLowerCase().contains(q);
    }).toList();
    list.sort(_compare);
    return list;
  }

  /// Orden estable según [_sortBy]. El código se ordena de forma natural
  /// (L2 antes que L10) extrayendo el número.
  int _compare(AdminRouteRow a, AdminRouteRow b) {
    switch (_sortBy) {
      case _SortBy.code:
        return _codeKey(a.code).compareTo(_codeKey(b.code));
      case _SortBy.status:
        final s = a.status.index.compareTo(b.status.index);
        return s != 0 ? s : _codeKey(a.code).compareTo(_codeKey(b.code));
      case _SortBy.updated:
        final da = a.updatedAt ?? DateTime(1970);
        final db = b.updatedAt ?? DateTime(1970);
        return db.compareTo(da); // más reciente primero
      case _SortBy.stops:
        final s = b.stopCount.compareTo(a.stopCount);
        return s != 0 ? s : _codeKey(a.code).compareTo(_codeKey(b.code));
    }
  }

  /// Clave de orden natural: "L10" -> (0010, "L10"), "LEI" -> (9999, "LEI").
  String _codeKey(String code) {
    final m = RegExp(r'(\d+)').firstMatch(code);
    final n = m != null ? int.parse(m.group(1)!) : 9999;
    return '${n.toString().padLeft(4, '0')}_$code';
  }

  String _operatorName(String id) =>
      _operators.firstWhere((o) => o.id == id,
          orElse: () => OperatorModel(
              id: id, name: id, shortName: id, slug: '', region: '')).shortName;

  Future<void> _createRoute() async {
    final scope = await ref.read(manageScopeProvider.future);
    if (!mounted) return;
    final String? operatorId = scope.isAdmin
        ? (_operators.isNotEmpty ? _operators.first.id : null)
        : scope.operatorId;
    if (operatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un operador primero')));
      return;
    }
    await context
        .push('/management/routes/new?operator=$operatorId');
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TransitAppBar(title: 'Gestión de líneas', transparent: true),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          textAlign: TextAlign.center,
                          style: TransitTypography.bodySecondary(c.textMid)),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _searchBar(c),
                        const SizedBox(height: 12),
                        _filters(c),
                        const SizedBox(height: 8),
                        _summaryBar(c),
                        const SizedBox(height: 12),
                        if (_filtered.isEmpty)
                          const EmptyState(
                            'Sin líneas',
                            'Crea la primera con el botón de abajo.',
                            icon: Icons.alt_route,
                          )
                        else if (_groupByOperator && _operators.length > 1)
                          ..._buildGrouped(c)
                        else
                          ..._filtered.map((r) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _routeCard(c, r),
                              )),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        onPressed: _createRoute,
        icon: const Icon(Icons.add),
        label: const Text('Nueva línea'),
      ),
    );
  }

  Widget _searchBar(TransitColorScheme c) => GlassCard(
        blur: 14,
        fillOpacity: 0.06,
        borderRadius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          decoration: InputDecoration(
            border: InputBorder.none,
            icon: Icon(Icons.search, color: c.textMid, size: 20),
            hintText: 'Buscar por código o nombre',
            hintStyle: TransitTypography.bodySecondary(c.textLo),
          ),
          style: TransitTypography.bodyPrimary(c.textHi),
          onChanged: (v) => setState(() => _query = v),
        ),
      );

  Widget _filters(TransitColorScheme c) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_operators.length > 1)
            _chip(
              c,
              label: _filterOperatorId == null
                  ? 'Todos los operadores'
                  : _operatorName(_filterOperatorId!),
              icon: Icons.business,
              onTap: _pickOperatorFilter,
            ),
          _chip(
            c,
            label: _filterStatus?.label ?? 'Cualquier estado',
            icon: Icons.flag_outlined,
            onTap: _pickStatusFilter,
          ),
          _chip(
            c,
            label: _sortLabel(_sortBy),
            icon: Icons.sort,
            onTap: _pickSort,
          ),
          if (_operators.length > 1)
            _chip(
              c,
              label: _groupByOperator ? 'Agrupado' : 'Sin agrupar',
              icon: Icons.layers_outlined,
              selected: _groupByOperator,
              onTap: () =>
                  setState(() => _groupByOperator = !_groupByOperator),
            ),
          if (_filterOperatorId != null || _filterStatus != null)
            _chip(
              c,
              label: 'Limpiar',
              icon: Icons.clear,
              onTap: () => setState(() {
                _filterOperatorId = null;
                _filterStatus = null;
              }),
            ),
        ],
      );

  String _sortLabel(_SortBy s) => switch (s) {
        _SortBy.code => 'Código',
        _SortBy.status => 'Estado',
        _SortBy.updated => 'Recientes',
        _SortBy.stops => 'Más paradas',
      };

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_SortBy>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return SafeArea(
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _SortBy.values
                  .map((s) => ListTile(
                        leading: Icon(Icons.sort, color: c.textMid),
                        title: Text('Ordenar por: ${_sortLabel(s)}'),
                        trailing: _sortBy == s
                            ? Icon(Icons.check, color: c.accent)
                            : null,
                        onTap: () => Navigator.pop(ctx, s),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) setState(() => _sortBy = picked);
  }

  /// Barra de resumen: nº de líneas mostradas y totales de paradas/horarios.
  Widget _summaryBar(TransitColorScheme c) {
    final list = _filtered;
    final stops = list.fold<int>(0, (s, r) => s + r.stopCount);
    final scheds = list.fold<int>(0, (s, r) => s + r.scheduleCount);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.alt_route, size: 13, color: c.textLo),
          const SizedBox(width: 4),
          Text('${list.length} líneas',
              style: TransitTypography.bodySmall(c.textMid)),
          const SizedBox(width: 12),
          Icon(Icons.place_outlined, size: 13, color: c.textLo),
          const SizedBox(width: 4),
          Text('$stops paradas',
              style: TransitTypography.bodySmall(c.textLo)),
          const SizedBox(width: 12),
          Icon(Icons.schedule, size: 13, color: c.textLo),
          const SizedBox(width: 4),
          Text('$scheds horarios',
              style: TransitTypography.bodySmall(c.textLo)),
        ],
      ),
    );
  }

  /// Lista agrupada por operador con cabeceras plegables.
  List<Widget> _buildGrouped(TransitColorScheme c) {
    final byOp = <String, List<AdminRouteRow>>{};
    for (final r in _filtered) {
      byOp.putIfAbsent(r.operatorId, () => []).add(r);
    }
    final opIds = byOp.keys.toList()
      ..sort((a, b) => _operatorName(a).compareTo(_operatorName(b)));
    final widgets = <Widget>[];
    for (final opId in opIds) {
      final routes = byOp[opId]!;
      final collapsed = _collapsedOps.contains(opId);
      widgets.add(Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Pressable(
          onTap: () => setState(() {
            collapsed ? _collapsedOps.remove(opId) : _collapsedOps.add(opId);
          }),
          child: Row(
            children: [
              Icon(collapsed ? Icons.chevron_right : Icons.expand_more,
                  color: c.textMid, size: 20),
              const SizedBox(width: 4),
              Icon(Icons.business, size: 14, color: c.accent),
              const SizedBox(width: 6),
              Text(_operatorName(opId),
                  style: TransitTypography.bodyPrimary(c.textHi)
                      .copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('${routes.length}',
                  style: TransitTypography.bodySmall(c.textLo)),
            ],
          ),
        ),
      ));
      if (!collapsed) {
        widgets.addAll(routes.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _routeCard(c, r),
            )));
      }
    }
    return widgets;
  }

  Widget _chip(TransitColorScheme c,
          {required String label,
          required IconData icon,
          required VoidCallback onTap,
          bool selected = false}) =>
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? c.accent.withValues(alpha: 0.18)
                : c.bgRaised.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? c.accent : c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? c.accent : c.textMid),
              const SizedBox(width: 6),
              Text(label,
                  style: TransitTypography.bodySmall(
                      selected ? c.accent : c.textMid)),
            ],
          ),
        ),
      );

  Future<void> _pickOperatorFilter() async {
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return SafeArea(
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.all_inclusive, color: c.accent),
                  title: const Text('Todos los operadores'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
                const Divider(height: 1),
                ..._operators.map((o) => ListTile(
                      leading: Icon(Icons.business, color: c.textMid),
                      title: Text(o.shortName),
                      subtitle: o.region.isEmpty ? null : Text(o.region),
                      onTap: () => Navigator.pop(ctx, o.id),
                    )),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) {
      setState(() => _filterOperatorId = picked);
    }
  }

  Future<void> _pickStatusFilter() async {
    final picked = await showModalBottomSheet<RouteStatus?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final c = TransitColorScheme.of(isDark);
        return SafeArea(
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(Icons.flag_outlined, color: c.accent),
                  title: const Text('Cualquier estado'),
                  onTap: () => Navigator.pop(ctx, null),
                ),
                const Divider(height: 1),
                ...RouteStatus.values.map((s) => ListTile(
                      leading: Icon(Icons.circle, color: _statusColor(s, c)),
                      title: Text(s.label),
                      onTap: () => Navigator.pop(ctx, s),
                    )),
              ],
            ),
          ),
        );
      },
    );
    if (mounted) {
      setState(() => _filterStatus = picked);
    }
  }

  Color _statusColor(RouteStatus s, TransitColorScheme c) => switch (s) {
        RouteStatus.draft => c.textLo,
        RouteStatus.pendingVerification => c.stateDelay,
        RouteStatus.verified => c.stateOnTime,
        RouteStatus.official => c.accent,
        RouteStatus.suspended => c.stateCancelled,
      };

  Widget _routeCard(TransitColorScheme c, AdminRouteRow r) {
    final routeColor = _parseHex(r.color) ?? c.accent;
    return Pressable(
      onTap: () => context
          .push('/management/routes/${r.id}')
          .then((_) => _load()),
      child: GlassCard(
        blur: 14,
        fillOpacity: 0.06,
        borderRadius: 14,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: routeColor.withValues(alpha: 0.2),
                border: Border.all(color: routeColor, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              // FittedBox: códigos largos (p.ej. "L15-EP") se reducen para
              // caber en el cuadro de 44px en vez de desbordarlo.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  r.code.isEmpty ? '?' : r.code,
                  maxLines: 1,
                  softWrap: false,
                  style: TransitTypography.bodyPrimary(routeColor)
                      .copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.name,
                      style: TransitTypography.bodyPrimary(c.textHi),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.circle,
                          size: 8, color: _statusColor(r.status, c)),
                      const SizedBox(width: 4),
                      Text(r.status.label,
                          style: TransitTypography.bodySmall(c.textMid)),
                      const SizedBox(width: 10),
                      Icon(Icons.business, size: 12, color: c.textLo),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(_operatorName(r.operatorId),
                            style: TransitTypography.bodySmall(c.textLo),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined, size: 12, color: c.textLo),
                      const SizedBox(width: 4),
                      Text('${r.stopCount} paradas',
                          style: TransitTypography.bodySmall(c.textLo)),
                      const SizedBox(width: 12),
                      Icon(Icons.schedule, size: 12, color: c.textLo),
                      const SizedBox(width: 4),
                      Text('${r.scheduleCount} horarios',
                          style: TransitTypography.bodySmall(c.textLo)),
                    ],
                  ),
                ],
              ),
            ),
            if (!r.active)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: c.stateCancelled.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('INACTIVA',
                    style: TransitTypography.bodySmall(c.stateCancelled)),
              ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: c.textLo),
          ],
        ),
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
