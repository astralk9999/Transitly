import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/app_logger.dart';

class FloatingLinesBackground extends StatefulWidget {
  const FloatingLinesBackground({
    super.key,
    this.color1 = const Color(0xFFE945F5),
    this.color2 = const Color(0xFF6F6F6F),
    this.color3 = const Color(0xFF6A6A6A),
    this.animationSpeed = 1.0,
    this.lineCount = 6,
    this.topLineDistance = 0.05,
    this.middleLineDistance = 0.05,
    this.bottomLineDistance = 0.05,
    this.topWavePosition = const Offset(10.0, 0.5),
    this.topWaveRotate = -0.4,
    this.middleWavePosition = const Offset(5.0, 0.0),
    this.middleWaveRotate = 0.2,
    this.bottomWavePosition = const Offset(2.0, -0.7),
    this.bottomWaveRotate = 0.4,
    this.enableTop = true,
    this.enableMiddle = true,
    this.enableBottom = true,
    this.opacity = 1.0,
    this.reduceMotion = false,
    this.child,
  });

  final Color color1;
  final Color color2;
  final Color color3;
  final double animationSpeed;
  final int lineCount;
  final double topLineDistance;
  final double middleLineDistance;
  final double bottomLineDistance;
  final Offset topWavePosition;
  final double topWaveRotate;
  final Offset middleWavePosition;
  final double middleWaveRotate;
  final Offset bottomWavePosition;
  final double bottomWaveRotate;
  final bool enableTop;
  final bool enableMiddle;
  final bool enableBottom;
  final double opacity;
  final bool reduceMotion;
  final Widget? child;

  @override
  State<FloatingLinesBackground> createState() =>
      _FloatingLinesBackgroundState();
}

class _FloatingLinesBackgroundState extends State<FloatingLinesBackground>
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
          await ui.FragmentProgram.fromAsset('shaders/floating_lines.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (e) {
      AppLogger.warn('FloatingLinesBackground', 'shader load failed', e);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(FloatingLinesBackground oldWidget) {
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
    final painter = _FloatingLinesPainter(
      shader: _shader!,
      time: _time,
      widget: widget,
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

class _FloatingLinesPainter extends CustomPainter {
  _FloatingLinesPainter({
    required this.shader,
    required this.time,
    required this.widget,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  final FloatingLinesBackground widget;

  @override
  void paint(Canvas canvas, Size size) {
    int idx = 0;
    // uTime
    shader.setFloat(idx++, time.value);
    // uResolution
    shader.setFloat(idx++, size.width);
    shader.setFloat(idx++, size.height);
    // uAnimationSpeed
    shader.setFloat(idx++, widget.animationSpeed);
    // uEnableTop/Middle/Bottom
    shader.setFloat(idx++, widget.enableTop ? 1.0 : 0.0);
    shader.setFloat(idx++, widget.enableMiddle ? 1.0 : 0.0);
    shader.setFloat(idx++, widget.enableBottom ? 1.0 : 0.0);
    // uTopLineCount/Middle/Bottom
    shader.setFloat(idx++, widget.lineCount.toDouble());
    shader.setFloat(idx++, widget.lineCount.toDouble());
    shader.setFloat(idx++, widget.lineCount.toDouble());
    // uTopLineDistance/Middle/Bottom
    shader.setFloat(idx++, widget.topLineDistance);
    shader.setFloat(idx++, widget.middleLineDistance);
    shader.setFloat(idx++, widget.bottomLineDistance);
    // uTopWavePos/Middle/Bottom (vec3 cada uno)
    shader.setFloat(idx++, widget.topWavePosition.dx);
    shader.setFloat(idx++, widget.topWavePosition.dy);
    shader.setFloat(idx++, widget.topWaveRotate);
    shader.setFloat(idx++, widget.middleWavePosition.dx);
    shader.setFloat(idx++, widget.middleWavePosition.dy);
    shader.setFloat(idx++, widget.middleWaveRotate);
    shader.setFloat(idx++, widget.bottomWavePosition.dx);
    shader.setFloat(idx++, widget.bottomWavePosition.dy);
    shader.setFloat(idx++, widget.bottomWaveRotate);
    // uColor1/2/3 (vec3 cada uno)
    shader.setFloat(idx++, widget.color1.r);
    shader.setFloat(idx++, widget.color1.g);
    shader.setFloat(idx++, widget.color1.b);
    shader.setFloat(idx++, widget.color2.r);
    shader.setFloat(idx++, widget.color2.g);
    shader.setFloat(idx++, widget.color2.b);
    shader.setFloat(idx++, widget.color3.r);
    shader.setFloat(idx++, widget.color3.g);
    shader.setFloat(idx++, widget.color3.b);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_FloatingLinesPainter old) =>
      old.widget != widget;
}
