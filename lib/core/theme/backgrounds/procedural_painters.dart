import 'dart:math';

import 'package:flutter/material.dart';

class SoftGridPainter extends CustomPainter {
  SoftGridPainter({
    required this.lineColor,
    required this.bgColor,
    this.spacing = 32,
  });

  final Color lineColor;
  final Color bgColor;
  final double spacing;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(SoftGridPainter old) =>
      old.lineColor != lineColor ||
      old.bgColor != bgColor ||
      old.spacing != spacing;
}

class TopoLinesPainter extends CustomPainter {
  TopoLinesPainter({
    required this.lineColor,
    required this.bgColor,
    this.seed = 42,
  });

  final Color lineColor;
  final Color bgColor;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = bgColor);
    final rng = Random(seed);
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      final amplitude = 30.0 + rng.nextDouble() * 60;
      final frequency = 0.005 + rng.nextDouble() * 0.01;
      final phase = rng.nextDouble() * pi * 2;
      final yOffset = (size.height / 20) * i + rng.nextDouble() * 20;
      final path = Path()..moveTo(0, yOffset);
      for (double x = 0; x < size.width; x += 4) {
        path.lineTo(x, yOffset + sin(x * frequency + phase) * amplitude);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(TopoLinesPainter old) =>
      old.lineColor != lineColor ||
      old.bgColor != bgColor ||
      old.seed != seed;
}
