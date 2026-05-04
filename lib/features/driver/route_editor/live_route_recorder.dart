import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/transit_colors.dart';
import '../../../core/theme/transit_typography.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/providers/user_provider.dart';
import 'live_recorder_controller.dart';
import 'recorded_session.dart';
import 'widgets/recorder_live_view.dart';
import 'widgets/recorder_pre_form.dart';

/// Prefijo de la clave que guarda el último borrador de grabación en
/// `shared_preferences`. Una entrada por usuario (o `guest` si no
/// hay sesión). En F3 esto migra a Hive con cifrado AES.
const String liveRecorderDraftKeyPrefix = 'live_recorder_draft';

class LiveRouteRecorder extends ConsumerStatefulWidget {
  const LiveRouteRecorder({super.key});

  @override
  ConsumerState<LiveRouteRecorder> createState() => _LiveRouteRecorderState();
}

class _LiveRouteRecorderState extends ConsumerState<LiveRouteRecorder> {
  final _controller = LiveRecorderController();
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _serviceType = 'urban';

  @override
  void initState() {
    super.initState();
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
            onStart: _controller.start,
          );
        }
        return RecorderLiveView(
          c: c,
          isDark: isDark,
          controller: _controller,
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
            child: Text('CONTINUAR',
                style: TransitTypography.bodySecondary(c.textMid)),
          ),
          TextButton(
            onPressed: () async {
              final session = _controller.getCurrentSession();
              _controller.stop();
              Navigator.of(ctx).pop();
              await _persistDraft(session);
              if (!mounted) return;
              unawaited(context.push('/driver/editor/post', extra: session));
            },
            child: Text('DETENER',
                style: TransitTypography.bodySecondary(c.stateCancelled)),
          ),
        ],
      ),
    );
  }

  Future<void> _persistDraft(RecordedSession session) async {
    try {
      final user = ref.read(currentUserProvider);
      final key = '$liveRecorderDraftKeyPrefix:${user.id}';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(session.toJson()));
      AppLogger.info('LiveRecorder',
          'draft saved (key=$key, ${session.stops.length} stops)');
    } catch (e, st) {
      AppLogger.error('LiveRecorder', 'failed to persist draft', e, st);
      // No relanzamos: el flujo de navegación al editor sigue
      // independientemente de si la persistencia tuvo éxito.
    }
  }
}
