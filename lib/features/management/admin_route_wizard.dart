import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/uuid.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';
import '../create_route/steps/step_basic_info.dart';
import '../create_route/steps/step_schedules.dart';
import '../create_route/steps/step_stops.dart';
import '../create_route/steps/wizard_models.dart';

/// Wizard de creación/edición de línea OFICIAL para admin / operator_admin.
/// Reutiliza los pasos del wizard de comunidad (Info, Paradas con mapa,
/// Horarios) pero escribe en las tablas oficiales vía RPCs admin y añade un
/// paso de Operador + Código + Estado en lugar de Visibilidad.
///
/// Si se pasa [routeId], entra en modo EDICIÓN: carga la línea con sus
/// paradas y horarios y, al guardar, sincroniza por diff (preserva los
/// horarios que no se tocan, incluidos los exactos por parada).
class AdminRouteWizard extends ConsumerStatefulWidget {
  const AdminRouteWizard({super.key, this.initialOperatorId, this.routeId});

  final String? initialOperatorId;
  final String? routeId;

  @override
  ConsumerState<AdminRouteWizard> createState() => _AdminRouteWizardState();
}

class _AdminRouteWizardState extends ConsumerState<AdminRouteWizard> {
  static const _logTag = 'AdminRouteWizard';
  final _pageController = PageController();
  int _step = 0;
  static const _stepCount = 4; // Info · Paradas · Horarios · Operador/Resumen

  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  String _routeColor = '0xFF977DDF';
  String _serviceType = 'urban';

  final List<WizardStop> _stops = [];
  final List<WizardSchedule> _schedules = [];

  String? _operatorId;
  RouteStatus _status = RouteStatus.official;
  bool _active = true;

  bool _loading = true;
  bool _saving = false;
  List<OperatorModel> _operators = const [];
  bool _isAdmin = false;

