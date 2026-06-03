import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/app_logger.dart';

/// Origen de los rayos en el espacio del lienzo.
enum LightRaysOrigin {
  topCenter,
  topLeft,
  topRight,
  left,
  right,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

class LightRaysBackground extends StatefulWidget {
  const LightRaysBackground({
    super.key,
    this.origin = LightRaysOrigin.topCenter,
    this.color = Colors.white,
    this.speed = 1.0,
    this.lightSpread = 0.5,
    this.rayLength = 3.0,
    this.pulsating = false,
    this.fadeDistance = 1.0,
    this.saturation = 1.0,
    this.noiseAmount = 0.0,
    this.distortion = 0.0,
    this.opacity = 1.0,
    this.reduceMotion = false,
    this.child,
  });

  final LightRaysOrigin origin;
  final Color color;
  final double speed;
  final double lightSpread;
  final double rayLength;
  final bool pulsating;
  final double fadeDistance;
  final double saturation;
  final double noiseAmount;
  final double distortion;
  final double opacity;
  final bool reduceMotion;
  final Widget? child;

  @override
  State<LightRaysBackground> createState() => _LightRaysBackgroundState();
}

class _LightRaysBackgroundState extends State<LightRaysBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      // Mod 600s: evita pérdida de precisión mediump en GLSL tras minutos.
      final t = (d.inMilliseconds / 1000.0) % 600.0;
      if ((t - _time.value).abs() >= 0.033) _time.value = t;
    });
    if (!widget.reduceMotion) _ticker.start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/light_rays.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (e) {
      AppLogger.warn('LightRaysBackground', 'shader load failed', e);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(LightRaysBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduceMotion != oldWidget.reduceMotion) {
      if (widget.reduceMotion) {
        _ticker.stop();
      } else {
        _ticker.start();
      }
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
    if (_failed || _shader == null) {
      return Container(color: Colors.black, child: widget.child);
    }
    final painter = _LightRaysPainter(
      shader: _shader!,
      time: _time,
      origin: widget.origin,
      color: widget.color,
      speed: widget.speed,
      lightSpread: widget.lightSpread,
      rayLength: widget.rayLength,
      pulsating: widget.pulsating,
      fadeDistance: widget.fadeDistance,
      saturation: widget.saturation,
      noiseAmount: widget.noiseAmount,
      distortion: widget.distortion,
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: widget.opacity.clamp(0.0, 1.0),
          child: RepaintBoundary(
            child: SizedBox.expand(child: CustomPaint(painter: painter)),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _LightRaysPainter extends CustomPainter {
  _LightRaysPainter({
    required this.shader,
    required this.time,
    required this.origin,
    required this.color,
    required this.speed,
    required this.lightSpread,
    required this.rayLength,
    required this.pulsating,
    required this.fadeDistance,
    required this.saturation,
    required this.noiseAmount,
    required this.distortion,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  final LightRaysOrigin origin;
  final Color color;
  final double speed;
  final double lightSpread;
  final double rayLength;
  final bool pulsating;
  final double fadeDistance;
  final double saturation;
  final double noiseAmount;
  final double distortion;

  ({Offset anchor, Offset dir}) _computeAnchorDir(double w, double h) {
    const outside = 0.2;
    switch (origin) {
      case LightRaysOrigin.topLeft:
        return (anchor: Offset(0, -outside * h), dir: const Offset(0, 1));
      case LightRaysOrigin.topRight:
        return (anchor: Offset(w, -outside * h), dir: const Offset(0, 1));
      case LightRaysOrigin.left:
        return (anchor: Offset(-outside * w, 0.5 * h), dir: const Offset(1, 0));
      case LightRaysOrigin.right:
        return (
          anchor: Offset((1 + outside) * w, 0.5 * h),
          dir: const Offset(-1, 0),
        );
      case LightRaysOrigin.bottomLeft:
        return (
          anchor: Offset(0, (1 + outside) * h),
          dir: const Offset(0, -1),
        );
      case LightRaysOrigin.bottomCenter:
        return (
          anchor: Offset(0.5 * w, (1 + outside) * h),
          dir: const Offset(0, -1),
        );
      case LightRaysOrigin.bottomRight:
        return (
          anchor: Offset(w, (1 + outside) * h),
          dir: const Offset(0, -1),
        );
      case LightRaysOrigin.topCenter:
        return (
          anchor: Offset(0.5 * w, -outside * h),
          dir: const Offset(0, 1),
        );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final anchorDir = _computeAnchorDir(size.width, size.height);

    // Orden uniforms en shaders/light_rays.frag:
    // 0: uTime
    // 1-2: uResolution
    // 3-4: uRayPos
    // 5-6: uRayDir
    // 7-9: uRaysColor
    // 10: uRaysSpeed
    // 11: uLightSpread
    // 12: uRayLength
    // 13: uPulsating
    // 14: uFadeDistance
    // 15: uSaturation
    // 16: uNoiseAmount
    // 17: uDistortion
    shader.setFloat(0, time.value);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    shader.setFloat(3, anchorDir.anchor.dx);
    shader.setFloat(4, anchorDir.anchor.dy);
    shader.setFloat(5, anchorDir.dir.dx);
    shader.setFloat(6, anchorDir.dir.dy);
    shader.setFloat(7, color.r);
    shader.setFloat(8, color.g);
    shader.setFloat(9, color.b);
    shader.setFloat(10, speed);
    shader.setFloat(11, lightSpread);
    shader.setFloat(12, rayLength);
    shader.setFloat(13, pulsating ? 1.0 : 0.0);
    shader.setFloat(14, fadeDistance);
    shader.setFloat(15, saturation);
    shader.setFloat(16, noiseAmount);
    shader.setFloat(17, distortion);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LightRaysPainter old) =>
      old.color != color ||
      old.speed != speed ||
      old.origin != origin ||
      old.lightSpread != lightSpread ||
      old.rayLength != rayLength;
}
