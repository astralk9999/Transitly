import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/uuid.dart';
import '../../data/geo_alerts/geo_alerts_repository.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/geo_alert_model.dart';
import '../../shared/models/route_model.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

/// Avisos geo (admin). Lista con stats + filtros + búsqueda;
/// editor con mapa interactivo y selector de rutas afectadas.
class AdminGeoAlertsScreen extends ConsumerStatefulWidget {
  const AdminGeoAlertsScreen({super.key});

  @override
  ConsumerState<AdminGeoAlertsScreen> createState() =>
      _AdminGeoAlertsScreenState();
}

enum _Filter { all, active, inactive, critical }

class _AdminGeoAlertsScreenState extends ConsumerState<AdminGeoAlertsScreen> {
  List<GeoAlertModel> _alerts = [];
  bool _loading = true;
  String? _error;
  String _search = '';
  _Filter _filter = _Filter.all;
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
      final repo = ref.read(geoAlertsRepositoryProvider);
      final rows = await repo.listAllForAdmin();
      if (!mounted) return;
      setState(() {
        _alerts = rows;
        _loading = false;
      });
    } catch (e) {
      AppLogger.warn('AdminGeoAlerts', 'load failed', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar los avisos';
      });
    }
  }

  Future<void> _onCreate() async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(
        builder: (_) => const _GeoAlertEditorScreen(),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) return;
    final model = result[0] as GeoAlertModel;
    final broadcast = result[1] as bool;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final saved = await ref
          .read(geoAlertsRepositoryProvider)
          .create(model);
      if (broadcast) await _broadcast(saved.id);
      await _load();
      ref.invalidate(activeGeoAlertsProvider);
      messenger.showSnackBar(SnackBar(
          content: Text(broadcast
              ? 'Aviso creado y difundido'
              : 'Aviso creado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _onEdit(GeoAlertModel a) async {
    final result = await Navigator.of(context).push<List<dynamic>>(
      MaterialPageRoute(
        builder: (_) => _GeoAlertEditorScreen(initial: a),
        fullscreenDialog: true,
      ),
    );
    if (result == null || !mounted) return;
    final model = result[0] as GeoAlertModel;
    final broadcast = result[1] as bool;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(geoAlertsRepositoryProvider).update(model);
      if (broadcast) await _broadcast(model.id);
      await _load();
      ref.invalidate(activeGeoAlertsProvider);
      messenger.showSnackBar(SnackBar(
          content: Text(broadcast
              ? 'Aviso actualizado y difundido'
              : 'Aviso actualizado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _broadcast(String alertId) async {
    try {
      await ref
          .read(supabaseClientProvider)
          .rpc('admin_broadcast_alert', params: {'p_alert_id': alertId});
    } catch (e) {
      AppLogger.warn('AdminGeoAlerts', 'broadcast failed', e);
    }
  }

  Future<void> _toggleActive(GeoAlertModel a) async {
    try {
      await ref
          .read(geoAlertsRepositoryProvider)
          .setActive(a.id, !a.active);
      await _load();
      ref.invalidate(activeGeoAlertsProvider);
    } catch (_) {}
  }

  Future<void> _onDelete(GeoAlertModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar aviso'),
        content: Text('¿Eliminar "${a.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB71C1C)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(geoAlertsRepositoryProvider).delete(a.id);
    await _load();
    ref.invalidate(activeGeoAlertsProvider);
  }

  List<GeoAlertModel> get _filteredAlerts {
    final q = _search.trim().toLowerCase();
    return _alerts.where((a) {
      if (q.isNotEmpty &&
          !a.title.toLowerCase().contains(q) &&
          !a.body.toLowerCase().contains(q)) return false;
      switch (_filter) {
        case _Filter.active:
          return a.active;
        case _Filter.inactive:
          return !a.active;
        case _Filter.critical:
          return a.severity == GeoAlertSeverity.critical;
        case _Filter.all:
          return true;
      }
    }).toList();
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
          title: 'Avisos geo',
          transparent: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: c.accent),
              tooltip: 'Crear aviso',
              onPressed: _onCreate,
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(c)
                : Column(
                    children: [
                      _statsHeader(c),
                      _searchBar(c),
                      _filtersBar(c),
                      const SizedBox(height: 4),
                      Expanded(child: _list(c)),
                    ],
                  ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────
  Widget _statsHeader(TransitColorScheme c) {
    final total = _alerts.length;
    final active = _alerts.where((a) => a.active).length;
    final crit = _alerts
        .where((a) =>
            a.active && a.severity == GeoAlertSeverity.critical)
        .length;
    final inactive = total - active;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
              child: _statPill(c, Icons.campaign_outlined, '$total',
                  'Total', c.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.bolt, '$active', 'Activos',
                  const Color(0xFF4CAF50))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.priority_high, '$crit',
                  'Críticos', const Color(0xFFB71C1C))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.pause_circle_outline, '$inactive',
                  'Inactivos', c.textMid)),
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
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textHi,
                  )),
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

  Widget _searchBar(TransitColorScheme c) {
    return Padding(
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
                onChanged: (v) => setState(() => _search = v),
                style: TransitTypography.bodyPrimary(c.textHi),
                decoration: InputDecoration(
                  hintText: 'Título o descripción',
                  hintStyle: TransitTypography.bodySecondary(c.textMid),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_search.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 16, color: c.textMid),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _filtersBar(TransitColorScheme c) {
    final chips = [
      _filterChip(c,
          icon: Icons.list,
          label: 'Todos',
          selected: _filter == _Filter.all,
          color: c.accent,
          onTap: () => setState(() => _filter = _Filter.all)),
      _filterChip(c,
          icon: Icons.bolt,
          label: 'Activos',
          selected: _filter == _Filter.active,
          color: const Color(0xFF4CAF50),
          onTap: () => setState(() => _filter = _Filter.active)),
      _filterChip(c,
          icon: Icons.priority_high,
          label: 'Críticos',
          selected: _filter == _Filter.critical,
          color: const Color(0xFFB71C1C),
          onTap: () => setState(() => _filter = _Filter.critical)),
      _filterChip(c,
          icon: Icons.pause_circle_outline,
          label: 'Inactivos',
          selected: _filter == _Filter.inactive,
          color: c.textMid,
          onTap: () => setState(() => _filter = _Filter.inactive)),
    ];
    return SizedBox(
      height: 36,
      child: LayoutBuilder(builder: (ctx, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ConstrainedBox(
            constraints:
                BoxConstraints(minWidth: constraints.maxWidth - 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < chips.length; i++) ...[
                  chips[i],
                  if (i < chips.length - 1) const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _filterChip(TransitColorScheme c,
      {required IconData icon,
      required String label,
      required bool selected,
      required Color color,
      required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
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
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? color : c.textHi,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _list(TransitColorScheme c) {
    final list = _filteredAlerts;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.notifications_off_outlined,
                  size: 64, color: c.textLo),
              const SizedBox(height: 12),
              Text(
                  _search.isNotEmpty || _filter != _Filter.all
                      ? 'Sin resultados con los filtros'
                      : 'No hay avisos creados',
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
    }
    return RefreshIndicator(
      color: c.accent,
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: list.length,
        itemBuilder: (_, i) => _alertCard(c, list[i]),
      ),
    );
  }

  Widget _alertCard(TransitColorScheme c, GeoAlertModel a) {
    final (sevLabel, sevColor) = switch (a.severity) {
      GeoAlertSeverity.info => ('Info', const Color(0xFF2196F3)),
      GeoAlertSeverity.warning => ('Aviso', const Color(0xFFFF9800)),
      GeoAlertSeverity.critical => ('Crítico', const Color(0xFFB71C1C)),
    };
    final routes = a.affectedRouteIds;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onEdit(a),
        child: GlassCard(
          blur: 12,
          fillOpacity: a.active ? 0.05 : 0.02,
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _pill(sevLabel, sevColor),
                  const SizedBox(width: 6),
                  _pill(a.active ? 'ACTIVO' : 'INACTIVO',
                      a.active ? const Color(0xFF4CAF50) : c.textMid),
                  const Spacer(),
                  if (a.createdAt != null)
                    Text(
                        '${a.createdAt!.year}-${a.createdAt!.month.toString().padLeft(2, '0')}-${a.createdAt!.day.toString().padLeft(2, '0')}',
                        style: TransitTypography.bodySmall(c.textLo)),
                ],
              ),
              const SizedBox(height: 8),
              Text(a.title,
                  style: TransitTypography.bodyPrimary(
                      a.active ? c.textHi : c.textLo)),
              const SizedBox(height: 4),
              Text(a.body,
                  style: TransitTypography.bodySecondary(c.textMid),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (a.isGlobal)
                    _miniBadge(c,
                        icon: Icons.public,
                        label: 'GLOBAL',
                        color: const Color(0xFF9C27B0))
                  else ...[
                    _miniBadge(c,
                        icon: Icons.place_outlined,
                        label:
                            '${(a.centerLat ?? 0).toStringAsFixed(4)}, ${(a.centerLng ?? 0).toStringAsFixed(4)}',
                        color: c.accent),
                    _miniBadge(c,
                        icon: Icons.radio_button_unchecked,
                        label: '${a.radiusM ?? 0} m',
                        color: const Color(0xFF2196F3)),
                  ],
                  if (a.targetRole != null)
                    _miniBadge(c,
                        icon: Icons.person_outline,
                        label: a.targetRole!,
                        color: c.textMid),
                  if (routes.isEmpty)
                    _miniBadge(c,
                        icon: Icons.public,
                        label: 'Todas las rutas',
                        color: c.textMid)
                  else
                    _miniBadge(c,
                        icon: Icons.route_outlined,
                        label: '${routes.length} rutas',
                        color: const Color(0xFF9C27B0)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      a.active ? Icons.visibility : Icons.visibility_off,
                      color: c.accent,
                      size: 20,
                    ),
                    tooltip: a.active ? 'Desactivar' : 'Activar',
                    onPressed: () => _toggleActive(a),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: c.accent, size: 20),
                    tooltip: 'Editar',
                    onPressed: () => _onEdit(a),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline,
                        color: c.stateCancelled, size: 20),
                    tooltip: 'Eliminar',
                    onPressed: () => _onDelete(a),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
            color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(label.toUpperCase(),
          style: GoogleFonts.ibmPlexMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1)),
    );
  }

  Widget _miniBadge(TransitColorScheme c,
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  Widget _errorView(TransitColorScheme c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: c.stateCancelled),
            const SizedBox(height: 12),
            Text(_error!,
                style: TransitTypography.bodyPrimary(c.textHi)),
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
  }
}

// ─────────────────────────────────────────────────────────────────────
// EDITOR — mapa interactivo + selector de rutas
// ─────────────────────────────────────────────────────────────────────
class _GeoAlertEditorScreen extends ConsumerStatefulWidget {
  const _GeoAlertEditorScreen({this.initial});
  final GeoAlertModel? initial;

  @override
  ConsumerState<_GeoAlertEditorScreen> createState() =>
      _GeoAlertEditorScreenState();
}

class _GeoAlertEditorScreenState
    extends ConsumerState<_GeoAlertEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  late LatLng _center;
  late double _radius;
  late GeoAlertSeverity _severity;
  final Set<String> _selectedRoutes = {};
  final _mapController = MapController();
  final _routeSearchCtrl = TextEditingController();
  String _routeSearch = '';
  ServiceType? _routeTypeFilter;
  bool _showAllRoutes = false;
  static const _routesPageSize = 12;
  bool _isGlobal = false;
  String? _targetRole; // null = todos
  DateTime? _expiresAt;
  DateTime? _scheduledAt;
  final _actionUrlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _titleCtrl.text = i.title;
      _bodyCtrl.text = i.body;
      _center = LatLng(
          i.centerLat ?? 36.6850, i.centerLng ?? -6.1376);
      _radius = (i.radiusM ?? 500).toDouble();
      _severity = i.severity;
      _selectedRoutes.addAll(i.affectedRouteIds);
      _isGlobal = i.isGlobal;
      _targetRole = i.targetRole;
      _expiresAt = i.expiresAt;
      _scheduledAt = i.scheduledAt;
      _actionUrlCtrl.text = i.actionUrl ?? '';
    } else {
      _center = const LatLng(36.6850, -6.1376); // Jerez
      _radius = 500;
      _severity = GeoAlertSeverity.info;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _routeSearchCtrl.dispose();
    _actionUrlCtrl.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tap, LatLng pos) {
    setState(() => _center = pos);
  }

  void _submit({bool broadcast = false}) {
    if (!_formKey.currentState!.validate()) return;
    final base = widget.initial;
    final url = _actionUrlCtrl.text.trim();
    final out = GeoAlertModel(
      id: base?.id ?? generateUuidV4(),
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      severity: _severity,
      centerLat: _isGlobal ? null : _center.latitude,
      centerLng: _isGlobal ? null : _center.longitude,
      radiusM: _isGlobal ? null : _radius.round(),
      active: base?.active ?? true,
      createdBy: base?.createdBy,
      createdAt: base?.createdAt,
      expiresAt: _expiresAt,
      affectedRouteIds: _selectedRoutes.toList(),
      isGlobal: _isGlobal,
      targetRole: _targetRole,
      scheduledAt: _scheduledAt,
      actionUrl: url.isEmpty ? null : url,
    );
    Navigator.of(context).pop(<dynamic>[out, broadcast]);
  }

  Future<void> _pickDate(BuildContext ctx,
      {required DateTime? current,
      required ValueChanged<DateTime?> onPicked}) async {
    final now = DateTime.now();
    final initial = current ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null) return;
    if (!ctx.mounted) return;
    final time = await showTimePicker(
      context: ctx,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    onPicked(DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final routes = mockData.routes;
    final isEditing = widget.initial != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: isEditing ? 'Editar aviso' : 'Nuevo aviso',
        transparent: true,
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section(c, Icons.title_outlined, 'Datos'),
              const SizedBox(height: 8),
              TransitInput(
                hint: 'Título',
                controller: _titleCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 12),
              TransitInput(
                hint: 'Descripción',
                controller: _bodyCtrl,
                maxLines: 3,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _section(c, Icons.warning_amber, 'Severidad'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _severityChip(c, GeoAlertSeverity.info, 'Info',
                      Icons.info_outline, const Color(0xFF2196F3)),
                  _severityChip(c, GeoAlertSeverity.warning, 'Aviso',
                      Icons.warning_amber, const Color(0xFFFF9800)),
                  _severityChip(c, GeoAlertSeverity.critical, 'Crítico',
                      Icons.priority_high, const Color(0xFFB71C1C)),
                ],
              ),
              const SizedBox(height: 20),
              _section(c, Icons.tune, 'Tipo y destinatarios'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _typeToggleChip(c, false, 'Geo',
                      Icons.location_on_outlined, c.accent),
                  _typeToggleChip(c, true, 'Global',
                      Icons.public, const Color(0xFF9C27B0)),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                  _isGlobal
                      ? 'El aviso se envía a TODOS los usuarios (filtrable por rol).'
                      : 'El aviso solo aparece a quienes estén dentro del radio.',
                  style: TransitTypography.bodySmall(c.textMid)),
              const SizedBox(height: 12),
              Text('Rol destinatario',
                  style: TransitTypography.bodySmall(c.textMid)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _roleChip(c, null, 'Todos'),
                  _roleChip(c, 'passenger', 'Pasajeros'),
                  _roleChip(c, 'driver', 'Conductores'),
                  _roleChip(c, 'operatorAdmin', 'Op. Admin'),
                  _roleChip(c, 'moderator', 'Moderadores'),
                  _roleChip(c, 'admin', 'Admins'),
                ],
              ),
              const SizedBox(height: 20),
              _section(c, Icons.schedule, 'Programación y expiración'),
              const SizedBox(height: 8),
              _dateRow(c,
                  label: 'Programar para',
                  value: _scheduledAt,
                  icon: Icons.event,
                  onPick: () => _pickDate(context,
                      current: _scheduledAt,
                      onPicked: (d) =>
                          setState(() => _scheduledAt = d)),
                  onClear: () => setState(() => _scheduledAt = null)),
              const SizedBox(height: 6),
              _dateRow(c,
                  label: 'Expira el',
                  value: _expiresAt,
                  icon: Icons.timer_off_outlined,
                  onPick: () => _pickDate(context,
                      current: _expiresAt,
                      onPicked: (d) =>
                          setState(() => _expiresAt = d)),
                  onClear: () => setState(() => _expiresAt = null)),
              const SizedBox(height: 20),
              _section(c, Icons.link, 'URL de acción (opcional)'),
              const SizedBox(height: 8),
              TransitInput(
                hint: 'https://… o transitly://route/L1',
                controller: _actionUrlCtrl,
              ),
              if (!_isGlobal) ...[
                const SizedBox(height: 20),
                _section(c, Icons.place_outlined,
                    'Ubicación y radio (toca el mapa para colocar)'),
                const SizedBox(height: 8),
                Container(
                height: 280,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 14,
                    onTap: _onMapTap,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.transitly.transitly',
                    ),
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: _center,
                          radius: _radius,
                          useRadiusInMeter: true,
                          color: c.accent.withValues(alpha: 0.18),
                          borderColor: c.accent,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _center,
                          width: 32,
                          height: 32,
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.accent,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.campaign,
                                size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.my_location, size: 14, color: c.textMid),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${_center.latitude.toStringAsFixed(5)}, ${_center.longitude.toStringAsFixed(5)}',
                      style: TransitTypography.bodySmall(c.textMid),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () =>
                        _mapController.move(_center, 15),
                    icon: const Icon(Icons.center_focus_strong, size: 14),
                    label: const Text('Centrar'),
                    style: TextButton.styleFrom(
                        foregroundColor: c.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.radio_button_unchecked,
                      size: 14, color: c.textMid),
                  const SizedBox(width: 4),
                  Text('Radio: ${_radius.round()} m',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                ],
              ),
              Slider(
                value: _radius,
                min: 50,
                max: 5000,
                divisions: 99,
                activeColor: c.accent,
                label: '${_radius.round()} m',
                onChanged: (v) => setState(() => _radius = v),
              ),
              ], // cierra el if (!_isGlobal) ...[
              const SizedBox(height: 20),
              _section(c, Icons.route_outlined,
                  'Rutas afectadas (vacío = todas)'),
              const SizedBox(height: 4),
              Text(
                _selectedRoutes.isEmpty
                    ? 'El aviso se aplica a TODAS las rutas'
                    : 'Aplica a ${_selectedRoutes.length} ruta(s)',
                style: TransitTypography.bodySmall(c.textMid),
              ),
              const SizedBox(height: 8),
              if (routes.isEmpty)
                Text('No hay rutas cargadas',
                    style: TransitTypography.bodySmall(c.textLo))
              else
                _routesSelector(c, routes),
              const SizedBox(height: 32),
              TransitButton(
                label: isEditing ? 'GUARDAR' : 'CREAR',
                onPressed: () => _submit(),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _submit(broadcast: true),
                icon: const Icon(Icons.send),
                label: Text(isEditing
                    ? 'GUARDAR Y DIFUNDIR AHORA'
                    : 'CREAR Y DIFUNDIR AHORA'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.accent,
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: c.accent),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancelar',
                    style: TransitTypography.bodyPrimary(c.textMid)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(TransitColorScheme c, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: c.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text.toUpperCase(),
              style: GoogleFonts.ibmPlexMono(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: c.accent,
                letterSpacing: 1.5,
              )),
        ),
      ],
    );
  }

  Widget _typeToggleChip(TransitColorScheme c, bool isGlobalValue,
      String label, IconData icon, Color color) {
    final selected = _isGlobal == isGlobalValue;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _isGlobal = isGlobalValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : c.border,
              width: selected ? 1.5 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? color : c.textMid),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? color : c.textHi,
                )),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(TransitColorScheme c, String? role, String label) {
    final selected = _targetRole == role;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() => _targetRole = role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.accent.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 1 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? c.accent : c.textHi,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }

  Widget _dateRow(TransitColorScheme c,
      {required String label,
      required DateTime? value,
      required IconData icon,
      required VoidCallback onPick,
      required VoidCallback onClear}) {
    String fmt(DateTime d) {
      String pad(int n) => n.toString().padLeft(2, '0');
      return '${d.year}-${pad(d.month)}-${pad(d.day)} ${pad(d.hour)}:${pad(d.minute)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: c.textMid),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value == null ? '$label: —' : '$label: ${fmt(value)}',
              style: TransitTypography.bodySmall(
                  value == null ? c.textLo : c.textHi),
            ),
          ),
          if (value != null)
            IconButton(
              icon: Icon(Icons.close, size: 14, color: c.textMid),
              onPressed: onClear,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
              tooltip: 'Quitar',
            ),
          TextButton.icon(
            onPressed: onPick,
            icon: const Icon(Icons.calendar_month, size: 14),
            label: Text(value == null ? 'Elegir' : 'Cambiar'),
            style: TextButton.styleFrom(
              foregroundColor: c.accent,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _severityChip(TransitColorScheme c, GeoAlertSeverity sev,
      String label, IconData icon, Color color) {
    final selected = _severity == sev;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => setState(() => _severity = sev),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : c.border,
              width: selected ? 1.5 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textMid),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? color : c.textHi,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  Widget _routesSelector(TransitColorScheme c, List<RouteModel> all) {
    var filtered = all.where((r) {
      if (_routeTypeFilter != null && r.serviceType != _routeTypeFilter) {
        return false;
      }
      if (_routeSearch.isEmpty) return true;
      final q = _routeSearch.toLowerCase();
      return r.code.toLowerCase().contains(q) ||
          r.name.toLowerCase().contains(q);
    }).toList();
    final hasMore = filtered.length > _routesPageSize;
    final visible = _showAllRoutes || !hasMore
        ? filtered
        : filtered.take(_routesPageSize).toList();
    final allFilteredSelected = filtered.isNotEmpty &&
        filtered.every((r) => _selectedRoutes.contains(r.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Buscador
        Container(
          decoration: BoxDecoration(
            color: c.bgRaised,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border, width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(Icons.search, size: 16, color: c.textMid),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: _routeSearchCtrl,
                  onChanged: (v) => setState(() {
                    _routeSearch = v;
                    _showAllRoutes = false;
                  }),
                  style: TransitTypography.bodyPrimary(c.textHi),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código o nombre',
                    hintStyle:
                        TransitTypography.bodySecondary(c.textMid),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              if (_routeSearch.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, size: 14, color: c.textMid),
                  onPressed: () {
                    _routeSearchCtrl.clear();
                    setState(() => _routeSearch = '');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 32,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _typeChip(c, null, 'Todos'),
              for (final t in ServiceType.values) ...[
                const SizedBox(width: 6),
                _typeChip(c, t, t.label),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '${visible.length} de ${filtered.length} '
              '${filtered.length == 1 ? "ruta" : "rutas"}'
              '${_selectedRoutes.isEmpty ? "" : " · ${_selectedRoutes.length} sel."}',
              style: TransitTypography.bodySmall(c.textMid),
            ),
            const Spacer(),
            if (filtered.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(() {
                  if (allFilteredSelected) {
                    for (final r in filtered) {
                      _selectedRoutes.remove(r.id);
                    }
                  } else {
                    for (final r in filtered) {
                      _selectedRoutes.add(r.id);
                    }
                  }
                }),
                icon: Icon(
                    allFilteredSelected
                        ? Icons.deselect
                        : Icons.select_all,
                    size: 14),
                label: Text(allFilteredSelected
                    ? 'Quitar visibles'
                    : 'Seleccionar visibles'),
                style: TextButton.styleFrom(
                  foregroundColor: c.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            if (_selectedRoutes.isNotEmpty)
              TextButton.icon(
                onPressed: () => setState(_selectedRoutes.clear),
                icon: const Icon(Icons.clear_all, size: 14),
                label: const Text('Limpiar'),
                style: TextButton.styleFrom(
                  foregroundColor: c.stateCancelled,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Text('Sin coincidencias',
              style: TransitTypography.bodySmall(c.textLo))
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [for (final r in visible) _routeChip(c, r)],
          ),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: () =>
                  setState(() => _showAllRoutes = !_showAllRoutes),
              icon: Icon(
                  _showAllRoutes
                      ? Icons.expand_less
                      : Icons.expand_more,
                  size: 16),
              label: Text(_showAllRoutes
                  ? 'Ver menos'
                  : 'Ver todas (${filtered.length - _routesPageSize} más)'),
              style: TextButton.styleFrom(foregroundColor: c.accent),
            ),
          ),
        ],
      ],
    );
  }

  Widget _typeChip(TransitColorScheme c, ServiceType? t, String label) {
    final selected = _routeTypeFilter == t;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => setState(() {
        _routeTypeFilter = t;
        _showAllRoutes = false;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color:
              selected ? c.accent.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? c.accent : c.border,
              width: selected ? 1 : 0.5),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 11,
              color: selected ? c.accent : c.textHi,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            )),
      ),
    );
  }

  Widget _routeChip(TransitColorScheme c, RouteModel r) {
    final selected = _selectedRoutes.contains(r.id);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => setState(() {
        if (selected) {
          _selectedRoutes.remove(r.id);
        } else {
          _selectedRoutes.add(r.id);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? r.routeColor.withValues(alpha: 0.22)
              : c.bgRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? r.routeColor : c.border,
              width: selected ? 1.2 : 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: r.routeColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(r.code,
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected ? r.routeColor : c.textHi,
                )),
            const SizedBox(width: 4),
            Text(r.name,
                style: TextStyle(
                  fontSize: 11,
                  color: selected ? r.routeColor : c.textMid,
                )),
            if (selected) ...[
              const SizedBox(width: 4),
              Icon(Icons.check, size: 12, color: r.routeColor),
            ],
          ],
        ),
      ),
    );
  }
}
