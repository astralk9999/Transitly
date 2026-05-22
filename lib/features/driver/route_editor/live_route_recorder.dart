import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../data/geo/geo_providers.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'live_recorder_controller.dart';
import 'widgets/recorder_live_view.dart';
import 'widgets/recorder_pre_form.dart';

class LiveRouteRecorder extends ConsumerStatefulWidget {
  const LiveRouteRecorder({super.key});

  @override
  ConsumerState<LiveRouteRecorder> createState() =>
      _LiveRouteRecorderState();
}

class _LiveRouteRecorderState extends ConsumerState<LiveRouteRecorder> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _serviceType = 'urban';
  late LiveRecorderController _controller;

  @override
  void initState() {
    super.initState();
    _initController();
    _controller.onStopMarked = (stop) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final c = TransitColorScheme.of(isDark);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PARADA #${stop.number} MARCADA · ${stop.distanceKm.toStringAsFixed(2)} km',
            style: GoogleFonts.ibmPlexMono(color: c.accent),
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    };
  }

  void _initController() {
    final locationService = ref.read(locationServiceProvider);
    _controller = LiveRecorderController(locationService: locationService);
  }

  @override
  void dispose() {
    _controller.dispose();
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!_controller.isRecording) {
          return RecorderPreForm(
            c: c,
            isDark: isDark,
            codeCtrl: _codeCtrl,
            nameCtrl: _nameCtrl,
            serviceType: _serviceType,
            onServiceTypeChanged: (v) => setState(() => _serviceType = v),
            onStart: () => _controller.start(),
          );
        }
        return RecorderLiveView(
          c: c,
          isDark: isDark,
          controller: _controller,
          onPausePressed: _controller.pause,
          onResumePressed: _controller.resume,
          onStopPressed: () => _confirmStop(c),
        );
      },
    );
  }

  void _confirmStop(TransitColorScheme c) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.bgSurface,
        title: Text('¿Detener grabación?',
            style: TransitTypography.heading(c.textHi)),
        content: Text(
          '${_controller.markedStops.length} paradas marcadas · ${_controller.totalDistanceKm.toStringAsFixed(1)} km',
          style: TransitTypography.bodySecondary(c.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context).actionContinue.toUpperCase(),
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () async {
              final session = _controller.getCurrentSession();
              _controller.stop();
              Navigator.of(ctx).pop();
              if (!mounted) return;
              unawaited(context.push('/driver/editor/post', extra: session));
            },
            child: Text(AppLocalizations.of(context).actionStop.toUpperCase(),
                style: TransitTypography.bodySecondary(c.stateCancelled)),
          ),
        ],
      ),
    );
  }
}
