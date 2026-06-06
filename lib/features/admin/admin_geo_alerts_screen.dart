import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/uuid.dart';
import '../../data/geo_alerts/geo_alerts_repository.dart';
import '../../shared/models/geo_alert_model.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_input.dart';

/// Sub P2-#55: CRUD de avisos geolocalizados (admin only).
class AdminGeoAlertsScreen extends ConsumerStatefulWidget {
  const AdminGeoAlertsScreen({super.key});

  @override
  ConsumerState<AdminGeoAlertsScreen> createState() =>
      _AdminGeoAlertsScreenState();
}

class _AdminGeoAlertsScreenState extends ConsumerState<AdminGeoAlertsScreen> {
  List<GeoAlertModel> _alerts = [];
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
    final messenger = ScaffoldMessenger.of(context);
    final result = await showDialog<GeoAlertModel>(
      context: context,
      builder: (_) => const _GeoAlertFormDialog(),
    );
    if (result == null) return;
    try {
      final repo = ref.read(geoAlertsRepositoryProvider);
      await repo.create(result);
      await _load();
      ref.invalidate(activeGeoAlertsProvider);
      messenger.showSnackBar(const SnackBar(
        content: Text('Aviso creado'),
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        duration: const Duration(seconds: 3),
      ));
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
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('Eliminar',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error))),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(geoAlertsRepositoryProvider).delete(a.id);
    await _load();
    ref.invalidate(activeGeoAlertsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              children: [
                TransitAppBar(
                  title: 'Avisos geo',
                  actions: [
                    IconButton(
                      icon: Icon(Icons.add, color: c.accent),
                      tooltip: 'Crear aviso',
                      onPressed: _onCreate,
                    ),
                  ],
                ),
                Expanded(child: _buildContent(c)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!,
                style: TransitTypography.bodyPrimary(c.stateCancelled)),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 64, color: c.textLo),
            const SizedBox(height: 12),
            Text('No hay avisos creados',
                style: TransitTypography.bodyPrimary(c.textMid)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _alerts.length,
      itemBuilder: (_, i) {
        final a = _alerts[i];
        final sevColor = switch (a.severity) {
          GeoAlertSeverity.info => c.accent,
          GeoAlertSeverity.warning => c.stateDelay,
          GeoAlertSeverity.critical => c.stateCancelled,
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sevColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        a.severity.name.toUpperCase(),
                        style: TransitTypography.bodySmall(sevColor),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        a.title,
                        style: TransitTypography.bodyPrimary(
                            a.active ? c.textHi : c.textLo),
                      ),
                    ),
                    if (!a.active)
                      Text('INACTIVO',
                          style:
                              TransitTypography.bodySmall(c.stateCancelled)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(a.body,
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 4),
                Text(
                  'Centro: ${a.centerLat.toStringAsFixed(4)}, '
                  '${a.centerLng.toStringAsFixed(4)} · Radio: ${a.radiusM}m',
                  style: TransitTypography.bodySmall(c.textLo),
                ),
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        a.active ? Icons.visibility : Icons.visibility_off,
                        color: c.accent,
                        size: 20,
                      ),
                      tooltip:
                          a.active ? 'Desactivar' : 'Activar',
                      onPressed: () => _toggleActive(a),
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
        );
      },
    );
  }
}

class _GeoAlertFormDialog extends StatefulWidget {
  const _GeoAlertFormDialog();
  @override
  State<_GeoAlertFormDialog> createState() => _GeoAlertFormDialogState();
}

class _GeoAlertFormDialogState extends State<_GeoAlertFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _latCtrl = TextEditingController(text: '36.6850');
  final _lngCtrl = TextEditingController(text: '-6.1376');
  int _radius = 500;
  GeoAlertSeverity _severity = GeoAlertSeverity.info;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    return AlertDialog(
      title: Text('Crear aviso geo',
          style: TransitTypography.subheading(c.textHi)),
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              const SizedBox(height: 12),
              Text('Severidad',
                  style: TransitTypography.bodySmall(c.textMid)),
              const SizedBox(height: 4),
              SegmentedButton<GeoAlertSeverity>(
                segments: const [
                  ButtonSegment(
                      value: GeoAlertSeverity.info, label: Text('Info')),
                  ButtonSegment(
                      value: GeoAlertSeverity.warning,
                      label: Text('Aviso')),
                  ButtonSegment(
                      value: GeoAlertSeverity.critical,
                      label: Text('Crítico')),
                ],
                selected: {_severity},
                onSelectionChanged: (s) {
                  if (s.isNotEmpty) setState(() => _severity = s.first);
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TransitInput(
                      hint: 'Lat',
                      controller: _latCtrl,
                      validator: (v) {
                        if (v == null) return 'req';
                        return double.tryParse(v.trim()) == null
                            ? 'numérico'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TransitInput(
                      hint: 'Lng',
                      controller: _lngCtrl,
                      validator: (v) {
                        if (v == null) return 'req';
                        return double.tryParse(v.trim()) == null
                            ? 'numérico'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Radio: ${_radius}m',
                  style: TransitTypography.bodySmall(c.textMid)),
              Slider(
                value: _radius.toDouble(),
                min: 50,
                max: 5000,
                divisions: 99,
                activeColor: c.accent,
                label: '${_radius}m',
                onChanged: (v) => setState(() => _radius = v.round()),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TransitButton(
          label: 'CREAR',
          isSmall: true,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final lat = double.parse(_latCtrl.text.trim());
            final lng = double.parse(_lngCtrl.text.trim());
            Navigator.of(context).pop(GeoAlertModel(
              id: generateUuidV4(),
              title: _titleCtrl.text.trim(),
              body: _bodyCtrl.text.trim(),
              severity: _severity,
              centerLat: lat,
              centerLng: lng,
              radiusM: _radius,
            ));
          },
        ),
      ],
    );
  }
}
