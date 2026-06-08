import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/driver_live/driver_live_repository.dart';
import '../../data/geo/location_service.dart';
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
  DateTime? _startedAt;
  String? _error;

  static const _updateEvery = Duration(seconds: 5);

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
    super.dispose();
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
                Text('Inicia tu ruta',
                    style: TransitTypography.heading(c.textHi)),
                const SizedBox(height: 4),
                Text(
                    'Elige tu línea y la hora de salida. Tu posición se '
                    'compartirá en vivo y los pasajeros te verán en el mapa.',
                    style: TransitTypography.bodySecondary(c.textMid)),
                const SizedBox(height: 20),
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
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('RUTA EN CURSO',
                      style: TransitTypography.bodySmall(const Color(0xFF22C55E))
                          .copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
                ],
              ),
              const SizedBox(height: 16),
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
              if (_departureTime != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: c.textMid),
                    const SizedBox(width: 6),
                    Text('Salida ${_departureTime!}',
                        style: TransitTypography.bodyPrimary(c.textMid)),
                  ],
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: c.accent),
                  const SizedBox(width: 6),
                  Text('Compartiendo tu posición en vivo',
                      style: TransitTypography.bodySmall(c.textMid)),
                ],
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
