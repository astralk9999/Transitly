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

class _State extends ConsumerState<RoutesManagementScreen> {
  String _query = '';
  String? _filterOperatorId;
  RouteStatus? _filterStatus;
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
    return _all.where((r) {
      if (_filterOperatorId != null && r.operatorId != _filterOperatorId) {
        return false;
      }
      if (_filterStatus != null && r.status != _filterStatus) return false;
      if (q.isEmpty) return true;
      return r.code.toLowerCase().contains(q) ||
          r.name.toLowerCase().contains(q);
    }).toList();
  }

  String _operatorName(String id) =>
      _operators.firstWhere((o) => o.id == id,
          orElse: () => OperatorModel(
              id: id, name: id, shortName: id, slug: '', region: '')).shortName;

  Future<void> _createRoute() async {
    final scope = await ref.read(manageScopeProvider.future);
    if (!mounted) return;
    String? operatorId = scope.isAdmin
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
                        const SizedBox(height: 16),
                        if (_filtered.isEmpty)
                          const EmptyState(
                            'Sin líneas',
                            'Crea la primera con el botón de abajo.',
                            icon: Icons.alt_route,
                          )
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

  Widget _chip(TransitColorScheme c,
          {required String label,
          required IconData icon,
          required VoidCallback onTap}) =>
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: c.bgRaised.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: c.textMid),
              const SizedBox(width: 6),
              Text(label, style: TransitTypography.bodySmall(c.textMid)),
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
              child: Text(
                r.code.isEmpty ? '?' : r.code,
                style: TransitTypography.bodyPrimary(routeColor)
                    .copyWith(fontWeight: FontWeight.w800),
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
