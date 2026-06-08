import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/utils/app_logger.dart';

/// Smoke/fog animated background using a GLSL fragment shader (FBM noise).
///
/// In dark mode: purple smoke on near-black base.
/// In light mode: purple smoke on white base.
///
/// [opacity] controls overall visibility (0.0 = hidden, 1.0 = full).
/// [reduceMotion] pauses the animation ticker when true.
class SmokeBackground extends StatefulWidget {
  const SmokeBackground({
    super.key,
    this.color = const Color(0xFF977DDF),
    this.isDark = true,
    this.opacity = 1.0,
    this.reduceMotion = false,
    this.child,
  });

  final Color color;
  final bool isDark;
  final double opacity;
  final bool reduceMotion;
  final Widget? child;

  @override
  State<SmokeBackground> createState() => _SmokeBackgroundState();
}

class _SmokeBackgroundState extends State<SmokeBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _shaderFailed = false;
  double _lastUpdateTime = 0;

  static const _frameInterval = 0.05; // ~20fps

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    if (!widget.reduceMotion) _ticker.start();
    _loadShader();
  }

  @override
  void didUpdateWidget(SmokeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _ticker.stop();
      } else {
        _ticker.start();
      }
    }
  }

  void _onTick(Duration elapsed) {
    final t = elapsed.inMilliseconds / 1000.0;
    if (t - _lastUpdateTime >= _frameInterval) {
      _lastUpdateTime = t;
      _time.value = t;
    }
  }

  /// El shader GLSL puede quedar inutilizable (recurso GPU descartado por
  /// el sistema, pérdida de contexto al navegar entre pantallas pesadas,
  /// etc.). Si al pintar lanza, caemos al fallback animado por canvas — que
  /// nunca se rompe — para que el fondo NUNCA se quede congelado/roto.
  void _onShaderBroken() {
    if (_shaderFailed || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _shaderFailed = true);
        AppLogger.warn('SmokeBackground', 'shader broke → canvas fallback');
      }
    });
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/smoke.frag');
      if (mounted) {
        setState(() => _shader = program.fragmentShader());
      }
    } catch (e) {
      AppLogger.warn('SmokeBackground', 'shader load failed', e);
      if (mounted) setState(() => _shaderFailed = true);
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _shader?.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final painter = (!_shaderFailed && _shader != null)
        ? _SmokePainter(
            shader: _shader!,
            time: _time,
            color: widget.color,
            isDark: widget.isDark,
            onShaderError: _onShaderBroken,
          )
        : _SmokeGradientPainter(
            color: widget.color,
            time: _time,
            isDark: widget.isDark,
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: widget.opacity.clamp(0.0, 1.0),
          child: RepaintBoundary(
            child: SizedBox.expand(
              child: CustomPaint(painter: painter),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

// ── GLSL Shader painter ──

class _SmokePainter extends CustomPainter {
  _SmokePainter({
    required this.shader,
    required this.time,
    required this.color,
    required this.isDark,
    this.onShaderError,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  final Color color;
  final bool isDark;
  final VoidCallback? onShaderError;

  @override
  void paint(Canvas canvas, Size size) {
    try {
      shader.setFloat(0, time.value);
      shader.setFloat(1, size.width);
      shader.setFloat(2, size.height);
      shader.setFloat(3, color.r);
      shader.setFloat(4, color.g);
      shader.setFloat(5, color.b);
      shader.setFloat(6, isDark ? 1.0 : 0.0);

      canvas.drawRect(
        Offset.zero & size,
        Paint()..shader = shader,
      );
    } catch (_) {
      // Shader inutilizable → avisamos para caer al fallback animado.
      onShaderError?.call();
    }
  }

  @override
  bool shouldRepaint(_SmokePainter old) => old.isDark != isDark;
}

// ── Animated gradient fallback ──

class _SmokeGradientPainter extends CustomPainter {
  _SmokeGradientPainter({
    required this.color,
    required this.time,
    required this.isDark,
  }) : super(repaint: time);

  final Color color;
  final ValueNotifier<double> time;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final rect = Offset.zero & size;

    // Base color: dark → near-black, light → white
    final baseColor = isDark
        ? const Color(0xFF08081A)
        : const Color(0xFFF4F4FB);
    canvas.drawRect(rect, Paint()..color = baseColor);

    // 5 drifting smoke blobs
    _drawBlob(canvas, rect,
      math.sin(t * 0.07) * 0.35,
      math.cos(t * 0.05) * 0.3 - 0.35,
      1.8, 0.35 + math.sin(t * 0.12) * 0.08, 0);
    _drawBlob(canvas, rect,
      math.cos(t * 0.09) * 0.4 + 0.25,
      math.sin(t * 0.06) * 0.35 + 0.3,
      1.2, 0.28 + math.cos(t * 0.10 + 1.0) * 0.07, -20);
    _drawBlob(canvas, rect,
      math.sin(t * 0.04 + 2.0) * 0.5 - 0.3,
      math.cos(t * 0.08 + 1.5) * 0.4,
      1.0, 0.22 + math.sin(t * 0.14 + 0.5) * 0.06, 15);
    _drawBlob(canvas, rect,
      math.cos(t * 0.11 + 1.0) * 0.3,
      math.sin(t * 0.03 + 2.5) * 0.5 - 0.15,
      1.5, 0.18 + math.cos(t * 0.08 + 2.0) * 0.05, 30);
    _drawBlob(canvas, rect,
      math.sin(t * 0.06 + 3.0) * 0.2 + 0.4,
      math.cos(t * 0.07 + 0.3) * 0.25 - 0.5,
      0.9, 0.25 + math.sin(t * 0.16 + 1.5) * 0.06, -10);

    // Vignette matching the base
    final vignette = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: [
        Colors.transparent,
        baseColor.withValues(alpha: 0.6),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = vignette.createShader(rect));
  }

  void _drawBlob(Canvas canvas, Rect rect,
      double cx, double cy, double radius, double opacity, int hueShift) {
    final shifted = _shiftHue(color, hueShift);
    final gradient = RadialGradient(
      center: Alignment(cx, cy),
      radius: radius,
      colors: [
        shifted.withValues(alpha: opacity),
        shifted.withValues(alpha: opacity * 0.5),
        shifted.withValues(alpha: opacity * 0.15),
        Colors.transparent,
      ],
      stops: const [0.0, 0.25, 0.55, 1.0],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));
  }

  Color _shiftHue(Color base, int degrees) {
    final hsl = HSLColor.fromColor(base);
    return hsl.withHue((hsl.hue + degrees) % 360).toColor();
  }

  @override
  bool shouldRepaint(_SmokeGradientPainter old) => old.isDark != isDark;
}
