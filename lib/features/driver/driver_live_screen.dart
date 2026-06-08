import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/driver_live/driver_live_repository.dart';
import '../../data/geo/location_service.dart';
import '../../data/notification/local_push_service.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../shared/models/route_model.dart';
import '../../shared/providers/user_location_provider.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/responsive_scaffold.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_button.dart';
import '../../shared/widgets/transit_chip.dart';

/// Modo conductor SIMPLE: elige una línea y la hora de salida, inicia la ruta
/// y la app publica tu posición GPS en vivo (visible para todos en el mapa).
/// Sustituye al panel/editor antiguo. Ver docs/DESACTIVADO.md.
class DriverLiveScreen extends ConsumerStatefulWidget {
  const DriverLiveScreen({super.key});

  @override
  ConsumerState<DriverLiveScreen> createState() => _DriverLiveScreenState();
}

class _DriverLiveScreenState extends ConsumerState<DriverLiveScreen> {
  RouteModel? _route;
  String? _departureTime;
  bool _starting = false;
  bool _running = false;
  String? _tripId;
  Timer? _ticker;
  Timer? _clock; // refresca el cronómetro cada segundo
  DateTime? _startedAt;
  String? _error;

  static const _updateEvery = Duration(seconds: 5);
  static const _notifId = 778001; // id fijo de la notificación "compartiendo"

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final trip = await ref.read(driverLiveRepositoryProvider).myActiveTrip();
    if (trip != null && mounted) {
      // Ya hay un viaje activo (la app se reabrió): reanuda el envío.
      final mock = ref.read(mockDataServiceProvider);
      setState(() {
        _route = mock.getRouteById(trip.routeId);
        _departureTime = trip.departureTime;
        _tripId = trip.id;
        _running = true;
        _startedAt = trip.updatedAt;
      });
      _startTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  String _elapsed() {
    if (_startedAt == null) return '0:00';
    final d = DateTime.now().difference(_startedAt!);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0 ? '$h:$mm:$ss' : '$m:$ss';
  }

  List<String> _timesFor(RouteModel route) {
    // Horas de salida del día actual para esa línea (desde mockData). Si no
    // hay, deja elegir con un picker manual.
    final mock = ref.read(mockDataServiceProvider);
    final stops = mock.getStopsForRoute(route.id);
    final originId = stops.isNotEmpty ? stops.first.id : '';
    final deps = mock.getNextDepartures(route.id, originId, 24);
    final set = <String>{for (final d in deps) d.departureTime};
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _start() async {
    if (_route == null || _starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      final service = ref.read(userLocationServiceProvider);
      final pos = await service.getCurrent(timeout: const Duration(seconds: 12));
      if (pos == null) {
        setState(() {
          _starting = false;
          _error = 'No se pudo obtener tu ubicación. Activa el GPS y permite '
              'el acceso a la ubicación.';
        });
        return;
      }
      final ll = LocationService.toLatLng(pos);
      final repo = ref.read(driverLiveRepositoryProvider);
      final client = ref.read(supabaseClientProvider);
      // Nombre del conductor + operadora (para mostrar y filtrar).
      String? driverName;
      String? operatorId;
      try {
        final uid = client.auth.currentUser?.id;
        final prof = await client
            .from('profiles')
            .select('display_name, operator_id')
            .eq('id', uid!)
            .maybeSingle();
        driverName = prof?['display_name'] as String?;
        operatorId = prof?['operator_id'] as String?;
      } catch (_) {}

      final id = await repo.startTrip(
        routeId: _route!.id,
        routeCode: _route!.code,
        routeName: _route!.name,
        routeColor:
            '#${_route!.routeColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
        departureTime: _departureTime,
        operatorId: operatorId,
        driverName: driverName,
        lat: ll.latitude,
        lng: ll.longitude,
      );
      if (!mounted) return;
      setState(() {
        _tripId = id;
        _running = true;
        _starting = false;
        _startedAt = DateTime.now();
      });
      _startTicker();
      // Notificación: avisa al conductor de que está compartiendo su posición.
      unawaited(LocalPushService.instance.show(
        id: _notifId,
        title: 'Compartiendo tu ubicación',
        body: 'Línea ${_route!.code} · ${_route!.name}'
            '${_departureTime != null ? ' · salida $_departureTime' : ''}. '
            'Los pasajeros te ven en el mapa.',
      ));
    } catch (e) {
      if (mounted) {
        setState(() {
          _starting = false;
          _error = 'No se pudo iniciar la ruta: $e';
        });
      }
    }
  }

  void _startTicker() {
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _ticker?.cancel();
    _ticker = Timer.periodic(_updateEvery, (_) async {
      final id = _tripId;
      if (id == null) return;
      final pos = await ref
          .read(userLocationServiceProvider)
          .getCurrent(timeout: const Duration(seconds: 8));
      if (pos == null) return;
      final ll = LocationService.toLatLng(pos);
      await ref.read(driverLiveRepositoryProvider).updatePosition(
            tripId: id,
            lat: ll.latitude,
            lng: ll.longitude,
            heading: pos.heading,
          );
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    _clock?.cancel();
    unawaited(LocalPushService.instance.cancel(_notifId));
    await ref.read(driverLiveRepositoryProvider).endTrip();
    if (mounted) {
      setState(() {
        _running = false;
        _tripId = null;
        _startedAt = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mock = ref.watch(mockDataServiceProvider);
    final routes = mock.routes;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const TransitAppBar(title: 'Modo conductor', transparent: true),
      body: SafeArea(
        top: false,
        child: ContentConstraints(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_running)
                _runningCard(c)
              else ...[
                // Cabecera visual: icono de bus con resplandor.
                Center(
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        c.accent.withValues(alpha: 0.30),
                        c.accent.withValues(alpha: 0.05),
                      ]),
                      border: Border.all(
                          color: c.accent.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Icon(Icons.directions_bus_rounded,
                        size: 40, color: c.accent),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text('Inicia tu ruta',
                      style: TransitTypography.heading(c.textHi)),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                      'Elige tu línea y la hora de salida. Tu posición se '
                      'compartirá en vivo y los pasajeros te verán en el mapa.',
                      textAlign: TextAlign.center,
                      style: TransitTypography.bodySecondary(c.textMid)),
                ),
                const SizedBox(height: 24),
                _label(c, 'Línea'),
                const SizedBox(height: 8),
                _routeSelector(c, routes),
                if (_route != null) ...[
                  const SizedBox(height: 20),
                  _label(c, 'Hora de salida'),
                  const SizedBox(height: 8),
                  _timeSelector(c),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: c.stateCancelled.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: c.stateCancelled.withValues(alpha: 0.4)),
                    ),
                    child: Text(_error!,
                        style: TransitTypography.bodySecondary(c.textHi)),
                  ),
                ],
                const SizedBox(height: 28),
                TransitButton(
                  label: _starting ? 'Iniciando…' : 'Iniciar ruta',
                  icon: Icons.play_arrow_rounded,
                  isLoading: _starting,
                  onPressed: (_route != null && !_starting) ? _start : null,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _runningCard(TransitColorScheme c) {
    final r = _route;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCard(
          blur: 16,
          fillOpacity: 0.06,
          borderRadius: 16,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _PulsingDot(color: Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  Text('RUTA EN CURSO',
                      style: TransitTypography.bodySmall(const Color(0xFF22C55E))
                          .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const Spacer(),
                  // Cronómetro de tiempo compartiendo.
                  Text(_elapsed(),
                      style: TransitTypography.bodyPrimary(c.textHi)
                          .copyWith(fontFeatures: const [], fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  if (r != null) ...[
                    TransitChip(r.code, color: r.routeColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(r.name,
                          style: TransitTypography.heading(c.textHi),
                          maxLines: 2, overflow: TextOverflow.ellipsis),
                    ),
                  ] else
                    Expanded(
                      child: Text('Ruta en curso',
                          style: TransitTypography.heading(c.textHi)),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              // Estado: posición compartida + salida.
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: c.accent.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.my_location, size: 16, color: c.accent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('Compartiendo tu posición en vivo',
                              style: TransitTypography.bodyPrimary(c.textHi)),
                        ),
                      ],
                    ),
                    if (_departureTime != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 16, color: c.textMid),
                          const SizedBox(width: 8),
                          Text('Salida programada · ${_departureTime!}',
                              style: TransitTypography.bodySmall(c.textMid)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        TransitButton(
          label: 'Terminar ruta',
          icon: Icons.stop_rounded,
          isDanger: true,
          onPressed: _stop,
        ),
      ],
    );
  }

  Widget _label(TransitColorScheme c, String t) =>
      Text(t.toUpperCase(),
          style: TransitTypography.bodySmall(c.textMid)
              .copyWith(letterSpacing: 1, fontWeight: FontWeight.w700));

  Widget _routeSelector(TransitColorScheme c, List<RouteModel> routes) {
    return GlassCard(
      blur: 12,
      fillOpacity: 0.05,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _route?.id,
          isExpanded: true,
          dropdownColor: c.bgElevated,
          icon: Icon(Icons.expand_more, color: c.textMid),
          style: TransitTypography.bodyPrimary(c.textHi),
          hint: Text('Selecciona tu línea',
              style: TransitTypography.bodySecondary(c.textLo)),
          items: routes
              .map((r) => DropdownMenuItem(
                    value: r.id,
                    child: Text('${r.code} · ${r.name}',
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (v) {
            final mock = ref.read(mockDataServiceProvider);
            setState(() {
              _route = v == null ? null : mock.getRouteById(v);
              _departureTime = null;
            });
          },
        ),
      ),
    );
  }

  Widget _timeSelector(TransitColorScheme c) {
    final times = _timesFor(_route!);
    if (times.isEmpty) {
      // Sin horarios cargados: picker manual.
      return TransitButton(
        label: _departureTime ?? 'Elegir hora',
        icon: Icons.schedule,
        isPrimary: false,
        onPressed: () async {
          final now = TimeOfDay.now();
          final t = await showTimePicker(context: context, initialTime: now);
          if (t != null) {
            setState(() => _departureTime =
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}');
          }
        },
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((t) {
        final sel = t == _departureTime;
        return ChoiceChip(
          label: Text(t),
          selected: sel,
          onSelected: (_) => setState(() => _departureTime = t),
          backgroundColor: c.bgRaised,
          selectedColor: c.accent.withValues(alpha: 0.25),
          labelStyle: TransitTypography.bodyPrimary(sel ? c.accent : c.textHi),
          side: BorderSide(color: sel ? c.accent : c.border),
        );
      }).toList(),
    );
  }
}

/// Punto que late suavemente (indicador "en vivo").
class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value; // 0..1
        return SizedBox(
          width: 14,
          height: 14,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // halo expandiéndose
              Container(
                width: 6 + t * 8,
                height: 6 + t * 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withValues(alpha: (1 - t) * 0.5),
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
