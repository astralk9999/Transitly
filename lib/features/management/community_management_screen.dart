import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Panel admin para gestionar las rutas de la comunidad: ver todas,
/// filtrar las que el autor pidió oficializar (status review_pending) y
/// entrar a cada una para oficializarla o eliminarla.
class CommunityManagementScreen extends ConsumerStatefulWidget {
  const CommunityManagementScreen({super.key});

  @override
  ConsumerState<CommunityManagementScreen> createState() => _State();
}

enum _Filter { all, pending, published }

class _State extends ConsumerState<CommunityManagementScreen> {
  List<Map<String, dynamic>> _routes = const [];
  String _query = '';
  _Filter _filter = _Filter.all;
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(userRoutesRepositoryProvider);
      if (repo == null) throw 'No autenticado';
      final rows = await repo.adminListCommunity();
      if (!mounted) return;
      setState(() {
        _routes = rows;
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

  bool _isPending(String status) =>
      status == 'review_pending' || status == 'pending_official';

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    return _routes.where((r) {
      final status = r['status'] as String? ?? '';
      switch (_filter) {
        case _Filter.pending:
          if (!_isPending(status)) return false;
        case _Filter.published:
          if (status != 'published' && status != 'community_approved') {
            return false;
          }
        case _Filter.all:
          break;
      }
      if (q.isEmpty) return true;
      final name = (r['name'] as String? ?? '').toLowerCase();
      final code = (r['code'] as String? ?? '').toLowerCase();
      return name.contains(q) || code.contains(q);
    }).toList();
  }

  static int _count(dynamic rel) {
    if (rel is List && rel.isNotEmpty && rel.first is Map) {
      final c = (rel.first as Map)['count'];
      if (c is num) return c.toInt();
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TransitAppBar(
          title: 'Gestión de comunidad',
          transparent: true,
          actions: [
            IconButton(
              icon: Icon(Icons.refresh, color: c.accent),
              tooltip: 'Refrescar',
              onPressed: _load,
            ),
          ],
        ),
        body: _loading
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
                : Column(
                    children: [
                      _statsHeader(c),
                      _searchBar(c),
                      _filtersBar(c),
                      const SizedBox(height: 6),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _load,
                          color: c.accent,
                          child: _filtered.isEmpty
                              ? ListView(children: const [
                                  SizedBox(height: 60),
                                  EmptyState(
                                    'Sin rutas',
                                    'No hay rutas de comunidad para este filtro.',
                                    icon: Icons.groups_outlined,
                                  ),
                                ])
                              : ListView.builder(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) =>
                                      _routeCard(c, _filtered[i]),
                                ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _statsHeader(TransitColorScheme c) {
    final total = _routes.length;
    final pendientes = _routes
        .where((r) => _isPending(r['status'] as String? ?? ''))
        .length;
    final publicadas = _routes
        .where((r) => (r['status'] as String? ?? '') == 'published')
        .length;
    final paradas =
        _routes.fold<int>(0, (s, r) => s + _count(r['user_route_stops']));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _statPill(
                  c, Icons.groups_outlined, '$total', 'Rutas', c.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.flag_outlined, '$pendientes',
                  'A revisar', const Color(0xFFFF9800))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.public, '$publicadas', 'Públicas',
                  const Color(0xFF4CAF50))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.place_outlined, '$paradas', 'Paradas',
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

  Widget _searchBar(TransitColorScheme c) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search, size: 18, color: c.textMid),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: TransitTypography.bodyPrimary(c.textHi),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    hintText: 'Buscar por nombre o código',
                    hintStyle: TransitTypography.bodySecondary(c.textMid),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _filtersBar(TransitColorScheme c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _filterChip(c, _Filter.all, 'Todas', Icons.list),
            const SizedBox(width: 6),
            _filterChip(c, _Filter.pending, 'A revisar', Icons.flag_outlined),
            const SizedBox(width: 6),
            _filterChip(c, _Filter.published, 'Públicas', Icons.public),
          ],
        ),
      );

  Widget _filterChip(
      TransitColorScheme c, _Filter f, String label, IconData icon) {
    final selected = _filter == f;
    final color = f == _Filter.pending ? const Color(0xFFFF9800) : c.accent;
    return Pressable(
      onTap: () => setState(() => _filter = f),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : c.border,
              width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textMid),
            const SizedBox(width: 6),
            Text(label,
                style: TransitTypography.bodySmall(
                    selected ? color : c.textMid)),
          ],
        ),
      ),
    );
  }

  Widget _routeCard(TransitColorScheme c, Map<String, dynamic> r) {
    final id = r['id'] as String;
    final name = r['name'] as String? ?? 'Sin nombre';
    final code = r['code'] as String?;
    final status = r['status'] as String? ?? '';
    final votes = (r['vote_count'] as num?)?.toInt() ?? 0;
    final stops = _count(r['user_route_stops']);
    final author = (r['profiles'] as Map?)?['display_name'] as String?;
    final routeColor = _parseHex(r['route_color'] as String?) ?? c.accent;
    final pending = _isPending(status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () =>
            context.push('/community/route/$id').then((_) => _load()),
        child: Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: pending
                    ? const Color(0xFFFF9800).withValues(alpha: 0.5)
                    : c.border,
                width: pending ? 1 : 0.5),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 50,
                decoration: BoxDecoration(
                  color: routeColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (code != null && code.isNotEmpty) ...[
                          Text(code,
                              style: TransitTypography.bodyPrimary(routeColor)
                                  .copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(width: 6),
                        ],
                        Expanded(
                          child: Text(name,
                              style: TransitTypography.bodyPrimary(c.textHi),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (pending)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('PIDE OFICIALIZAR',
                                style: TransitTypography.bodySmall(
                                    const Color(0xFFFF9800))),
                          ),
                        Icon(Icons.place_outlined, size: 12, color: c.textLo),
                        const SizedBox(width: 3),
                        Text('$stops',
                            style: TransitTypography.bodySmall(c.textLo)),
                        const SizedBox(width: 10),
                        Icon(Icons.thumb_up_outlined,
                            size: 12, color: c.textLo),
                        const SizedBox(width: 3),
                        Text('$votes',
                            style: TransitTypography.bodySmall(c.textLo)),
                        if (author != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.person_outline,
                              size: 12, color: c.textLo),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(author,
                                style: TransitTypography.bodySmall(c.textLo),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textLo),
            ],
          ),
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
