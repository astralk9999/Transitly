import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/admin/admin_routes_repository.dart';
import '../../shared/models/enums.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';

/// Editor de horarios por parada.
/// Cada **expedición** guarda la hora de paso por CADA parada de la línea
/// (no solo la salida). Tabs por tipo de día (los 3 reales de la BD),
/// chips ida/vuelta, y lista de expediciones. Al añadir/editar una
/// expedición se fija la hora en cada parada.
class RouteSchedulesEditorScreen extends ConsumerStatefulWidget {
  const RouteSchedulesEditorScreen({super.key, required this.routeId});
  final String routeId;

  @override
  ConsumerState<RouteSchedulesEditorScreen> createState() => _State();
}

/// Solo los 3 tipos de día que existen en la BD (`day_type`).
const _dayTypes = [DayType.weekday, DayType.saturday, DayType.sundayHoliday];

class _State extends ConsumerState<RouteSchedulesEditorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  DayType _dayType = DayType.weekday;
  int _direction = 0;
  AdminRouteRow? _route;
  List<AdminTripRow> _trips = const [];
  List<AdminRouteStopRow> _routeStops = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: _dayTypes.length, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        setState(() => _dayType = _dayTypes[_tabs.index]);
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
      final trips = await repo.listTrips(widget.routeId);
      final rs = await repo.listRouteStops(widget.routeId);
      if (!mounted) return;
      setState(() {
        _route = r;
        _trips = trips;
        _routeStops = rs;
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

  List<AdminTripRow> get _filtered => _trips
      .where((t) => t.dayType == _dayType && t.direction == _direction)
      .toList()
    ..sort((a, b) => a.departureTime.compareTo(b.departureTime));

  List<AdminRouteStopRow> get _stopsForDir => _routeStops
      .where((s) => s.direction == _direction && s.stop != null)
      .toList()
    ..sort((a, b) => a.sequence.compareTo(b.sequence));

  Future<void> _editTrip([AdminTripRow? trip]) async {
    if (_stopsForDir.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Primero añade paradas a esta dirección en el editor de paradas.')));
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _TripEditor(
          routeId: widget.routeId,
          dayType: _dayType,
          direction: _direction,
          stops: _stopsForDir,
          trip: trip,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _deleteTrip(AdminTripRow t) async {
    try {
      await ref.read(adminRoutesRepositoryProvider).tripDelete(t.id);
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
                        tabAlignment: TabAlignment.start,
                        indicatorColor: c.accent,
                        labelColor: c.accent,
                        unselectedLabelColor: c.textMid,
                        tabs: _dayTypes
                            .map((d) => Tab(text: d.label))
                            .toList(),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Row(
                          children: [
                            _dirPill(c, 0, 'Ida'),
                            const SizedBox(width: 8),
                            _dirPill(c, 1, 'Vuelta'),
                            const Spacer(),
                            Text('${_filtered.length} expediciones',
                                style: TransitTypography.bodySmall(c.textMid)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _filtered.isEmpty
                            ? _empty(c)
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _tripCard(c, _filtered[i]),
                              ),
                      ),
                    ],
                  ),
      ),
      floatingActionButton: _loading
          ? null
          : FloatingActionButton.extended(
              backgroundColor: c.accent,
              foregroundColor: Colors.white,
              onPressed: () => _editTrip(),
              icon: const Icon(Icons.add),
              label: const Text('Añadir expedición'),
            ),
    );
  }

  Widget _empty(TransitColorScheme c) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Sin expediciones para ${_dayType.label} · '
            '${_direction == 0 ? 'Ida' : 'Vuelta'}.\n'
            'Añade una con el botón de abajo y fija la hora en cada parada.',
            textAlign: TextAlign.center,
            style: TransitTypography.bodySecondary(c.textMid),
          ),
        ),
      );

  Widget _tripCard(TransitColorScheme c, AdminTripRow t) {
    final stops = _stopsForDir;
    final last = stops.isNotEmpty ? t.timeForStop(stops.last.stopId) : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: () => _editTrip(t),
        child: GlassCard(
          blur: 12,
          fillOpacity: 0.06,
          borderRadius: 14,
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(t.departureTime,
                    style: TransitTypography.bodyPrimary(c.accent)
                        .copyWith(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salida ${t.departureTime}'
                        '${last != null ? ' → llegada $last' : ''}',
                        style: TransitTypography.bodyPrimary(c.textHi)),
                    Text('${t.stopTimes.length} de ${stops.length} paradas con hora',
                        style: TransitTypography.bodySmall(c.textMid)),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: c.stateCancelled),
                onPressed: () => _deleteTrip(t),
              ),
              Icon(Icons.chevron_right, color: c.textLo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dirPill(TransitColorScheme c, int dir, String label) => Pressable(
        onTap: () => setState(() => _direction = dir),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: _direction == dir ? c.accent.withValues(alpha: 0.18) : c.bgRaised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: _direction == dir ? c.accent : c.border,
                width: _direction == dir ? 1.2 : 0.5),
          ),
          child: Text(label,
              style: TransitTypography.bodySmall(
                  _direction == dir ? c.accent : c.textMid)),
        ),
      );
}

