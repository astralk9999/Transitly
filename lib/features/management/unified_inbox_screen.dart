import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/moderation_repository.dart';
import '../../shared/widgets/transit_app_bar.dart';

/// Bandeja unificada: feedback, incidencias, sugerencias, solicitudes,
/// zonas propuestas, alta de operador y RGPD en una sola lista con
/// filtros por tipo. operator_admin ve solo lo de su operadora; admin
/// ve todo. Al resolver puede otorgar puntos al autor.
class UnifiedInboxScreen extends ConsumerStatefulWidget {
  const UnifiedInboxScreen({super.key});

  @override
  ConsumerState<UnifiedInboxScreen> createState() => _State();
}

class _Filter {
  const _Filter(this.id, this.label, this.icon, this.color);
  final String id; // source o 'all'
  final String label;
  final IconData icon;
  final Color color;
}

const _filters = [
  _Filter('all', 'Todas', Icons.inbox, Color(0xFF888888)),
  _Filter('feedback', 'Mejoras', Icons.tips_and_updates_outlined,
      Color(0xFF2196F3)),
  _Filter('incident', 'Incidencias', Icons.warning_amber, Color(0xFFFF9800)),
  _Filter('suggestion', 'Sugerencias', Icons.route_outlined, Color(0xFF4CAF50)),
  _Filter('feature', 'Solicitudes', Icons.lightbulb_outline, Color(0xFF9C27B0)),
  _Filter('zone', 'Zonas', Icons.map_outlined, Color(0xFF00BCD4)),
  _Filter('operator_app', 'Operadores', Icons.business_outlined,
      Color(0xFF7E57C2)),
  _Filter('rgpd', 'RGPD', Icons.delete_outline, Color(0xFFB71C1C)),
];

class _State extends ConsumerState<UnifiedInboxScreen> {
  List<ModerationItem> _items = const [];
  String _filter = 'all';
  bool _onlyOpen = true;
  bool _loading = true;
  String? _error;

