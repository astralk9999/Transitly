import 'dart:math';

import 'package:flutter/material.dart';

class Particle {
  final double x;
  final double y;
  final double radius;
  final double drift;
  final double phaseOffset;

  const Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.drift,
    required this.phaseOffset,
  });
}

List<Particle> generateParticles(int count, {int seed = 42}) {
  final rng = Random(seed);
  return List.generate(
      count,
      (_) => Particle(
            x: rng.nextDouble(),
            y: rng.nextDouble(),
            radius: 1.5 + rng.nextDouble() * 3.5,
            drift: 0.1 + rng.nextDouble() * 0.15,
            phaseOffset: rng.nextDouble(),
          ));
}

class ParticlesPainter extends CustomPainter {
  ParticlesPainter({
    required this.progress,
    required this.color,
    required this.particles,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final List<Particle> particles;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    final paint = Paint();
    for (final p in particles) {
      final phase = (t + p.phaseOffset) % 1.0;
      final dx = (p.x + sin(phase * pi * 2) * 0.02) * size.width;
      final dy = (p.y + (phase - 0.5) * p.drift) * size.height;
      final radius = p.radius * (0.6 + 0.4 * sin(phase * pi * 2));
      final alpha = (0.15 + 0.25 * sin(phase * pi * 2)).clamp(0.0, 1.0);
      paint.color = color.withValues(alpha: alpha);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlesPainter old) => false;
}
