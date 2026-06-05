import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/transit_colors.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/smoke_background.dart';
import '../../../../core/map/map_config.dart';
import '../live_recorder_controller.dart';

/// Active-recording view: header with timer, mini-map, stats, mark/stop buttons.
class RecorderLiveView extends StatelessWidget {
  const RecorderLiveView({
    super.key,
    required this.c,
    required this.isDark,
    required this.controller,
    required this.onStopPressed,
    this.onPausePressed,
    this.onResumePressed,
  });

  final TransitColorScheme c;
  final bool isDark;
  final LiveRecorderController controller;
  final VoidCallback onStopPressed;
  final VoidCallback? onPausePressed;
  final VoidCallback? onResumePressed;

  String _formatTime(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _accuracyColor() {
    final acc = controller.currentAccuracyM;
    if (acc == null) return Colors.grey;
    if (acc <= 10) return Colors.greenAccent;
    if (acc <= 30) return Colors.yellowAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final speed = controller.speedKmh();
    final lastStopDist = controller.distanceFromLastMarkedKm();

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: Stack(
        children: [
          Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark)),
          Column(
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top),
              _Header(
                  c: c,
                  controller: controller,
                  formatTime: _formatTime,
                  accuracyColor: _accuracyColor()),
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child:
                    _MiniMap(c: c, isDark: isDark, controller: controller),
              ),
              _StatsStrip(
                c: c,
                lastStopCount: controller.markedStops.length,
                lastStopDistKm: lastStopDist,
                speedKmh: speed,
                totalKm: controller.totalDistanceKm,
                accuracyM: controller.currentAccuracyM,
                isPaused: controller.isPaused,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: controller.markStop,
                  child: Container(
                    width: double.infinity,
                    color: controller.isPaused
                        ? c.textLo.withValues(alpha: 0.3)
                        : c.accent,
                    alignment: Alignment.center,
                    child: Text(
                      controller.isPaused
                          ? '⏸ ${AppLocalizations.of(context).statusPaused.toUpperCase()}'
                          : '＋ ${AppLocalizations.of(context).recorderMarkStop.toUpperCase()}',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: controller.isPaused ? c.textMid : c.bgRoot,
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (onPausePressed != null ||
                          onResumePressed != null) ...[
                        GestureDetector(
                          onTap: controller.isPaused
                              ? onResumePressed
                              : onPausePressed,
                          child: Container(
                            height: 36,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.orangeAccent, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              controller.isPaused ? '▶ ${AppLocalizations.of(context).actionResume.toUpperCase()}' : '⏸ ${AppLocalizations.of(context).actionPause.toUpperCase()}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.orangeAccent,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: GestureDetector(
                          onTap: onStopPressed,
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: c.stateCancelled, width: 1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '■ ${AppLocalizations.of(context).actionStop.toUpperCase()}',
                              style: GoogleFonts.ibmPlexMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: c.stateCancelled,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (controller.flashVisible)
            Positioned.fill(child: Container(color: c.accent.withAlpha(77))),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.c,
    required this.controller,
    required this.formatTime,
    required this.accuracyColor,
  });

  final TransitColorScheme c;
  final LiveRecorderController controller;
  final String Function(int) formatTime;
  final Color accuracyColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: c.bgSurface,
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: controller.blinkOn ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: controller.isPaused
                    ? Colors.orangeAccent
                    : c.stateCancelled,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.isPaused ? AppLocalizations.of(context).statusPaused.toUpperCase() : AppLocalizations.of(context).statusRecordingRoute.toUpperCase(),
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.0,
                  color: controller.isPaused
                      ? Colors.orangeAccent
                      : c.stateCancelled,
                ),
              ),
              if (controller.currentAccuracyM != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: accuracyColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'GPS ${controller.currentAccuracyM!.toStringAsFixed(1)}m',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 9,
                        color: c.textLo,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const Spacer(),
          Text(
            formatTime(controller.elapsedSeconds),
            style: GoogleFonts.ibmPlexMono(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: c.textHi,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMap extends StatelessWidget {
  const _MiniMap({
    required this.c,
    required this.isDark,
    required this.controller,
  });

  final TransitColorScheme c;
  final bool isDark;
  final LiveRecorderController controller;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controller.mapController,
      options: MapOptions(
        initialCenter: controller.path.first,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: MapConfig.tileUrl(isDark ? 'dark' : 'light'),
          subdomains: MapConfig.subdomains,
          retinaMode: true,
        ),
        if (controller.trace.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: controller.trace,
                color: c.accent,
                strokeWidth: 3,
              ),
            ],
          ),
        if (controller.lowAccuracyTrace.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: controller.lowAccuracyTrace,
                color: Colors.yellowAccent.withValues(alpha: 0.5),
                strokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            ...controller.markedStops.map((s) => Marker(
                  point: s.position,
                  width: 24,
                  height: 24,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${s.number}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )),
            if (controller.trace.isNotEmpty)
              Marker(
                point: controller.trace.last,
                width: 16,
                height: 16,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: c.stateOnRoute,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({
    required this.c,
    required this.lastStopCount,
    required this.lastStopDistKm,
    required this.speedKmh,
    required this.totalKm,
    this.accuracyM,
    this.isPaused = false,
  });

  final TransitColorScheme c;
  final int lastStopCount;
  final double lastStopDistKm;
  final double speedKmh;
  final double totalKm;
  final double? accuracyM;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Última parada: #$lastStopCount (hace ${lastStopDistKm.toStringAsFixed(2)} km)',
                style:
                    GoogleFonts.ibmPlexMono(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Velocidad: ${speedKmh.toStringAsFixed(0)} km/h',
                style:
                    GoogleFonts.ibmPlexMono(fontSize: 13, color: c.textMid),
              ),
              Text(
                'Distancia: ${totalKm.toStringAsFixed(2)} km',
                style:
                    GoogleFonts.ibmPlexMono(fontSize: 13, color: c.textMid),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