  // Modo edición: id de la línea + estado original para hacer diff seguro al
  // guardar (paradas y horarios) sin destruir lo que no se toca.
  String? get _editingId => widget.routeId;
  bool get _isEditing => widget.routeId != null;
  List<String> _origStopIds = const []; // stopId de las paradas actuales
  final Map<String, String> _origSchedKeys = {}; // 'dayType|HH:mm' → schedule id

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onChanged);
    _codeCtrl.addListener(_onChanged);
    _load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
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
    _operatorId = widget.initialOperatorId ??
        scope.operatorId ??
        (_operators.isNotEmpty ? _operators.first.id : null);

    if (_isEditing) {
      await _loadExisting();
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Carga la línea existente (datos + paradas + horarios) para editarla.
  Future<void> _loadExisting() async {
    final repo = ref.read(adminRoutesRepositoryProvider);
    try {
      final route = await repo.getRoute(_editingId!);
      if (route != null) {
        _nameCtrl.text = route.name;
        _codeCtrl.text = route.code;
        _operatorId = route.operatorId;
        if ((route.color ?? '').isNotEmpty) {
          final hex = route.color!.replaceFirst('#', '');
          _routeColor = '0xFF${hex.length == 6 ? hex : '977DDF'}';
        }
        _status = route.status;
        _descCtrl.text = route.description ?? '';
      }
      // Paradas en orden (dirección 0).
      final rs = await repo.listRouteStops(_editingId!);
      rs.sort((a, b) => a.sequence.compareTo(b.sequence));
      _stops.clear();
      for (final r in rs) {
        final st = r.stop;
        if (st == null) continue;
        _stops.add(WizardStop(
          stopId: st.id,
          name: st.name,
          lat: st.lat,
          lng: st.lng,
          officialStopId: st.id,
          orderIndex: r.sequence,
        ));
      }
      _origStopIds = [for (final r in rs) r.stopId];
      // Horarios: cargamos todos como horas de cabecera y guardamos su id por
      // clave para hacer diff al guardar (preserva los que no se tocan).
      final scheds = await repo.listSchedules(_editingId!);
      _schedules.clear();
      _origSchedKeys.clear();
      for (final s in scheds) {
        final dayName = s.dayType.name;
        _schedules.add(WizardSchedule(
            dayType: dayName, departureTime: s.departureTime));
        _origSchedKeys['$dayName|${s.departureTime}'] = s.id;
      }
    } catch (e) {
      AppLogger.error(_logTag, 'load existing failed', e);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _codeCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    _pageController.animateToPage(step,
        duration: const Duration(milliseconds: 280), curve: Curves.easeInOut);
    setState(() => _step = step);
  }

  bool _canProceed() {
    switch (_step) {
      case 0:
        return _codeCtrl.text.trim().isNotEmpty &&
            _nameCtrl.text.trim().length >= 3;
      case 1:
        return _stops.length >= 2;
      case 2:
        return true;
      case 3:
        return _operatorId != null &&
            _codeCtrl.text.trim().isNotEmpty &&
            _nameCtrl.text.trim().length >= 3 &&
            _stops.length >= 2;
      default:
        return false;
    }
  }

  /// Convierte el color del wizard ('0xFFRRGGBB') a hex '#RRGGBB' para la BD.
  String _colorHex() {
    final v = _routeColor.replaceFirst('0x', '').replaceFirst('#', '');
    final rgb = v.length == 8 ? v.substring(2) : v;
    return '#$rgb';
  }

  Future<void> _publish() async {
    if (_saving || !_canProceed()) return;
    setState(() => _saving = true);
    final repo = ref.read(adminRoutesRepositoryProvider);
    try {
      final routeId = await repo.upsertRoute(
        id: _editingId,
        operatorId: _operatorId!,
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        description:
            _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        color: _colorHex(),
        status: _status,
        source: RouteSource.official,
        active: _active,
      );

      // Paradas: vincula cada una a la ruta en orden (admin_route_stop_add
      // hace upsert por secuencia). En edición, quita después las que ya no
      // están.
      final keptStopIds = <String>{};
      for (var i = 0; i < _stops.length; i++) {
        final ws = _stops[i];
        final stopId = await repo.upsertStop(
          operatorId: _operatorId!,
          code: ws.officialStopId ?? generateUuidV4().substring(0, 8),
          name: ws.name,
          lat: ws.lat,
          lng: ws.lng,
        );
        await repo.addStopToRoute(
            routeId: routeId, stopId: stopId, sequence: i, direction: 0);
        keptStopIds.add(stopId);
      }
      if (_isEditing) {
        for (final oldId in _origStopIds) {
          if (!keptStopIds.contains(oldId)) {
            await repo.removeStopFromRoute(
                routeId: routeId, stopId: oldId, direction: 0);
          }
        }
      }

      // Horarios: diff por clave 'dayType|HH:mm'. Solo se crean los nuevos y
      // se borran los que el admin quitó; los que no cambian (incluidos los
      // exactos por parada con arrival_offsets) se preservan intactos.
      final keptKeys = <String>{};
      for (final s in _schedules) {
        final key = '${s.dayType}|${s.departureTime}';
        keptKeys.add(key);
        if (_origSchedKeys.containsKey(key)) continue; // ya existe, no tocar
        await repo.upsertSchedule(
          routeId: routeId,
          dayType: DayType.fromString(s.dayType),
          direction: 0,
          departureTime: s.departureTime,
        );
      }
      if (_isEditing) {
        for (final entry in _origSchedKeys.entries) {
          if (!keptKeys.contains(entry.key)) {
            await repo.deleteSchedule(entry.value);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_isEditing
                ? 'Línea oficial actualizada'
                : 'Línea oficial creada')));
        context.pop();
      }
    } catch (e) {
      AppLogger.error(_logTag, 'publish failed', e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: TransitAppBar(
            title: _isEditing ? 'Editar línea oficial' : 'Nueva línea oficial',
            transparent: true),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
          title: _isEditing ? 'Editar línea oficial' : 'Nueva línea oficial',
          transparent: true),
      body: Column(
        children: [
          _indicator(c),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _step = i),
              children: [
                _infoPage(c),
                StepStops(stops: _stops, onChanged: () => setState(() {})),
                StepSchedules(
                  schedules: _schedules,
                  stops: _stops,
                  onChanged: () => setState(() {}),
                ),
                _operatorPage(c),
              ],
            ),
          ),
          _bottomBar(c),
        ],
      ),
    );
  }

  // Paso 0: info básica + código de línea (el código no existe en el wizard
  // de comunidad, lo añadimos arriba).
  Widget _infoPage(TransitColorScheme c) {
    return ListView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      children: [
        Text('Código de línea',
            style: TransitTypography.bodySmall(c.textMid)),
        const SizedBox(height: TransitSpacing.space4),
        TransitInput(
          controller: _codeCtrl,
          hint: 'p.ej. L1, L2A',
        ),
        const SizedBox(height: TransitSpacing.space12),
        StepBasicInfo(
          nameCtrl: _nameCtrl,
          descCtrl: _descCtrl,
          routeColor: _routeColor,
          serviceType: _serviceType,
          onColorChanged: (v) => setState(() => _routeColor = v),
          onServiceTypeChanged: (v) => setState(() => _serviceType = v),
        ),
      ],
    );
  }

  // Paso 3: operador + estado + resumen.
  Widget _operatorPage(TransitColorScheme c) {
    return ListView(
      padding: const EdgeInsets.all(TransitSpacing.space16),
      children: [
        Text('Operador', style: TransitTypography.heading(c.textHi)),
        const SizedBox(height: TransitSpacing.space4),
        Text('Asigna la línea a un operador.',
            style: TransitTypography.bodySecondary(c.textMid)),
        const SizedBox(height: TransitSpacing.space12),
        if (_isAdmin)
          GlassCard(
            blur: 14,
            fillOpacity: 0.06,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                value: _operatorId,
                isExpanded: true,
                dropdownColor: c.bgRaised,
                style: TransitTypography.bodyPrimary(c.textHi),
                icon: Icon(Icons.expand_more, color: c.textMid),
                decoration: const InputDecoration(border: InputBorder.none),
                items: _operators
                    .map((o) => DropdownMenuItem(
                        value: o.id, child: Text(o.shortName)))
                    .toList(),
                onChanged: (v) => setState(() => _operatorId = v),
              ),
            ),
          )
        else
          GlassCard(
            blur: 14,
            fillOpacity: 0.06,
            borderRadius: 12,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.lock_outline, color: c.textMid, size: 18),
                const SizedBox(width: 10),
                Text(
                  _operators.isEmpty ? '—' : _operators.first.shortName,
                  style: TransitTypography.bodyPrimary(c.textHi),
                ),
              ],
            ),
          ),
        const SizedBox(height: TransitSpacing.space20),
        Text('Estado', style: TransitTypography.heading(c.textHi)),
        const SizedBox(height: TransitSpacing.space8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RouteStatus.values
              .map((s) => Pressable(
                    onTap: () => setState(() => _status = s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: _status == s
                            ? c.accent.withValues(alpha: 0.25)
                            : c.bgRaised.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: _status == s ? c.accent : c.border),
                      ),
                      child: Text(s.label,
                          style: TransitTypography.bodySmall(
                              _status == s ? c.accent : c.textMid)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: TransitSpacing.space16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeColor: c.accent,
          title: Text('Activa', style: TransitTypography.bodyPrimary(c.textHi)),
          subtitle: Text('Visible en la app de pasajeros',
              style: TransitTypography.bodySmall(c.textMid)),
          value: _active,
          onChanged: (v) => setState(() => _active = v),
        ),
        const Divider(height: 32),
        _summaryRow(c, 'Código', _codeCtrl.text.trim()),
        _summaryRow(c, 'Nombre', _nameCtrl.text.trim()),
        _summaryRow(c, 'Paradas', '${_stops.length}'),
        _summaryRow(c, 'Horarios', '${_schedules.length}'),
      ],
    );
  }

  Widget _summaryRow(TransitColorScheme c, String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(k, style: TransitTypography.bodySmall(c.textMid)),
            const Spacer(),
            Text(v.isEmpty ? '—' : v,
                style: TransitTypography.bodyPrimary(c.textHi)),
          ],
        ),
      );

  Widget _indicator(TransitColorScheme c) {
    const labels = ['Info', 'Paradas', 'Horarios', 'Operador'];
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space16, vertical: TransitSpacing.space12),
      color: c.bgRaised,
      child: Row(
        children: List.generate(_stepCount, (i) {
          final active = i <= _step;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? c.accent : c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(labels[i],
                    style: TransitTypography.bodySmall(
                        i == _step ? c.accent : c.textLo)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _bottomBar(TransitColorScheme c) {
    final isLast = _step == _stepCount - 1;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space16, vertical: TransitSpacing.space12),
      decoration: BoxDecoration(
        color: c.bgRaised,
        border: Border(top: BorderSide(color: c.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_step > 0)
              TransitButton(
                label: 'Atrás',
                isPrimary: false,
                onPressed: () => _goTo(_step - 1),
              ),
            const Spacer(),
            if (isLast)
              TransitButton(
                label: _saving
                    ? 'Guardando...'
                    : (_isEditing ? 'Guardar cambios' : 'Crear línea'),
                isLoading: _saving,
                onPressed: _canProceed() && !_saving ? _publish : null,
              )
            else
              TransitButton(
                label: 'Siguiente',
                onPressed: _canProceed() ? () => _goTo(_step + 1) : null,
              ),
          ],
        ),
      ),
    );
  }
}
