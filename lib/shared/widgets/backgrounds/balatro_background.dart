import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/utils/app_logger.dart';

class BalatroBackground extends StatefulWidget {
  const BalatroBackground({
    super.key,
    this.color1 = const Color(0xFFDE443B),
    this.color2 = const Color(0xFF006BB4),
    this.color3 = const Color(0xFF162325),
    this.spinRotation = -2.0,
    this.spinSpeed = 7.0,
    this.offset = const Offset(0, 0),
    this.contrast = 3.5,
    this.lighting = 0.4,
    this.spinAmount = 0.25,
    this.pixelFilter = 745.0,
    this.spinEase = 1.0,
    this.isRotate = false,
    this.opacity = 1.0,
    this.reduceMotion = false,
    this.child,
  });

  final Color color1;
  final Color color2;
  final Color color3;
  final double spinRotation;
  final double spinSpeed;
  final Offset offset;
  final double contrast;
  final double lighting;
  final double spinAmount;
  final double pixelFilter;
  final double spinEase;
  final bool isRotate;
  final double opacity;
  final bool reduceMotion;
  final Widget? child;

  @override
  State<BalatroBackground> createState() => _BalatroBackgroundState();
}

class _BalatroBackgroundState extends State<BalatroBackground>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  late final Ticker _ticker;
  final ValueNotifier<double> _time = ValueNotifier<double>(0);
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      // Mod 600s para evitar pérdida de precisión mediump float en GLSL.
      final t = (d.inMilliseconds / 1000.0) % 600.0;
      if ((t - _time.value).abs() >= 0.033) _time.value = t;
    });
    if (!widget.reduceMotion) _ticker.start();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      final program =
          await ui.FragmentProgram.fromAsset('shaders/balatro.frag');
      if (mounted) setState(() => _shader = program.fragmentShader());
    } catch (e) {
      AppLogger.warn('BalatroBackground', 'shader load failed', e);
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void didUpdateWidget(BalatroBackground oldWidget) {
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
      return Container(color: widget.color3, child: widget.child);
    }
    final painter = _BalatroPainter(
      shader: _shader!,
      time: _time,
      color1: widget.color1,
      color2: widget.color2,
      color3: widget.color3,
      spinRotation: widget.spinRotation,
      spinSpeed: widget.spinSpeed,
      offset: widget.offset,
      contrast: widget.contrast,
      lighting: widget.lighting,
      spinAmount: widget.spinAmount,
      pixelFilter: widget.pixelFilter,
      spinEase: widget.spinEase,
      isRotate: widget.isRotate,
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

class _BalatroPainter extends CustomPainter {
  _BalatroPainter({
    required this.shader,
    required this.time,
    required this.color1,
    required this.color2,
    required this.color3,
    required this.spinRotation,
    required this.spinSpeed,
    required this.offset,
    required this.contrast,
    required this.lighting,
    required this.spinAmount,
    required this.pixelFilter,
    required this.spinEase,
    required this.isRotate,
  }) : super(repaint: time);

  final ui.FragmentShader shader;
  final ValueNotifier<double> time;
  final Color color1;
  final Color color2;
  final Color color3;
  final double spinRotation;
  final double spinSpeed;
  final Offset offset;
  final double contrast;
  final double lighting;
  final double spinAmount;
  final double pixelFilter;
  final double spinEase;
  final bool isRotate;

  @override
  void paint(Canvas canvas, Size size) {
    // 0: uTime
    // 1-2: uResolution
    // 3: uSpinRotation
    // 4: uSpinSpeed
    // 5-6: uOffset
    // 7-10: uColor1 (vec4)
    // 11-14: uColor2
    // 15-18: uColor3
    // 19: uContrast
    // 20: uLighting
    // 21: uSpinAmount
    // 22: uPixelFilter
    // 23: uSpinEase
    // 24: uIsRotate
    shader.setFloat(0, time.value);
    shader.setFloat(1, size.width);
    shader.setFloat(2, size.height);
    shader.setFloat(3, spinRotation);
    shader.setFloat(4, spinSpeed);
    shader.setFloat(5, offset.dx);
    shader.setFloat(6, offset.dy);
    shader.setFloat(7, color1.r);
    shader.setFloat(8, color1.g);
    shader.setFloat(9, color1.b);
    shader.setFloat(10, color1.a);
    shader.setFloat(11, color2.r);
    shader.setFloat(12, color2.g);
    shader.setFloat(13, color2.b);
    shader.setFloat(14, color2.a);
    shader.setFloat(15, color3.r);
    shader.setFloat(16, color3.g);
    shader.setFloat(17, color3.b);
    shader.setFloat(18, color3.a);
    shader.setFloat(19, contrast);
    shader.setFloat(20, lighting);
    shader.setFloat(21, spinAmount);
    shader.setFloat(22, pixelFilter);
    shader.setFloat(23, spinEase);
    shader.setFloat(24, isRotate ? 1.0 : 0.0);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BalatroPainter old) =>
      old.color1 != color1 ||
      old.color2 != color2 ||
      old.color3 != color3 ||
      old.contrast != contrast ||
      old.lighting != lighting;
}
