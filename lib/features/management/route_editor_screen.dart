import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../data/operator/operator_repository_provider.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/operator_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

class RouteEditorScreen extends ConsumerStatefulWidget {
  const RouteEditorScreen({
    super.key,
    this.routeId,
    this.initialOperatorId,
  });
  final String? routeId;
  final String? initialOperatorId;
  bool get isNew => routeId == null;

  @override
  ConsumerState<RouteEditorScreen> createState() => _State();
}

class _State extends ConsumerState<RouteEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _colorHex;

  String? _operatorId;
  RouteStatus _status = RouteStatus.draft;
  RouteSource _source = RouteSource.official;
  bool _active = true;

  bool _loading = true;
  bool _saving = false;
  bool _isAdmin = false;
  String? _error;
  List<OperatorModel> _operators = const [];

  @override
  void initState() {
    super.initState();
    _code = TextEditingController();
    _name = TextEditingController();
    _description = TextEditingController();
    _colorHex = TextEditingController(text: '#977DDF');
    _load();
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    _description.dispose();
    _colorHex.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final scope = await ref.read(manageScopeProvider.future);
      _isAdmin = scope.isAdmin;
      _operators = scope.isAdmin
          ? await ref.read(operatorRepositoryProvider).list()
          : (scope.operatorId == null
              ? const []
              : [
                  await ref
                      .read(operatorRepositoryProvider)
                      .byId(scope.operatorId!)
                ].whereType<OperatorModel>().toList());
      if (!widget.isNew) {
        final repo = ref.read(adminRoutesRepositoryProvider);
        final r = await repo.getRoute(widget.routeId!);
        if (r != null) {
          _code.text = r.code;
          _name.text = r.name;
          _description.text = r.description ?? '';
          _colorHex.text = r.color ?? '#977DDF';
          _status = r.status;
          _source = r.source;
          _active = r.active;
          _operatorId = r.operatorId;
        }
      } else {
        _operatorId = widget.initialOperatorId ??
            (scope.operatorId ??
                (_operators.isNotEmpty ? _operators.first.id : null));
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_operatorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un operador')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(adminRoutesRepositoryProvider);
      await repo.upsertRoute(
        id: widget.routeId,
        operatorId: _operatorId!,
        code: _code.text.trim(),
        name: _name.text.trim(),
        description: _description.text.trim().isEmpty
            ? null
            : _description.text.trim(),
        color: _colorHex.text.trim().isEmpty ? null : _colorHex.text.trim(),
        status: _status,
        source: _source,
        active: _active,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Línea guardada')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar línea'),
        content: const Text(
            'Se borrará la línea y todas sus paradas vinculadas y horarios. ¿Continuar?'),
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
    if (confirmed != true || widget.routeId == null) return;
    try {
      await ref
          .read(adminRoutesRepositoryProvider)
          .deleteRoute(widget.routeId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Línea eliminada')));
        Navigator.pop(context);
      }
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: widget.isNew ? 'Nueva línea' : 'Editar línea',
        transparent: true,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _section(c, 'Datos básicos'),
                        const SizedBox(height: 8),
                        _input(c, 'Código', _code,
                            hint: 'p.ej. L1, L2A',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null),
                        const SizedBox(height: 10),
                        _input(c, 'Nombre', _name,
                            hint: 'p.ej. Plaza del Arenal – Hospital',
                            validator: (v) =>
                                (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null),
                        const SizedBox(height: 10),
                        _input(c, 'Descripción (opcional)', _description,
                            hint: 'Notas internas o recorrido resumido',
                            maxLines: 3),
                        const SizedBox(height: 10),
                        _colorRow(c),
                        const SizedBox(height: 16),
                        _section(c, 'Operador'),
                        const SizedBox(height: 8),
                        _operatorDropdown(c),
                        const SizedBox(height: 16),
                        _section(c, 'Estado'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: RouteStatus.values
                              .map((s) => _pill(c,
                                  label: s.label,
                                  selected: _status == s,
                                  onTap: () => setState(() => _status = s)))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          children: RouteSource.values
                              .map((s) => _pill(c,
                                  label: s.name == 'official'
                                      ? 'Oficial'
                                      : 'Comunitaria',
                                  selected: _source == s,
                                  onTap: () => setState(() => _source = s)))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeColor: c.accent,
                          title: Text('Activa',
                              style: TransitTypography.bodyPrimary(c.textHi)),
                          subtitle: Text(
                              'Aparece en la app de pasajeros y conductores',
                              style: TransitTypography.bodySmall(c.textMid)),
                          value: _active,
                          onChanged: (v) => setState(() => _active = v),
                        ),
                        const SizedBox(height: 16),
                        if (!widget.isNew) ...[
                          _section(c, 'Gestión avanzada'),
                          const SizedBox(height: 8),
                          _navTile(c,
                              icon: Icons.place_outlined,
                              title: 'Paradas',
                              subtitle:
                                  'Añadir, mover y reordenar paradas en el mapa',
                              onTap: () => context.push(
                                  '/management/routes/${widget.routeId}/stops')),
                          const SizedBox(height: 8),
                          _navTile(c,
                              icon: Icons.schedule,
                              title: 'Horarios',
                              subtitle:
                                  'Frecuencias y horas por día y dirección',
                              onTap: () => context.push(
                                  '/management/routes/${widget.routeId}/schedules')),
                          const SizedBox(height: 16),
                        ],
                        TransitButton(
                          label: widget.isNew ? 'CREAR LÍNEA' : 'GUARDAR',
                          icon: Icons.save_outlined,
                          isLoading: _saving,
                          onPressed: _save,
                        ),
                        if (!widget.isNew) ...[
                          const SizedBox(height: 10),
                          TransitButton(
                            label: 'ELIMINAR LÍNEA',
                            icon: Icons.delete_outline,
                            isDanger: true,
                            onPressed: _delete,
                          ),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _section(TransitColorScheme c, String label) =>
      Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(label.toUpperCase(),
            style: TransitTypography.bodySmall(c.textLo)
                .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
      );

  Widget _input(TransitColorScheme c, String label, TextEditingController ctrl,
      {String? hint,
      int maxLines = 1,
      String? Function(String?)? validator}) {
    return GlassCard(
      blur: 14,
      fillOpacity: 0.06,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: TextFormField(
        controller: ctrl,
        validator: validator,
        maxLines: maxLines,
        style: TransitTypography.bodyPrimary(c.textHi),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
          labelStyle: TransitTypography.bodySmall(c.textMid),
          hintText: hint,
          hintStyle: TransitTypography.bodySmall(c.textLo),
        ),
      ),
    );
  }

  Widget _colorRow(TransitColorScheme c) {
    final color = _parseHex(_colorHex.text) ?? c.accent;
    return GlassCard(
      blur: 14,
      fillOpacity: 0.06,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickColor,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: c.border),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _colorHex,
              style: TransitTypography.bodyPrimary(c.textHi),
              decoration: InputDecoration(
                border: InputBorder.none,
                labelText: 'Color (hex)',
                labelStyle: TransitTypography.bodySmall(c.textMid),
                hintText: '#977DDF',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickColor() async {
    const presets = [
      '#977DDF', '#00D4FF', '#FF006E', '#FF8C00', '#B0FF00',
      '#3B82F6', '#00A0FF', '#9333EA', '#10B981', '#F43F5E',
      '#FACC15', '#94A3B8',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            blur: 24,
            fillOpacity: 0.10,
            borderRadius: 18,
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: presets
                  .map((h) => GestureDetector(
                        onTap: () => Navigator.pop(ctx, h),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _parseHex(h),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
    if (picked != null) {
      setState(() => _colorHex.text = picked);
    }
  }

  Widget _operatorDropdown(TransitColorScheme c) {
    if (!_isAdmin) {
      final op = _operators.isEmpty
          ? null
          : _operators.firstWhere((o) => o.id == _operatorId,
              orElse: () => _operators.first);
      return GlassCard(
        blur: 14,
        fillOpacity: 0.06,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.lock_outline, color: c.textMid, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(op?.shortName ?? '—',
                  style: TransitTypography.bodyPrimary(c.textHi)),
            ),
          ],
        ),
      );
    }
    return GlassCard(
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
          decoration: InputDecoration(
            border: InputBorder.none,
            labelText: 'Operador',
            labelStyle: TransitTypography.bodySmall(c.textMid),
          ),
          items: _operators
              .map((o) => DropdownMenuItem(
                    value: o.id,
                    child: Text(o.shortName),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _operatorId = v),
        ),
      ),
    );
  }

  Widget _pill(TransitColorScheme c,
          {required String label,
          required bool selected,
          required VoidCallback onTap}) =>
      Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? c.accent.withValues(alpha: 0.25)
                : c.bgRaised.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? c.accent : c.border),
          ),
          child: Text(label,
              style: TransitTypography.bodySmall(
                  selected ? c.accent : c.textMid)),
        ),
      );

  Widget _navTile(TransitColorScheme c,
          {required IconData icon,
          required String title,
          required String subtitle,
          required VoidCallback onTap}) =>
      Pressable(
        onTap: onTap,
        child: GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(icon, color: c.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TransitTypography.bodyPrimary(c.textHi)),
                    Text(subtitle,
                        style: TransitTypography.bodySmall(c.textMid)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.textLo),
            ],
          ),
        ),
      );

  Color? _parseHex(String hex) {
    var h = hex.trim().replaceFirst('#', '');
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
