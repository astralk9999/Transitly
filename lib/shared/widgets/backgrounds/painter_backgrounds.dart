import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Base abstracta para fondos animados con CustomPainter.
/// Maneja Ticker, throttling ~30fps y respeto de reduceMotion.
abstract class _AnimatedPainterBackground extends StatefulWidget {
  const _AnimatedPainterBackground({
    super.key,
    required this.colors,
    required this.opacity,
    required this.reduceMotion,
  });

  final List<Color> colors;
  final double opacity;
  final bool reduceMotion;
}

abstract class _AnimatedPainterState<T extends _AnimatedPainterBackground>
    extends State<T> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<double> time = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) {
      final t = (d.inMilliseconds / 1000.0) % 600.0;
      if ((t - time.value).abs() >= 0.033) time.value = t;
    });
    if (!widget.reduceMotion) _ticker.start();
  }

  @override
  void didUpdateWidget(T old) {
    super.didUpdateWidget(old);
    if (widget.reduceMotion != old.reduceMotion) {
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
    time.dispose();
    super.dispose();
  }

  CustomPainter buildPainter();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: widget.opacity.clamp(0.0, 1.0),
          child: RepaintBoundary(
            child: SizedBox.expand(
              child: CustomPaint(painter: buildPainter()),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────
// ColorBends — cintas curvas de degradado que fluyen
// ──────────────────────────────────────────────────────────────────────

class ColorBendsBackground extends _AnimatedPainterBackground {
  const ColorBendsBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<ColorBendsBackground> createState() => _ColorBendsState();
}

class _ColorBendsState
    extends _AnimatedPainterState<ColorBendsBackground> {
  @override
  CustomPainter buildPainter() =>
      _ColorBendsPainter(time: time, colors: widget.colors);
}

class _ColorBendsPainter extends CustomPainter {
  _ColorBendsPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    // 5 cintas que fluyen horizontalmente con desplazamiento de fase.
    for (int i = 0; i < 5; i++) {
      final phase = i * 0.85 + t * 0.4;
      final baseY = size.height * (0.15 + i * 0.18);
      final path = Path()..moveTo(0, baseY);
      const step = 8.0;
      for (double x = 0; x <= size.width; x += step) {
        final u = x / size.width;
        final dy = sin(u * pi * 2 + phase) * 36 +
            cos(u * pi * 4 + phase * 1.4) * 18 +
            sin(u * pi * 7 + phase * 0.7) * 9;
        path.lineTo(x, baseY + dy);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final base = colors[i % colors.length];
      final top = base.withValues(alpha: 0.22);
      final bottom = base.withValues(alpha: 0.0);
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [top, bottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, baseY - 60, size.width, 200));
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────
// DotField — grid de puntos parpadeando con fade radial desde el centro
// ──────────────────────────────────────────────────────────────────────

class DotFieldBackground extends _AnimatedPainterBackground {
  const DotFieldBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<DotFieldBackground> createState() => _DotFieldState();
}

class _DotFieldState extends _AnimatedPainterState<DotFieldBackground> {
  @override
  CustomPainter buildPainter() =>
      _DotFieldPainter(time: time, colors: widget.colors);
}

class _DotFieldPainter extends CustomPainter {
  _DotFieldPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    const spacing = 26.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = sqrt(cx * cx + cy * cy);
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        final fade = 1.0 - (dist / maxDist).clamp(0.0, 1.0);
        // Parpadeo independiente por punto.
        final twinkle = 0.5 + 0.5 * sin(t * 1.8 + (x + y) * 0.04);
        final r = (1.6 + twinkle * 1.4) * fade;
        if (r < 0.4) continue;
        final c = colors[((x ~/ spacing) + (y ~/ spacing)) % colors.length];
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = c.withValues(alpha: 0.55 * fade * twinkle),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────
// DotGrid — grid uniforme de puntos con onda que se propaga
// ──────────────────────────────────────────────────────────────────────

class DotGridBackground extends _AnimatedPainterBackground {
  const DotGridBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<DotGridBackground> createState() => _DotGridState();
}

class _DotGridState extends _AnimatedPainterState<DotGridBackground> {
  @override
  CustomPainter buildPainter() =>
      _DotGridPainter(time: time, colors: widget.colors);
}

class _DotGridPainter extends CustomPainter {
  _DotGridPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    const spacing = 22.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final accent = colors.first;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy);
        // Onda que viaja del centro hacia afuera.
        final wave = sin(dist * 0.05 - t * 2.5);
        final intensity = 0.4 + 0.6 * (wave * 0.5 + 0.5);
        final r = 1.4 + 1.2 * intensity;
        canvas.drawCircle(
          Offset(x, y),
          r,
          Paint()..color = accent.withValues(alpha: 0.35 * intensity),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────
// Dither — patrón Bayer 4x4 tintado con animación lenta de brillo
// ──────────────────────────────────────────────────────────────────────

class DitherBackground extends _AnimatedPainterBackground {
  const DitherBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<DitherBackground> createState() => _DitherState();
}

class _DitherState extends _AnimatedPainterState<DitherBackground> {
  @override
  CustomPainter buildPainter() =>
      _DitherPainter(time: time, colors: widget.colors);
}

class _DitherPainter extends CustomPainter {
  _DitherPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  // Matriz Bayer 4x4 normalizada.
  static const _bayer = <int>[
    0, 8, 2, 10,
    12, 4, 14, 6,
    3, 11, 1, 9,
    15, 7, 13, 5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    const cell = 4.0;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDist = sqrt(cx * cx + cy * cy);
    final accent = colors.first;
    final paint = Paint();
    // Onda que viaja en diagonal y modula la "luminosidad" base por celda.
    for (double y = 0; y < size.height; y += cell) {
      for (double x = 0; x < size.width; x += cell) {
        final dx = x - cx;
        final dy = y - cy;
        final dist = sqrt(dx * dx + dy * dy) / maxDist;
        final luminosity = 0.5 + 0.5 * sin(dist * 8 - t * 1.5);
        final bx = (x ~/ cell) % 4;
        final by = (y ~/ cell) % 4;
        final threshold = _bayer[by * 4 + bx] / 16.0;
        if (luminosity > threshold) {
          paint.color = accent.withValues(alpha: 0.25 * luminosity);
          canvas.drawRect(
            Rect.fromLTWH(x, y, cell - 0.5, cell - 0.5),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────
// FaultyTerminal — scanlines + ruido tipo CRT con glitches verticales
// ──────────────────────────────────────────────────────────────────────

class FaultyTerminalBackground extends _AnimatedPainterBackground {
  const FaultyTerminalBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<FaultyTerminalBackground> createState() => _FaultyTerminalState();
}

class _FaultyTerminalState
    extends _AnimatedPainterState<FaultyTerminalBackground> {
  @override
  CustomPainter buildPainter() =>
      _FaultyTerminalPainter(time: time, colors: widget.colors);
}

class _FaultyTerminalPainter extends CustomPainter {
  _FaultyTerminalPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final accent = colors.first;

    // Scanlines horizontales suaves.
    final scanPaint = Paint()..color = accent.withValues(alpha: 0.08);
    const lineGap = 3.0;
    for (double y = 0; y < size.height; y += lineGap) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 1.0),
        scanPaint,
      );
    }

    // Línea de barrido que recorre la pantalla.
    final sweepY = ((t * 60) % size.height);
    final sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          accent.withValues(alpha: 0.0),
          accent.withValues(alpha: 0.35),
          accent.withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, sweepY - 40, size.width, 80));
    canvas.drawRect(
      Rect.fromLTWH(0, sweepY - 40, size.width, 80),
      sweepPaint,
    );

    // Glitches verticales pseudo-random cada N frames.
    final rng = Random((t * 4).toInt());
    for (int i = 0; i < 4; i++) {
      if (rng.nextDouble() < 0.5) continue;
      final gx = rng.nextDouble() * size.width;
      final gw = 30.0 + rng.nextDouble() * 90;
      final gy = rng.nextDouble() * size.height;
      final gh = 2.0 + rng.nextDouble() * 4;
      canvas.drawRect(
        Rect.fromLTWH(gx, gy, gw, gh),
        Paint()..color = accent.withValues(alpha: 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ──────────────────────────────────────────────────────────────────────
// DarkVeil — gradiente radial animado con blobs orbitantes
// ──────────────────────────────────────────────────────────────────────

class DarkVeilBackground extends _AnimatedPainterBackground {
  const DarkVeilBackground({
    super.key,
    required super.colors,
    super.opacity = 1.0,
    super.reduceMotion = false,
  });

  @override
  State<DarkVeilBackground> createState() => _DarkVeilState();
}

class _DarkVeilState extends _AnimatedPainterState<DarkVeilBackground> {
  @override
  CustomPainter buildPainter() =>
      _DarkVeilPainter(time: time, colors: widget.colors);
}

class _DarkVeilPainter extends CustomPainter {
  _DarkVeilPainter({required this.time, required this.colors})
      : super(repaint: time);

  final ValueNotifier<double> time;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = time.value;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = sqrt(cx * cx + cy * cy);

    // 4 blobs que orbitan en elipses superpuestas.
    for (int i = 0; i < 4; i++) {
      final angle = t * (0.3 + i * 0.1) + i * (pi / 2);
      final orbX = (size.width * 0.30) * (1 + 0.4 * sin(i.toDouble()));
      final orbY = (size.height * 0.30) * (1 + 0.4 * cos(i.toDouble()));
      final bx = cx + cos(angle) * orbX;
      final by = cy + sin(angle * 1.3) * orbY;
      final c = colors[i % colors.length];
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            c.withValues(alpha: 0.42),
            c.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(bx, by), radius: radius * 0.5),
        );
      canvas.drawCircle(Offset(bx, by), radius * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