/// Editor de una expedición: fija la hora de paso por cada parada.
class _TripEditor extends ConsumerStatefulWidget {
  const _TripEditor({
    required this.routeId,
    required this.dayType,
    required this.direction,
    required this.stops,
    this.trip,
  });
  final String routeId;
  final DayType dayType;
  final int direction;
  final List<AdminRouteStopRow> stops;
  final AdminTripRow? trip;

  @override
  ConsumerState<_TripEditor> createState() => _TripEditorState();
}

class _TripEditorState extends ConsumerState<_TripEditor> {
  late Map<String, String> _times; // stopId -> 'HH:MM'
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _times = {};
    if (widget.trip != null) {
      for (final st in widget.trip!.stopTimes) {
        _times[st.stopId] = st.time;
      }
    }
  }

  /// Rellena automáticamente desde la 1ª hora con un offset por parada.
  Future<void> _autoFill() async {
    final start = await showTimePicker(
        context: context, initialTime: const TimeOfDay(hour: 7, minute: 0));
    if (start == null) return;
    final minStr = await _askMinutes();
    if (minStr == null) return;
    var t = start.hour * 60 + start.minute;
    setState(() {
      for (final s in widget.stops) {
        _times[s.stopId] =
            '${(t ~/ 60).toString().padLeft(2, '0')}:${(t % 60).toString().padLeft(2, '0')}';
        t += minStr;
      }
    });
  }

  Future<int?> _askMinutes() async {
    final ctrl = TextEditingController(text: '2');
    return showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minutos entre paradas'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(suffixText: 'min'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () =>
                  Navigator.pop(ctx, int.tryParse(ctrl.text) ?? 2),
              child: const Text('Aplicar')),
        ],
      ),
    );
  }

  Future<void> _pickTime(String stopId) async {
    final existing = _times[stopId];
    TimeOfDay initial = const TimeOfDay(hour: 7, minute: 0);
    if (existing != null && existing.contains(':')) {
      final p = existing.split(':');
      initial = TimeOfDay(
          hour: int.tryParse(p[0]) ?? 7, minute: int.tryParse(p[1]) ?? 0);
    }
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() => _times[stopId] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    final stopTimes = widget.stops
        .where((s) => _times[s.stopId] != null)
        .map((s) => (stopId: s.stopId, time: _times[s.stopId]!))
        .toList();
    if (stopTimes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Fija al menos una hora.')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(adminRoutesRepositoryProvider).tripUpsert(
            id: widget.trip?.id,
            routeId: widget.routeId,
            dayType: widget.dayType,
            direction: widget.direction,
            stopTimes: stopTimes,
          );
      if (mounted) Navigator.pop(context, true);
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: TransitAppBar(
        title: widget.trip == null ? 'Nueva expedición' : 'Editar expedición',
        transparent: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.dayType.label} · '
                      '${widget.direction == 0 ? 'Ida' : 'Vuelta'}',
                      style: TransitTypography.bodySecondary(c.textMid),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _autoFill,
                    icon: const Icon(Icons.auto_fix_high, size: 16),
                    label: const Text('Auto'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: widget.stops.length,
                itemBuilder: (_, i) {
                  final s = widget.stops[i];
                  final time = _times[s.stopId];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      blur: 12,
                      fillOpacity: 0.06,
                      borderRadius: 12,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: c.bgRaised,
                              shape: BoxShape.circle,
                              border: Border.all(color: c.border),
                            ),
                            child: Text('${i + 1}',
                                style: TransitTypography.bodySmall(c.textMid)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(s.stop?.name ?? '—',
                                style: TransitTypography.bodyPrimary(c.textHi),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          if (time != null)
                            IconButton(
                              icon: Icon(Icons.close, size: 16, color: c.textLo),
                              onPressed: () =>
                                  setState(() => _times.remove(s.stopId)),
                            ),
                          Pressable(
                            onTap: () => _pickTime(s.stopId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: time != null
                                    ? c.accent.withValues(alpha: 0.18)
                                    : c.bgRaised,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: time != null ? c.accent : c.border),
                              ),
                              child: Text(time ?? '--:--',
                                  style: TransitTypography.bodyPrimary(
                                      time != null ? c.accent : c.textMid)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: TransitButton(
                label: 'GUARDAR EXPEDICIÓN',
                icon: Icons.save_outlined,
                isLoading: _saving,
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
