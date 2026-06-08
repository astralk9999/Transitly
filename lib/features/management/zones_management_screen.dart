import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../../core/map/map_config.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

/// Gestión de ZONAS (admin global + admin de operadora). Cada zona tiene un
/// perímetro circular (centro + radio), igual que los avisos geo. Sirve para
/// elegir la "zona principal" del perfil y como destino por defecto del mapa
/// cuando no hay ubicación.
class ZonesManagementScreen extends ConsumerStatefulWidget {
  const ZonesManagementScreen({super.key});

  @override
  ConsumerState<ZonesManagementScreen> createState() =>
      _ZonesManagementScreenState();
}

class _ZonesManagementScreenState extends ConsumerState<ZonesManagementScreen> {
  List<ZoneRow> _zones = [];
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
      final repo = ref.read(adminRoutesRepositoryProvider);
      final rows = await repo.listZones(includePending: true);
      if (!mounted) return;
      setState(() {
        _zones = rows;
        _loading = false;
      });
    } catch (e) {
      AppLogger.warn('AdminZones', 'load failed', e);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudieron cargar las zonas';
      });
    }
  }

  Future<void> _openEditor({ZoneRow? zone}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _ZoneEditorScreen(initial: zone),
        fullscreenDialog: true,
      ),
    );
    if (saved == true) await _load();
  }

  Future<void> _delete(ZoneRow z) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar zona'),
        content: Text('¿Eliminar "${z.name}"? Se desvinculará de los perfiles '
            'que la tengan como zona principal.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFB71C1C)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminRoutesRepositoryProvider).zoneDelete(z.id);
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

    return RoleGate(
      allow: const [UserRole.admin, UserRole.operatorAdmin],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TransitAppBar(
          title: 'Zonas',
          transparent: true,
          actions: [
            IconButton(
              icon: Icon(Icons.add, color: c.accent),
              tooltip: 'Crear zona',
              onPressed: () => _openEditor(),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _errorView(c)
                : _zones.isEmpty
                    ? _emptyView(c)
                    : RefreshIndicator(
                        color: c.accent,
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _zones.length,
                          itemBuilder: (_, i) => _zoneCard(c, _zones[i]),
                        ),
                      ),
      ),
    );
  }

  Widget _zoneCard(TransitColorScheme c, ZoneRow z) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditor(zone: z),
        child: GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                    z.hasGeometry
                        ? Icons.location_on
                        : Icons.location_off_outlined,
                    color: c.accent,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(z.name,
                              style: TransitTypography.bodyPrimary(c.textHi),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (z.isPending) ...[
                          const SizedBox(width: 6),
                          _pill('PROPUESTA', const Color(0xFFFF9800)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      z.hasGeometry
                          ? '${z.centerLat!.toStringAsFixed(4)}, ${z.centerLng!.toStringAsFixed(4)} · ${z.radiusM} m'
                          : 'Sin perímetro definido',
                      style: TransitTypography.bodySmall(
                          z.hasGeometry ? c.textMid : c.textLo),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: c.stateCancelled, size: 20),
                tooltip: 'Eliminar',
                onPressed: () => _delete(z),
              ),
              Icon(Icons.chevron_right, color: c.textMid, size: 18),
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
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
      ),
      child: Text(label,
          style: GoogleFonts.ibmPlexMono(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1)),
    );
  }

  Widget _emptyView(TransitColorScheme c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: c.textLo),
            const SizedBox(height: 12),
            Text('No hay zonas creadas',
                style: TransitTypography.bodyPrimary(c.textMid)),
            const SizedBox(height: 12),
            TransitButton(
                label: 'Crear la primera',
                icon: Icons.add,
                onPressed: () => _openEditor()),
          ],
        ),
      ),
    );
  }

  Widget _errorView(TransitColorScheme c) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: c.stateCancelled),
          const SizedBox(height: 12),
          Text(_error!, style: TransitTypography.bodyPrimary(c.textHi)),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// EDITOR — nombre + operadora + mapa (centro+radio)
// ─────────────────────────────────────────────────────────────────────
class _ZoneEditorScreen extends ConsumerStatefulWidget {
  const _ZoneEditorScreen({this.initial});
  final ZoneRow? initial;

  @override
  ConsumerState<_ZoneEditorScreen> createState() => _ZoneEditorScreenState();
}

class _ZoneEditorScreenState extends ConsumerState<_ZoneEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  late LatLng _center;
  late double _radius;
  String? _operatorId;
  List<OperatorModel> _operators = const [];
  bool _saving = false;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    if (i != null) {
      _nameCtrl.text = i.name;
      _center = LatLng(i.centerLat ?? MapConfig.defaultCenter.latitude,
          i.centerLng ?? MapConfig.defaultCenter.longitude);
      _radius = (i.radiusM ?? 1500).toDouble();
      _operatorId = i.operatorId;
    } else {
      _center = MapConfig.defaultCenter;
      _radius = 1500;
    }
    _loadOperators();
  }

  Future<void> _loadOperators() async {
    try {
      final ops = await ref.read(operatorRepositoryProvider).list();
      if (mounted) setState(() => _operators = ops);
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(adminRoutesRepositoryProvider).zoneUpsert(
            id: widget.initial?.id,
            name: _nameCtrl.text.trim(),
            operatorId: _operatorId,
            centerLat: _center.latitude,
            centerLng: _center.longitude,
            radiusM: _radius.round(),
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final isEditing = widget.initial != null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: isEditing ? 'Editar zona' : 'Nueva zona',
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
              _section(c, Icons.title_outlined, 'Nombre'),
              const SizedBox(height: 8),
              TransitInput(
                hint: 'p.ej. El Puerto de Santa María',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 20),
              _section(c, Icons.apartment_outlined, 'Operadora (opcional)'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: c.bgRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.border, width: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _operatorId,
                    isExpanded: true,
                    dropdownColor: c.bgElevated,
                    icon: Icon(Icons.expand_more, color: c.textMid),
                    style: TransitTypography.bodyPrimary(c.textHi),
                    hint: Text('Sin operadora (global)',
                        style: TransitTypography.bodySecondary(c.textLo)),
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('Sin operadora (global)')),
                      ..._operators.map((o) => DropdownMenuItem(
                          value: o.id, child: Text(o.shortName))),
                    ],
                    onChanged: (v) => setState(() => _operatorId = v),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _section(c, Icons.place_outlined,
                  'Perímetro (toca el mapa para colocar el centro)'),
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
                    initialZoom: 12,
                    onTap: (_, pos) => setState(() => _center = pos),
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
                              border:
                                  Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.location_city,
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
                    onPressed: () => _mapController.move(_center, 13),
                    icon: const Icon(Icons.center_focus_strong, size: 14),
                    label: const Text('Centrar'),
                    style: TextButton.styleFrom(
                        foregroundColor: c.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4)),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.radio_button_unchecked, size: 14, color: c.textMid),
                  const SizedBox(width: 4),
                  Text('Radio: ${(_radius / 1000).toStringAsFixed(1)} km',
                      style: TransitTypography.bodyPrimary(c.textHi)),
                ],
              ),
              Slider(
                value: _radius,
                min: 200,
                max: 20000,
                divisions: 99,
                activeColor: c.accent,
                label: '${(_radius / 1000).toStringAsFixed(1)} km',
                onChanged: (v) => setState(() => _radius = v),
              ),
              const SizedBox(height: 24),
              TransitButton(
                label: _saving
                    ? 'Guardando…'
                    : (isEditing ? 'GUARDAR' : 'CREAR'),
                icon: Icons.check,
                isLoading: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
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
}
