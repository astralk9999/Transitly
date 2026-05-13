import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/mock/mock_data_service.dart';
import '../../data/mock/mock_realtime_service.dart';
import '../../shared/models/enums.dart';
import '../../shared/providers/derived/active_trip_providers.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import '../incidents/report_incident_sheet.dart';

class ActiveRouteScreen extends ConsumerStatefulWidget {
  const ActiveRouteScreen({super.key});

  @override
  ConsumerState<ActiveRouteScreen> createState() => _ActiveRouteScreenState();
}

class _ActiveRouteScreenState extends ConsumerState<ActiveRouteScreen> {
  bool _isPressed = false;
  bool _justRegistered = false;
  String _registeredTime = '';
  final List<_RegisteredStop> _history = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final mockData = ref.watch(mockDataServiceProvider);
    final realtimeTrips = ref.watch(realtimeTripsProvider);

    // Pick the first active non-cancelled trip as "our" trip
    final tripsList = realtimeTrips.valueOrNull ?? mockData.activeTrips;
    final activeTrip = tripsList.where((t) =>
        t.status != TripStatus.cancelled &&
        t.status != TripStatus.completed).firstOrNull;

    final detail = activeTrip != null
        ? ref.watch(activeTripDetailProvider(activeTrip.id))
        : null;

    if (detail == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: Stack(
          children: [
            Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('No hay ruta activa',
                      style: TransitTypography.bodyPrimary(c.textMid)),
                  const SizedBox(height: 16),
                  TransitButton(
                    label: 'VOLVER',
                    isSmall: true,
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final route = mockData.getRouteById(detail.trip.routeId);
    final currentIdx = detail.currentIdx;
    final nextIdx = currentIdx + 1;
    final nextStop = detail.nextStop;
    final firstStop = detail.firstStop;
    final lastStop = detail.lastStop;

    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
        children: [
          // Safe area top
          SizedBox(height: MediaQuery.of(context).padding.top),

          // ── a) HEADER ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.bgSurface,
              border: Border(left: BorderSide(color: c.accent, width: 3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'RUTA ACTIVA',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: c.accent,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${route?.code ?? '?'} · $timeStr INICIO',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 13, color: c.textMid),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${firstStop.name} → ${lastStop.name}',
                  style: TransitTypography.bodyPrimary(c.textHi),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── b) PRÓXIMA PARADA ──
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRÓXIMA PARADA',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                    color: c.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        nextStop?.name ?? '--',
                        style: GoogleFonts.dmSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: c.textHi,
                        ),
                      ),
                    ),
                    Text(
                      'en 0.${(nextIdx % 5) + 1} km',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 18, color: c.textMid),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '~${(nextIdx % 4) + 1} min',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: c.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── c) BOTÓN REGISTRAR PARADA ──
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTapDown: (_) {
                  HapticFeedback.mediumImpact();
                  setState(() => _isPressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _registerStop(context, c, nextStop?.name ?? '?');
                },
                onTapCancel: () => setState(() => _isPressed = false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  transform: Matrix4.diagonal3Values(
                    _isPressed ? 0.96 : 1.0,
                    _isPressed ? 0.96 : 1.0,
                    1.0,
                  ),
                  transformAlignment: Alignment.center,
                  constraints: const BoxConstraints(minHeight: 120),
                  decoration: BoxDecoration(
                    color: _justRegistered ? c.bgSurface : c.accent,
                    border: _justRegistered
                        ? Border.all(color: c.accent, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _justRegistered
                        ? 'PARADA REGISTRADA · $_registeredTime'
                        : '✓ REGISTRAR PARADA',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _justRegistered ? c.accent : c.bgRoot,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── d) INCIDENCIA ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: TransitButton(
                label: '⚠ INCIDENCIA',
                isDanger: true,
                isSmall: true,
                onPressed: () => showReportIncidentSheet(
                  context,
                  ref: ref,
                  route: route,
                  stop: nextStop,
                ),
              ),
            ),
          ),

          // ── e) HISTORIAL ──
          if (_history.isNotEmpty)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                children: _history.reversed.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '✓ ${entry.name} · ${entry.time}',
                      style: GoogleFonts.ibmPlexMono(
                          fontSize: 13, color: c.textMid),
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── f) FINALIZAR ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: TransitButton(
                  label: 'FINALIZAR RUTA',
                  isDanger: true,
                  onPressed: () => _confirmFinish(context, c),
                ),
              ),
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }

  void _registerStop(
      BuildContext context, TransitColorScheme c, String stopName) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    // Simulate stop registration via realtime service
    final service = ref.read(mockRealtimeServiceProvider);
    final trips = service.currentTrips;
    final activeTrip = trips.where((t) =>
        t.status != TripStatus.cancelled &&
        t.status != TripStatus.completed).firstOrNull;
    if (activeTrip != null) {
      service.simulateStopRegistration(activeTrip.id);
    }

    setState(() {
      _justRegistered = true;
      _registeredTime = time;
      _history.add(_RegisteredStop(stopName, time));
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _justRegistered = false);
    });
  }

  void _confirmFinish(BuildContext context, TransitColorScheme c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text('¿Finalizar ruta?',
            style: TransitTypography.heading(c.textHi)),
        content: Text('Se registrará la ruta como completada.',
            style: TransitTypography.bodySecondary(c.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('CANCELAR',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/home/inicio');
            },
            child: Text('FINALIZAR',
                style: TransitTypography.bodySecondary(c.stateCancelled)),
          ),
        ],
      ),
    );
  }
}

class _RegisteredStop {
  final String name;
  final String time;
  const _RegisteredStop(this.name, this.time);
}
