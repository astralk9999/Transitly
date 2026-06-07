import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

/// Editor de horarios de una línea.
/// Tabs: una por DayType. Dentro: chips de Ida/Vuelta y rejilla de
/// horas. Acciones: añadir hora puntual, generar por frecuencia,
/// limpiar día+dirección.
class RouteSchedulesEditorScreen extends ConsumerStatefulWidget {
  const RouteSchedulesEditorScreen({super.key, required this.routeId});
  final String routeId;

  @override
  ConsumerState<RouteSchedulesEditorScreen> createState() => _State();
}

class _State extends ConsumerState<RouteSchedulesEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DayType _dayType = DayType.weekday;
  int _direction = 0;
  AdminRouteRow? _route;
  List<AdminScheduleRow> _all = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: DayType.values.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _dayType = DayType.values[_tabs.index]);
      }
    });
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final repo = ref.read(adminRoutesRepositoryProvider);
      final r = await repo.getRoute(widget.routeId);
      final s = await repo.listSchedules(widget.routeId);
      if (!mounted) return;
      setState(() {
        _route = r;
        _all = s;
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

  List<AdminScheduleRow> get _filtered => _all
      .where((s) => s.dayType == _dayType && s.direction == _direction)
      .toList()
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

  Future<void> _addOne() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    final time =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    try {
      await ref.read(adminRoutesRepositoryProvider).upsertSchedule(
            routeId: widget.routeId,
            dayType: _dayType,
            direction: _direction,
            departureTime: time,
          );
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _generateFrequency() async {
    var start = const TimeOfDay(hour: 6, minute: 0);
    var end = const TimeOfDay(hour: 23, minute: 0);
    var every = 15;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: const Text('Generar por frecuencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Inicio'),
                subtitle: Text(start.format(ctx)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final p = await showTimePicker(
                      context: ctx, initialTime: start);
                  if (p != null) setS(() => start = p);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fin'),
                subtitle: Text(end.format(ctx)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final p =
                      await showTimePicker(context: ctx, initialTime: end);
                  if (p != null) setS(() => end = p);
                },
              ),
              Row(
                children: [
                  const Expanded(child: Text('Cada (min)')),
                  SizedBox(
                    width: 80,
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: every.toString()),
                      onChanged: (v) =>
                          every = int.tryParse(v) ?? every,
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                  'Esto añade horas adicionales. Si quieres reemplazar, primero usa "Limpiar".',
                  style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Generar')),
          ],
        );
      }),
    );
    if (ok != true) return;
    final s = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final e = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    try {
      final n = await ref
          .read(adminRoutesRepositoryProvider)
          .generateFrequency(
            routeId: widget.routeId,
            dayType: _dayType,
            direction: _direction,
            startTime: s,
            endTime: e,
            intervalMinutes: every,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Añadidos $n horarios')));
      }
      await _load();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $err')));
      }
    }
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vaciar horarios'),
        content: Text(
            '¿Eliminar todos los horarios de ${_dayType.label} · ${_direction == 0 ? 'Ida' : 'Vuelta'}?'),
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
      final n = await ref.read(adminRoutesRepositoryProvider).clearSchedules(
            routeId: widget.routeId,
            dayType: _dayType,
            direction: _direction,
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Borrados $n horarios')));
      }
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _deleteOne(AdminScheduleRow s) async {
    try {
      await ref.read(adminRoutesRepositoryProvider).deleteSchedule(s.id);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: 'Horarios · ${_route?.code ?? ''}',
        transparent: true,
      ),
      body: SafeArea(
        top: false,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : Column(
                    children: [
                      TabBar(
                        controller: _tabs,
                        isScrollable: true,
                        indicatorColor: c.accent,
                        labelColor: c.accent,
                        unselectedLabelColor: c.textMid,
                        tabs: DayType.values
                            .map((d) => Tab(text: d.label))
                            .toList(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            _dirPill(c, 0, 'Ida'),
                            const SizedBox(width: 8),
                            _dirPill(c, 1, 'Vuelta'),
                            const Spacer(),
                            Text(
                              '${_filtered.length} horarios',
                              style: TransitTypography.bodySmall(c.textMid),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Sin horarios para esta combinación.\nAñade uno o genera por frecuencia.',
                                    textAlign: TextAlign.center,
                                    style: TransitTypography.bodySecondary(
                                        c.textMid),
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _filtered
                                      .map((s) => GestureDetector(
                                            onLongPress: () => _deleteOne(s),
                                            child: Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 14,
                                                  vertical: 8),
                                              decoration: BoxDecoration(
                                                color: c.accent
                                                    .withValues(alpha: 0.18),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                                border: Border.all(
                                                    color: c.accent
                                                        .withValues(
                                                            alpha: 0.4)),
                                              ),
                                              child: Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  Text(s.departureTime,
                                                      style: TransitTypography
                                                          .bodyPrimary(
                                                              c.textHi)),
                                                  const SizedBox(width: 6),
                                                  Icon(
                                                      Icons.close,
                                                      size: 14,
                                                      color: c.textMid),
                                                ],
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TransitButton(
                                    label: 'AÑADIR HORA',
                                    icon: Icons.add,
                                    onPressed: _addOne,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TransitButton(
                                    label: 'POR FRECUENCIA',
                                    icon: Icons.schedule,
                                    isPrimary: false,
                                    onPressed: _generateFrequency,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TransitButton(
                              label: 'LIMPIAR DÍA + DIRECCIÓN',
                              icon: Icons.delete_sweep_outlined,
                              isDanger: true,
                              onPressed: _clear,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _dirPill(TransitColorScheme c, int dir, String label) => Pressable(
        onTap: () => setState(() => _direction = dir),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _direction == dir
                ? c.accent.withValues(alpha: 0.25)
                : c.bgRaised.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _direction == dir ? c.accent : c.border),
          ),
          child: Text(label,
              style: TransitTypography.bodySmall(
                  _direction == dir ? c.accent : c.textMid)),
        ),
      );
}