  AdminModerationRepository get _repo =>
      ref.read(adminModerationRepositoryProvider);

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
      final items = await _repo.list(onlyOpen: _onlyOpen);
      if (!mounted) return;
      setState(() {
        _items = items;
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

  List<ModerationItem> get _filtered =>
      _filter == 'all' ? _items : _items.where((i) => i.source == _filter).toList();

  Map<String, int> get _countsBySource {
    final m = <String, int>{};
    for (final i in _items) {
      m[i.source] = (m[i.source] ?? 0) + 1;
    }
    return m;
  }

  Future<void> _resolve(ModerationItem it, String action) async {
    int points = 0;
    String? note;
    if (action == 'accept' || action == 'apply') {
      final res = await _askResolve(it);
      if (res == null) return;
      points = res.$1;
      note = res.$2;
    } else if (action == 'reject') {
      note = await _askNote('Motivo (opcional)');
    }
    try {
      await _repo.resolve(
        source: it.source,
        id: it.id,
        action: action,
        awardPoints: points,
        note: note,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(switch (action) {
          'review' => 'Marcado en revisión',
          'reject' => 'Rechazado',
          _ => points > 0 ? 'Aplicado · +$points XP al autor' : 'Aplicado',
        })));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  /// Dialog para aceptar/aplicar: puntos + nota.
  Future<(int, String?)?> _askResolve(ModerationItem it) async {
    final pointsCtrl = TextEditingController(text: it.rewardable ? '10' : '0');
    final noteCtrl = TextEditingController();
    return showDialog<(int, String?)>(
      context: context,
      builder: (ctx) {
        final c = TransitColorScheme.of(
            Theme.of(ctx).brightness == Brightness.dark);
        return AlertDialog(
          backgroundColor: c.bgElevated,
          title: const Text('Aplicar aportación'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (it.rewardable)
                TextField(
                  controller: pointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Puntos al autor (0 = ninguno)',
                    suffixText: 'XP',
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nota para el autor (opcional)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancelar')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: c.accent),
              onPressed: () => Navigator.pop(ctx, (
                int.tryParse(pointsCtrl.text) ?? 0,
                noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
              )),
              child: const Text('Aplicar'),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _askNote(String label) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(
                  ctx, ctrl.text.trim().isEmpty ? null : ctrl.text.trim()),
              child: const Text('Rechazar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TransitAppBar(title: 'Bandeja', transparent: true),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _filtersBar(c),
            _openToggle(c),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _errorView(c)
                      : _filtered.isEmpty
                          ? _emptyView(c)
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) => _card(c, _filtered[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtersBar(TransitColorScheme c) {
    final counts = _countsBySource;
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          for (final f in _filters) ...[
            _chip(c, f, f.id == 'all' ? _items.length : (counts[f.id] ?? 0)),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _chip(TransitColorScheme c, _Filter f, int count) {
    final selected = _filter == f.id;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => setState(() => _filter = f.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? f.color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? f.color : c.border,
              width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(f.icon, size: 14, color: selected ? f.color : c.textMid),
            const SizedBox(width: 4),
            Text(f.label,
                style: TextStyle(
                    fontSize: 12,
                    color: selected ? f.color : c.textHi,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: (selected ? f.color : c.textMid)
                      .withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected ? f.color : c.textMid)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _openToggle(TransitColorScheme c) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text('Mostrando ${_onlyOpen ? 'pendientes' : 'todas'}',
                style: TransitTypography.bodySmall(c.textMid)),
            const Spacer(),
            Switch.adaptive(
              value: !_onlyOpen,
              activeThumbColor: c.accent,
              onChanged: (v) {
                setState(() => _onlyOpen = !v);
                _load();
              },
            ),
            Text('Ver todas', style: TransitTypography.bodySmall(c.textMid)),
          ],
        ),
      );

  Widget _card(TransitColorScheme c, ModerationItem it) {
    final f = _filters.firstWhere((x) => x.id == it.source,
        orElse: () => _filters.first);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border, width: 0.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: f.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: f.color.withValues(alpha: 0.5), width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(f.icon, size: 12, color: f.color),
                    const SizedBox(width: 4),
                    Text(it.typeLabel.toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: f.color,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              const Spacer(),
              Text(_fmtDate(it.createdAt),
                  style: TransitTypography.bodySmall(c.textLo)),
            ],
          ),
          const SizedBox(height: 8),
          if (it.title.isNotEmpty)
            Text(it.title,
                style: TransitTypography.bodyPrimary(c.textHi)
                    .copyWith(fontWeight: FontWeight.w600)),
          if ((it.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(it.description!,
                style: TransitTypography.bodySecondary(c.textHi),
                maxLines: 4,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _statusBadge(c, it.status),
              const Spacer(),
              if (it.authorId != null)
                InkWell(
                  onTap: () => context.push('/admin/users/${it.authorId}'),
                  child: Row(
                    children: [
                      Icon(Icons.person_outline, size: 13, color: c.accent),
                      const SizedBox(width: 4),
                      Text('Autor', style: TransitTypography.bodySmall(c.accent)),
                    ],
                  ),
                ),
            ],
          ),
          if (it.isOpen) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (it.status == 'open' || it.status == 'requested')
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _resolve(it, 'review'),
                      icon: const Icon(Icons.visibility_outlined, size: 15),
                      label: const Text('Revisar'),
                      style: OutlinedButton.styleFrom(
                          foregroundColor: c.textMid,
                          side: BorderSide(color: c.border)),
                    ),
                  ),
                if (it.status == 'open' || it.status == 'requested')
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _resolve(it, 'reject'),
                    icon: const Icon(Icons.close, size: 15),
                    label: const Text('Rechazar'),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: c.stateCancelled,
                        side: BorderSide(
                            color: c.stateCancelled.withValues(alpha: 0.5))),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _resolve(it, 'accept'),
                    icon: const Icon(Icons.check, size: 15),
                    label: Text(it.source == 'rgpd' ? 'Borrar' : 'Aplicar'),
                    style: FilledButton.styleFrom(backgroundColor: c.accent),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(TransitColorScheme c, String status) {
    final label = switch (status) {
      'open' || 'requested' => 'Pendiente',
      'in_review' || 'inReview' || 'considered' => 'En revisión',
      'applied' || 'accepted' || 'resolved' || 'approved' || 'completed' =>
        'Resuelto',
      'rejected' || 'cancelled' => 'Rechazado',
      _ => status,
    };
    return Text(label, style: TransitTypography.bodySmall(c.textMid));
  }

  Widget _emptyView(TransitColorScheme c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox, size: 56, color: c.textLo),
              const SizedBox(height: 12),
              Text(
                  _onlyOpen
                      ? 'Nada pendiente por aquí.'
                      : 'No hay elementos.',
                  style: TransitTypography.bodyPrimary(c.textMid)),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refrescar'),
              ),
            ],
          ),
        ),
      );

  Widget _errorView(TransitColorScheme c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: c.stateCancelled),
              const SizedBox(height: 12),
              Text('No se pudo cargar la bandeja',
                  style: TransitTypography.bodyPrimary(c.textHi)),
              const SizedBox(height: 4),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TransitTypography.bodySmall(c.textLo),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
